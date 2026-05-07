## Why

Alerto runs as a menu bar utility with no dock icon. Currently, users must manually launch the app after each login. This breaks the intended experience: users who want Claude Code notifications throughout their workday must remember to start Alerto every morning. Adding launch-at-login support closes this gap and makes the app feel like a persistent, reliable part of their workflow.

## What Changes

- **New "Launch at Login" toggle** in General Settings, alongside existing notification and sound options
- Toggle uses `SMAppService.mainApp` to register/unregister the current app as a login item
- Status-aware UI that reflects the actual system state (enabled, not registered, requires approval)
- "Open System Settings" helper button when macOS requires user approval
- Graceful handling of all `SMAppService.Status` states with appropriate UI feedback

## Capabilities

### New Capabilities

- `launch-at-login`: Toggle and status management for macOS login item registration using `SMAppService.mainApp`

## Impact

- **New UI**: Toggle added to `GeneralSettingsView` in `SettingsView.swift`
- **New service**: `LaunchAtLoginService` — thin wrapper around `SMAppService.mainApp` with status polling and error handling
- **Info.plist**: No changes required — `SMAppService` requires no additional entitlements for non-sandboxed apps; sandbox compatibility confirmed
- **No new dependencies**: Uses only Apple frameworks (`ServiceManagement`)
