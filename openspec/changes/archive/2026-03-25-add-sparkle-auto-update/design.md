## Context

Alerto is an unsigned macOS menu bar app distributed as a DMG via GitHub releases. There is no current update mechanism. Users must manually download new releases. The app uses Swift Package Manager for dependencies (Hummingbird, ServiceLifecycle). Releases are built via GitHub Actions and published as GitHub release assets.

Sparkle is the de facto standard for auto-update in non-App-Store macOS apps. Sparkle 2.x supports SPM, requires EdDSA signatures on update packages (separate from Apple code signing), and handles all update UI natively.

## Goals / Non-Goals

**Goals:**
- Automatic update checks on launch and periodically in background
- Manual "Check for Updates" trigger from About tab
- Secure update delivery via EdDSA-signed DMG
- Minimal CI complexity — appcast generated and uploaded per release
- Stable appcast URL using GitHub's `/releases/latest/download/` redirect

**Non-Goals:**
- Apple Developer ID code signing (out of scope, user handles Gatekeeper manually)
- Delta/binary diff updates
- Staged rollouts or multiple release channels
- Downgrade / rollback support

## Decisions

### 1. Sparkle via Swift Package Manager
Use SPM to add `https://github.com/sparkle-project/Sparkle` (2.x). Consistent with how existing dependencies (Hummingbird) are managed. No need for a separate Xcode framework embedding step.

### 2. Appcast URL pattern: `/releases/latest/download/appcast.xml`
Each GitHub release uploads its own `appcast.xml` as a release asset. The `SUFeedURL` points to `https://github.com/{owner}/{repo}/releases/latest/download/appcast.xml` — GitHub redirects this to the latest release's asset automatically.

**Alternative considered**: Repo-hosted appcast (committed to `main` on each release). Rejected because it requires an extra git commit step in CI and complicates the release workflow. For this app's simple use case, per-release appcast is sufficient.

### 3. SPUStandardUpdaterController initialized in AppDelegate
`SPUStandardUpdaterController` is instantiated as a stored property on `AppDelegate`. This ties its lifecycle to the app lifecycle and gives access to `updater` for UI bindings.

**Alternative considered**: A dedicated `UpdateManager` singleton. Unnecessary wrapper — Sparkle's controller is already a well-scoped object.

### 4. UI in AboutView only
"Check for Updates" button and auto-check toggle live in the existing `AboutView` tab. This matches macOS convention (e.g., Figma, Raycast). No changes to the menu bar popover footer.

### 5. EdDSA signing in CI via `sign_update` tool
The Sparkle `sign_update` binary (extracted from the Sparkle release artifact in CI) signs the DMG using a private key stored as a GitHub Actions secret (`SPARKLE_PRIVATE_KEY`). The signature and file size are embedded in the generated `appcast.xml`.

## Risks / Trade-offs

- **Unsigned app + Sparkle update**: After Sparkle installs an update in-place, macOS may quarantine the new binary. Since the app is unsigned, users could see another Gatekeeper prompt after the first Sparkle update. → Mitigation: Document this in the release notes; it only happens once after transitioning from manual install to Sparkle-managed updates.
- **Private key loss**: If `SPARKLE_PRIVATE_KEY` is lost, future updates cannot be signed and users cannot receive them. → Mitigation: Back up the private key securely (e.g., password manager) before adding to GitHub secrets.
- **appcast.xml only shows latest version**: With per-release appcast, users on very old versions see only one jump target (latest). → Acceptable for this app's scale and release cadence.

## Migration Plan

1. Maintainer runs `generate_keys` locally (one-time), saves private key to secure storage, adds to GitHub secret `SPARKLE_PRIVATE_KEY`.
2. Public key is added to `Info.plist` as `SUPublicEDKey` in code.
3. Next release triggers updated CI workflow which signs DMG and uploads `appcast.xml`.
4. Existing users on older versions must manually install the first Sparkle-enabled release. All subsequent updates are automatic.

**Rollback**: Remove Sparkle dependency and revert `AppDelegate` + `AboutView` changes. Users would revert to manual updates.

## Open Questions

- What is the GitHub repo owner/name? Needed to finalize the `SUFeedURL` value in `Info.plist`. (Can be filled in during implementation.)
