## ADDED Requirements

### Requirement: Launch at Login Toggle

The system SHALL provide a toggle in General Settings that allows the user to enable or disable automatic launch of Alerto on login.

#### Scenario: User enables launch at login
- **WHEN** the user toggles "Launch at Login" to ON
- **THEN** the system SHALL call `SMAppService.mainApp.register()`
- **AND** the toggle SHALL reflect the resulting status

#### Scenario: User disables launch at login
- **WHEN** the user toggles "Launch at Login" to OFF
- **THEN** the system SHALL call `SMAppService.mainApp.unregister()`
- **AND** the toggle SHALL reflect the resulting status

#### Scenario: User enables launch at login and system requires approval
- **WHEN** the user toggles "Launch at Login" to ON
- **AND** `SMAppService.mainApp.status` becomes `.requiresApproval`
- **THEN** the system SHALL display a "Open System Settings" button
- **AND** the toggle SHALL remain in the ON state

#### Scenario: Status is not registered
- **WHEN** `SMAppService.mainApp.status` is `.notRegistered`
- **THEN** the toggle SHALL be in the OFF state

#### Scenario: Status is enabled
- **WHEN** `SMAppService.mainApp.status` is `.enabled`
- **THEN** the toggle SHALL be in the ON state

#### Scenario: Status is requires approval
- **WHEN** `SMAppService.mainApp.status` is `.requiresApproval`
- **THEN** the toggle SHALL be in the ON state
- **AND** a "Open System Settings" button SHALL be visible

#### Scenario: Open System Settings button is clicked
- **WHEN** the user clicks "Open System Settings"
- **THEN** the system SHALL open **System Settings → General → Login Items** via `URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension")`

#### Scenario: Toggle is clicked but register() throws
- **WHEN** the user toggles "Launch at Login" to ON
- **AND** `SMAppService.mainApp.register()` throws an error
- **THEN** the system SHALL revert the toggle to its previous state
- **AND** the system SHALL log the error

#### Scenario: Toggle is clicked but unregister() throws
- **WHEN** the user toggles "Launch at Login" to OFF
- **AND** `SMAppService.mainApp.unregister()` throws an error
- **THEN** the system SHALL revert the toggle to its previous state
- **AND** the system SHALL log the error

#### Scenario: Settings view appears
- **WHEN** `GeneralSettingsView` appears
- **THEN** the system SHALL read `SMAppService.mainApp.status`
- **AND** the toggle SHALL reflect the current status
