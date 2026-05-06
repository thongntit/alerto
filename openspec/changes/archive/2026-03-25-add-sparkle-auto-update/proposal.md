## Why

Alerto has no automatic update mechanism — users must manually download new releases from GitHub. Adding Sparkle-based auto-update removes this friction, ensuring users always run the latest version without any manual intervention.

## What Changes

- Add Sparkle framework as a Swift Package Manager dependency
- Initialize `SPUStandardUpdaterController` in `AppDelegate` for lifecycle-managed update checking
- Update `AboutView` to display dynamic version info, an auto-check toggle, and a manual "Check for Updates" button
- Add `SUFeedURL` and `SUPublicEDKey` to `Info.plist`
- Update GitHub Actions release workflow to sign the DMG with EdDSA and generate + upload `appcast.xml` as a release asset
- Document one-time key generation setup for maintainers

## Capabilities

### New Capabilities
- `auto-update`: Sparkle-powered update checking and installation — both automatic (on launch + periodic) and manual trigger from the About tab in Settings. Appcast is hosted as a GitHub release asset using the `/releases/latest/download/appcast.xml` stable URL pattern.

### Modified Capabilities
- `about-view`: The About tab gains live version display (from bundle), an auto-update toggle, and a "Check for Updates" button.

## Impact

- **Dependencies**: Adds `Sparkle` (~4MB) via Swift Package Manager
- **Info.plist**: New keys `SUFeedURL`, `SUPublicEDKey`
- **CI**: `release.yml` gains steps to install Sparkle tools, sign the DMG, and generate `appcast.xml`
- **One-time setup**: Maintainer must run `generate_keys`, store private key in GitHub secret `SPARKLE_PRIVATE_KEY`, and add public key to `Info.plist`
- **No breaking changes** — Sparkle update UI is purely additive; existing functionality is unchanged
