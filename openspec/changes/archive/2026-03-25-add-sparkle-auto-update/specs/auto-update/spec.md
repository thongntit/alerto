## ADDED Requirements

### Requirement: Automatic update check on launch
The app SHALL check for available updates automatically when it launches, using Sparkle's `SPUStandardUpdaterController` with `automaticallyChecksForUpdates` enabled.

#### Scenario: Update available on launch
- **WHEN** the app launches and a newer version is available in the appcast
- **THEN** Sparkle SHALL present its standard update available sheet to the user

#### Scenario: No update available on launch
- **WHEN** the app launches and no newer version is available
- **THEN** no UI is shown and the app starts normally

### Requirement: Periodic background update check
The app SHALL periodically check for updates in the background while running, using Sparkle's default check interval.

#### Scenario: Update found during background check
- **WHEN** a background check detects a newer version
- **THEN** Sparkle SHALL notify the user via its standard update sheet

### Requirement: EdDSA-signed update packages
Every DMG release asset SHALL be signed with an EdDSA private key. The corresponding public key SHALL be embedded in `Info.plist` as `SUPublicEDKey`. Sparkle SHALL reject any update whose signature does not verify against the public key.

#### Scenario: Valid signature
- **WHEN** Sparkle downloads an update and verifies the EdDSA signature
- **THEN** the update proceeds to installation

#### Scenario: Invalid or missing signature
- **WHEN** Sparkle downloads an update with an invalid or missing signature
- **THEN** Sparkle SHALL abort the update and display an error

### Requirement: Appcast served from GitHub release assets
The app SHALL fetch the appcast from `https://github.com/{owner}/{repo}/releases/latest/download/appcast.xml`, configured as `SUFeedURL` in `Info.plist`. Each GitHub release SHALL include an `appcast.xml` asset listing that release's DMG.

#### Scenario: Appcast fetch succeeds
- **WHEN** Sparkle fetches the appcast URL
- **THEN** it SHALL receive a valid RSS/appcast XML describing the latest release

#### Scenario: Appcast fetch fails (no network)
- **WHEN** the device has no network access
- **THEN** Sparkle SHALL silently fail the check without showing an error to the user (for automatic checks)
