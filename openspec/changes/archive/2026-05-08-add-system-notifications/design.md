## Context

Alerto is a macOS menu bar app (`LSUIElement = true`) that today renders every alert through a custom `NotificationOverlayView`/`NotificationOverlayManager`. The overlay path is the only delivery surface, controlled by a single `@AppStorage("showOverlay")` boolean and an `overlayDuration` slider in `SettingsView`. Sound is played manually via `NSSound` from `NotificationManager.showNotification`. The app is signed (Sparkle EdDSA) and not sandboxed (no `.entitlements` file).

Constraint: a menu bar app receives alerts from background HTTP hooks at any time, including while the user is in another full-screen app or has macOS Focus modes enabled. The overlay ignores Focus and steals attention. We need an OS-native delivery path that respects user system policy, while keeping the existing overlay mode for users who prefer it.

## Goals / Non-Goals

**Goals:**
- Add a `UNUserNotificationCenter`-based delivery mode selectable from Settings.
- Preserve existing default behavior for current users (overlay remains the default and migrates cleanly from the old boolean).
- Reuse existing notification content (title/body derived from `AgenticNotification`, source, hook type) and existing sound preference.
- Handle authorization gracefully: lazy request, clear in-app feedback when denied.
- Keep notification history in-app regardless of presentation mode.

**Non-Goals:**
- Custom notification actions / reply buttons (future work).
- Cross-device push relay (separate proposal).
- Per-project routing rules (separate proposal).
- Replacing or removing the overlay implementation.
- Sandbox migration.

## Decisions

### 1. Three-mode selector instead of a per-mode toggle pair
A single enum-backed `notificationStyle` setting with values `overlay | system | off` keeps the modes mutually exclusive and avoids the "both on" ambiguity (double notifications, double sound). The current `showOverlay: Bool` is migrated on first launch: `true → overlay`, `false → off`. New users default to `overlay` to preserve install-day parity.

Alternative considered: two booleans (`showOverlay`, `useSystemNotifications`). Rejected — invites contradictory states and complicates the sound-suppression rule below.

### 2. Sound ownership moves with the mode
- `overlay` and `off`: keep current `NSSound(named:).play()` in `NotificationManager`.
- `system`: pass `UNNotificationSound(named: NSSound.Name(selectedSound))` on the `UNMutableNotificationContent`. The manual `NSSound` call is **suppressed** in this branch.

Rationale: the OS plays a notification sound when banners deliver, and Focus/DND silence it correctly. Playing `NSSound` ourselves on top would double-play and bypass DND.

### 3. New `SystemNotificationService` singleton in `alerto/Services/`
Wraps `UNUserNotificationCenter.current()`. Responsibilities:
- Lazy `requestAuthorization(options: [.alert, .sound])` on first `post(...)` call; cache last-known status in a `@Published var authorizationStatus: UNAuthorizationStatus`.
- Build `UNMutableNotificationContent` from an `AgenticNotification` using the same title/body rules as the overlay (reuse a small helper extracted from existing display logic so the two paths can't drift).
- Schedule with a nil trigger (deliver immediately).
- Conform to `UNUserNotificationCenterDelegate`:
  - `willPresent` → return `[.banner, .sound]` so notifications still appear when the menu bar window is open.
  - `didReceive` (tap) → reopen Settings or focus menu bar (use existing `SettingsWindowManager` for now; tap-to-focus a specific notification is out of scope).

Alternative considered: keep this inline in `NotificationManager`. Rejected — `NotificationManager` already mixes state, sound, overlay, and history; adding UNC delegate duties makes it harder to test and reason about.

### 4. Branch in `NotificationManager.showNotification` on style
```
switch notificationStyle {
case .overlay:        currentNotification = ...; play NSSound; show overlay
case .system:         SystemNotificationService.shared.post(notification); append to history directly (no currentNotification gating)
case .off:            append to history only
}
```
History append for `.system` happens immediately because there is no in-app dismiss event to drive the existing `dismissOverlay()` flow. The menu bar unread badge logic (`menubarIcon`) continues to work via the `notifications` array.

### 5. Authorization UX
- First time the user picks `system` mode, requesting authorization will trigger the macOS prompt. We don't pre-request on launch — keeps cold-start clean for users who never opt in.
- If `authorizationStatus == .denied`, the Settings General → Notifications section shows an inline warning row with a "Open Notification Settings" button that opens `x-apple.systempreferences:com.apple.Notifications-Settings.extension?Alerto`. The `system` mode remains selectable; we don't silently fall back, so the user understands why they're not seeing banners.
- Status is refreshed when the Settings window appears (`getNotificationSettings`).

### 6. No new entitlements / Info.plist changes
`UNUserNotificationCenter` for **local** notifications on macOS does not require sandbox entitlements or aps-environment configuration; the existing signed bundle is sufficient. We are not using remote (push) notifications.

## Risks / Trade-offs

- **Authorization denied without remediation** → Mitigation: explicit inline warning in Settings + deep link to System Settings; never silently swallow the denial.
- **Behavior surprise: alerts swallowed by Focus/DND** → Mitigation: brief help text under the style picker explaining "System notifications respect Focus and Do Not Disturb." Users who want guaranteed visibility keep the overlay mode.
- **Title/body divergence between overlay and system paths** → Mitigation: extract a single `displayContent(for: AgenticNotification) -> (title, body, subtitle?)` helper used by both paths.
- **Double sound during transitions / race conditions** → Mitigation: sound branching is centralized in `NotificationManager.showNotification`, gated by the mode enum, with no other call site invoking `NSSound`.
- **Notification Center backlog** when user is away → Acceptable: this is exactly the behavior users opting into system mode want. We do not throttle or coalesce in this change.
- **Migration regressions for users with `showOverlay = false`** → They were getting silent history-only behavior; mapping to `off` preserves that. We log the migration once for diagnostics.

## Migration Plan

1. On first launch after upgrade, `NotificationManager` (or a small `SettingsMigration` helper called from `AppDelegate.applicationDidFinishLaunching`) checks for the absence of `notificationStyle` in `UserDefaults` and the presence of `showOverlay`:
   - `showOverlay == true` (or unset) → write `notificationStyle = "overlay"`.
   - `showOverlay == false` → write `notificationStyle = "off"`.
   - Keep the old `showOverlay` key in place for one release (do not delete) so a downgrade still works.
2. No data migration is needed for notification history.
3. Rollback: revert the binary; the old `showOverlay` key is still present and honored by the prior version.

## Open Questions

- Should tapping a system notification open Settings, focus the menu bar popover, or do nothing? Initial decision: open the menu bar popover if reachable, fall back to no-op. Revisit after user feedback.
- Should we expose `interruptionLevel` (active/timeSensitive) as a power-user setting? Out of scope for this change; default is `.active`.
