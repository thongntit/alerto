## ADDED Requirements

### Requirement: Notification style selector
The system SHALL provide a user-facing setting that selects exactly one notification presentation style from `overlay`, `system`, or `off`.

#### Scenario: Overlay mode selected
- **WHEN** the user selects "Overlay" in Settings → General → Notifications
- **THEN** incoming notifications are displayed using the in-app overlay window and no system notification is posted

#### Scenario: System mode selected
- **WHEN** the user selects "System notification" in Settings → General → Notifications
- **THEN** incoming notifications are delivered via `UNUserNotificationCenter` and no overlay window is shown

#### Scenario: Off mode selected
- **WHEN** the user selects "Off" in Settings → General → Notifications
- **THEN** no overlay is shown and no system notification is posted, but the notification is still appended to in-app history

#### Scenario: Default for new installs
- **WHEN** the app is launched for the first time with no prior `notificationStyle` setting and no prior `showOverlay` setting
- **THEN** the style defaults to `overlay`

### Requirement: Migrate legacy showOverlay setting
The system SHALL migrate the previous `showOverlay` boolean preference to the new `notificationStyle` setting on first launch after upgrade.

#### Scenario: Legacy enabled
- **WHEN** the app launches and `notificationStyle` is unset and `showOverlay` is `true`
- **THEN** `notificationStyle` is set to `overlay`

#### Scenario: Legacy disabled
- **WHEN** the app launches and `notificationStyle` is unset and `showOverlay` is `false`
- **THEN** `notificationStyle` is set to `off`

### Requirement: Deliver via UNUserNotificationCenter
The system SHALL deliver notifications through `UNUserNotificationCenter` when style is `system`, including when the menu bar window is open.

#### Scenario: Banner appears while app is foregrounded
- **WHEN** style is `system` and a notification is received while the user has the menu bar popover open
- **THEN** the notification still appears as a banner (presentation options include `.banner` and `.sound`)

#### Scenario: Notification persists in Notification Center
- **WHEN** style is `system` and a notification is delivered
- **THEN** the notification is retrievable from macOS Notification Center until the user dismisses it

### Requirement: Lazy authorization request
The system SHALL request notification authorization only when first needed, not at app launch.

#### Scenario: First post in system mode triggers prompt
- **WHEN** style is `system`, authorization status is `notDetermined`, and a notification needs to be delivered
- **THEN** the system requests authorization with `.alert` and `.sound` options before posting

#### Scenario: No prompt while in overlay or off mode
- **WHEN** the user remains in `overlay` or `off` mode for the entire session
- **THEN** the system does not request notification authorization

### Requirement: Surface denied authorization
The system SHALL inform the user when notification authorization is denied while `system` mode is selected.

#### Scenario: Inline warning shown in Settings
- **WHEN** style is `system` and authorization status is `denied`
- **THEN** Settings → General → Notifications displays an inline warning with a button to open System Settings → Notifications

#### Scenario: Mode remains selectable
- **WHEN** authorization is denied
- **THEN** the system does not silently change the user's selected style; the selection remains `system`

### Requirement: Sound delegation by mode
The system SHALL play notification sound through exactly one mechanism per mode to avoid double-play.

#### Scenario: Overlay mode plays in-app sound
- **WHEN** style is `overlay` and `playSound` is enabled
- **THEN** `NSSound(named: selectedSound)` is played by the app

#### Scenario: System mode delegates to UNNotificationSound
- **WHEN** style is `system` and `playSound` is enabled
- **THEN** the posted `UNMutableNotificationContent` carries `UNNotificationSound(named: selectedSound)` and the app does not call `NSSound.play`

#### Scenario: Sound disabled
- **WHEN** `playSound` is disabled
- **THEN** no sound is played in any mode and `UNNotificationContent.sound` is `nil` in `system` mode

### Requirement: History parity across modes
The system SHALL append every received notification to in-app history regardless of the selected style.

#### Scenario: System mode adds to history
- **WHEN** style is `system` and a notification is delivered
- **THEN** the notification appears in the menu bar history list with the same metadata as overlay-mode entries

#### Scenario: Off mode adds to history
- **WHEN** style is `off` and a notification is received
- **THEN** the notification still appears in the menu bar history list

### Requirement: Tapping a system notification activates the app
The system SHALL bring Alerto's interface to the foreground when the user taps a delivered system notification.

#### Scenario: Tap activates menu bar
- **WHEN** the user taps a delivered system notification
- **THEN** the app activates and the menu bar popover is shown if available

### Requirement: Hide overlay duration when not in overlay mode
The system SHALL hide or disable the overlay-duration control when the selected style is not `overlay`.

#### Scenario: Slider hidden in system mode
- **WHEN** the selected style is `system` or `off`
- **THEN** the "Overlay duration" slider is not shown in Settings
