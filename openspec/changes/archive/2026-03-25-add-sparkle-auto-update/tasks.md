## 1. One-Time Key Setup (Manual)

- [x] 1.1 Download Sparkle release and extract `generate_keys` tool, run it to produce EdDSA key pair
- [x] 1.2 Save private key securely (password manager) then add it as GitHub Actions secret `SPARKLE_PRIVATE_KEY`
- [x] 1.3 Note the public key — it will be added to `Info.plist` in task 2.3

## 2. Add Sparkle Dependency

- [x] 2.1 Add Sparkle Swift Package to `alerto.xcodeproj` via Xcode (Package URL: `https://github.com/sparkle-project/Sparkle`, version `2.x`)
- [x] 2.2 Link `Sparkle` framework to the `Alerto` target
- [x] 2.3 Add `SUFeedURL` (`https://github.com/{owner}/{repo}/releases/latest/download/appcast.xml`) and `SUPublicEDKey` (from step 1.3) to `Info.plist`

## 3. App Code — AppDelegate

- [x] 3.1 Import `Sparkle` in `AlertoApp.swift`
- [x] 3.2 Add `SPUStandardUpdaterController` as a stored property on `AppDelegate`, initialized with `startingUpdater: true`

## 4. App Code — AboutView

- [x] 4.1 Replace hardcoded `"Version 1.0"` with dynamic version from `Bundle.main.infoDictionary["CFBundleShortVersionString"]`
- [x] 4.2 Add `@ObservedObject` or `@StateObject` binding to the updater controller so the view can call `checkForUpdates`
- [x] 4.3 Add auto-check toggle bound to `updaterController.updater.automaticallyChecksForUpdates`
- [x] 4.4 Add "Check for Updates" button that calls `updaterController.checkForUpdates(nil)`

## 5. CI — Release Workflow

- [x] 5.1 Add step to download and extract Sparkle release (to get `sign_update` binary) in `release.yml`
- [x] 5.2 After DMG is built, add step to sign it: `./sign_update Alerto.dmg -s "$SPARKLE_PRIVATE_KEY"` and capture signature + file size
- [x] 5.3 Add step to generate `appcast.xml` with correct version, DMG URL, EdDSA signature, length, and `minimumSystemVersion`
- [x] 5.4 Upload `appcast.xml` as a release asset alongside `Alerto.dmg`

## 6. Verification

- [ ] 6.1 Build and run locally — confirm "Check for Updates" button appears in About tab
- [ ] 6.2 Publish a test release and verify `appcast.xml` is uploaded and accessible at `/releases/latest/download/appcast.xml`
- [ ] 6.3 Install older build, trigger update check, confirm Sparkle detects new version and installs successfully
