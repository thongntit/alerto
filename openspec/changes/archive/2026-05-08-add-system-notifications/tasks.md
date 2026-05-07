## 1. Settings model & migration

- [x] 1.1 Define `NotificationStyle` enum (`overlay`, `system`, `off`) with a `rawValue: String` representation suitable for `@AppStorage`
- [x] 1.2 Add `@AppStorage("notificationStyle")` reads in `NotificationManager` and `SettingsView` (default `overlay`)
- [x] 1.3 Implement one-time migration from `@AppStorage("showOverlay")` → `notificationStyle` in `AppDelegate.applicationDidFinishLaunching` (true → overlay, false → off, missing → overlay)
- [x] 1.4 Log the migration outcome once via `AppLogger`

## 2. SystemNotificationService

- [x] 2.1 Create `alerto/Services/SystemNotificationService.swift` as a `@MainActor` singleton wrapping `UNUserNotificationCenter.current()`
- [x] 2.2 Add `@Published var authorizationStatus: UNAuthorizationStatus` and a `refreshAuthorizationStatus()` method using `getNotificationSettings`
- [x] 2.3 Implement `requestAuthorizationIfNeeded()` that calls `requestAuthorization(options: [.alert, .sound])` only when status is `.notDetermined`
- [x] 2.4 Implement `post(_ notification: AgenticNotification, playSound: Bool, soundName: String)` that builds `UNMutableNotificationContent` (title/subtitle/body via shared content helper) and submits a `UNNotificationRequest` with nil trigger
- [x] 2.5 Conform to `UNUserNotificationCenterDelegate` and register on app launch:
  - `willPresent` → completion handler returns `[.banner, .sound]`
  - `didReceive` → activate the app (menu bar popover focus is a follow-up; tapping currently activates Alerto via `NSApp.activate`)
- [x] 2.6 Register the delegate from `AppDelegate.applicationDidFinishLaunching`

## 3. Shared content helper

- [x] 3.1 Extract a `displayContent(for: AgenticNotification) -> (title: String, subtitle: String?, body: String)` helper used by both overlay and system-notification paths so titles/bodies cannot drift
- [x] 3.2 Update `NotificationOverlayView` / `NotificationOverlayManager` to consume the shared helper (no behavior change in overlay mode)

## 4. NotificationManager branching

- [x] 4.1 Replace the `if showOverlaySetting` block in `NotificationManager.showNotification` with a `switch` on `NotificationStyle`
- [x] 4.2 In `.overlay` branch: keep current behavior (NSSound + overlay + history-on-dismiss)
- [x] 4.3 In `.system` branch: call `SystemNotificationService.shared.post(...)`, suppress `NSSound` playback, and append the notification to `notifications` history immediately
- [x] 4.4 In `.off` branch: append to history only; no sound, no overlay
- [x] 4.5 Verify `menubarIcon`/unread badge still updates correctly across all three modes

## 5. Settings UI

- [x] 5.1 Replace the "Show overlay notification" `Toggle` in `GeneralSettingsView` with a `Picker` bound to `notificationStyle` (segmented or menu) labeled "Notification style"
- [x] 5.2 Show the "Overlay duration" slider only when `notificationStyle == .overlay`
- [x] 5.3 Add help text under the picker noting that "System notifications respect Focus and Do Not Disturb"
- [x] 5.4 Subscribe to `SystemNotificationService.shared.authorizationStatus`; when style is `.system` and status is `.denied`, show an inline warning row with an "Open Notification Settings" button that opens `x-apple.systempreferences:com.apple.Notifications-Settings.extension?Alerto`
- [x] 5.5 Refresh authorization status on Settings window appear

## 6. Manual verification

- [x] 6.1 Fresh install: verify default style is `overlay` and `curl /notify` shows the overlay
- [x] 6.2 Upgrade with prior `showOverlay = true`: verify migration to `overlay` and unchanged behavior
- [x] 6.3 Upgrade with prior `showOverlay = false`: verify migration to `off` and history-only behavior
- [x] 6.4 Switch to `system` for the first time: verify macOS authorization prompt appears, then a `curl /notify` produces a banner
- [x] 6.5 Deny authorization in System Settings → verify inline warning appears in Settings and selection remains `system`
- [x] 6.6 With `system` selected and `playSound` enabled, confirm only one sound plays (no double-play)
- [x] 6.7 With `system` selected, enable a Focus mode → verify banner is suppressed by macOS and the entry still appears in app history
- [x] 6.8 Tap a delivered system notification → verify Alerto activates
