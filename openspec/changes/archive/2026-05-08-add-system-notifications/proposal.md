## Why

The current overlay-only presentation interrupts the user's screen, ignores macOS Focus / Do Not Disturb, and disappears after a fixed timeout with no way to recover the alert from Notification Center. Users who want quieter, OS-native delivery (and history that survives in Notification Center) have no option today.

## What Changes

- Add a new presentation mode that delivers alerts through `UNUserNotificationCenter` so they appear as native macOS banners/alerts and stack in Notification Center.
- Replace the boolean "Show overlay notification" toggle in Settings with a three-way notification style: **Overlay**, **System notification**, **Off**. Existing users keep "Overlay" behavior (migrated from the prior `showOverlay` bool).
- When System notification is selected, sound playback is delegated to `UNNotificationSound` using the existing selected sound; the in-app `NSSound` fallback is suppressed in that mode to prevent double-play.
- Request notification authorization lazily on first use, and surface an inline warning + deep link to System Settings → Notifications if authorization is denied.
- Hide the overlay-duration slider when style ≠ Overlay.
- Notifications continue to be appended to in-app history regardless of style (parity with current "Off" path).

## Capabilities

### New Capabilities
- `system-notification-display`: Deliver Alerto notifications via macOS `UNUserNotificationCenter`, including authorization handling, content mapping, sound, and tap behavior.

### Modified Capabilities
- `notification-content-display`: Notification presentation is no longer overlay-only; the existing content rules (title/body/subtitle, hook-type context, message truncation) MUST apply to the new system-notification path as well, and the user-visible setting is now a style selector rather than a single toggle.

## Impact

- **Code**: `alerto/Managers/NotificationManager.swift` (branch on style), new `alerto/Services/SystemNotificationService.swift`, `alerto/Views/SettingsView.swift` (style picker + permission UX), one-time migration of `@AppStorage("showOverlay")` → `@AppStorage("notificationStyle")`.
- **Frameworks**: Adds `UserNotifications` framework usage. No new third-party dependencies.
- **Entitlements / Info.plist**: No sandbox entitlements required (app is not sandboxed). `UNUserNotificationCenter` works for the existing signed bundle; no Info.plist keys are required for local user notifications on macOS.
- **User-visible behavior**: Authorization prompt appears the first time a user switches to System notification mode. Users on macOS Focus/DND will stop seeing alerts in that mode — by design.
- **Backward compatibility**: Default mode remains overlay; users who previously had `showOverlay = false` are migrated to the new "Off" mode.
