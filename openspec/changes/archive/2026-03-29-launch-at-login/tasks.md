## 1. Create LaunchAtLoginService

- [x] 1.1 Create `Services/LaunchAtLoginService.swift` with `@MainActor` singleton class
- [x] 1.2 Add `@Published private(set) var status: SMAppService.Status` property
- [x] 1.3 Implement `register()` method that calls `SMAppService.mainApp.register()` and updates status
- [x] 1.4 Implement `unregister()` method that calls `SMAppService.mainApp.unregister()` and updates status
- [x] 1.5 Add error handling in both methods with `print` logging
- [x] 1.6 Add `refreshStatus()` method to poll current `SMAppService.mainApp.status`

## 2. Add UI to GeneralSettingsView

- [x] 2.1 Import `ServiceManagement` in `SettingsView.swift`
- [x] 2.2 Add `@StateObject private var launchAtLoginService = LaunchAtLoginService.shared` to `GeneralSettingsView`
- [x] 2.3 Add "Launch at Login" `Toggle` in the Notifications section of `GeneralSettingsView`
- [x] 2.4 Bind toggle to `launchAtLoginService.status` using computed isEnabled getter
- [x] 2.5 Call `launchAtLoginService.refreshStatus()` in `onAppear` of `GeneralSettingsView`
- [x] 2.6 Add "Open System Settings" `Button` that is visible when status is `.requiresApproval`
- [x] 2.7 Implement `openLoginItemsSettings()` method that opens `x-apple.systempreferences:com.apple.LoginItems-Settings.extension`
- [x] 2.8 Wrap register/unregister calls in `Task { }` blocks to avoid blocking the main thread

## 3. Verify and Test

- [x] 3.1 Build the project to confirm no compilation errors
- [ ] 3.2 Open the app and verify the toggle appears in General Settings
- [ ] 3.3 Enable the toggle and confirm `SMAppService` registration succeeds (or approval prompt appears)
- [ ] 3.4 Disable the toggle and confirm `SMAppService` unregistration succeeds
- [ ] 3.5 Verify the toggle state persists correctly across Settings view navigation
- [x] 3.6 Confirm no new warnings from Xcode Analyzer
