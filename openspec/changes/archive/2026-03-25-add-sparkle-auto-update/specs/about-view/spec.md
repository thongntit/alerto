## ADDED Requirements

### Requirement: Dynamic version display
The About tab SHALL display the app version read from the main bundle (`CFBundleShortVersionString`) rather than a hardcoded string.

#### Scenario: Version displayed
- **WHEN** the user opens Settings and navigates to the About tab
- **THEN** the current app version SHALL be shown (e.g., "Version 1.2.0")

### Requirement: Auto-check for updates toggle
The About tab SHALL include a toggle that controls `SPUUpdater.automaticallyChecksForUpdates`. The toggle state SHALL persist across app restarts (managed by Sparkle).

#### Scenario: Toggle on
- **WHEN** the user enables the auto-check toggle
- **THEN** Sparkle SHALL check for updates on next launch and periodically thereafter

#### Scenario: Toggle off
- **WHEN** the user disables the auto-check toggle
- **THEN** Sparkle SHALL not perform any automatic update checks

### Requirement: Manual "Check for Updates" button
The About tab SHALL include a "Check for Updates" button that triggers an immediate update check via `SPUStandardUpdaterController.checkForUpdates(_:)`.

#### Scenario: Update available
- **WHEN** the user clicks "Check for Updates" and a newer version exists
- **THEN** Sparkle SHALL present its standard update sheet

#### Scenario: Already up to date
- **WHEN** the user clicks "Check for Updates" and no newer version exists
- **THEN** Sparkle SHALL show its "You're up to date" alert
