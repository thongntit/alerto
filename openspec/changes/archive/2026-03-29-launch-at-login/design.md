## Context

Alerto is a macOS menu bar utility (`LSUIElement = true`, no dock icon) that receives notifications from Claude Code via a local HTTP server. The app currently has no way to start automatically on login, requiring users to manually launch it each session.

This design covers adding launch-at-login support using `SMAppService.mainApp` from the `ServiceManagement` framework.

## Goals / Non-Goals

**Goals:**
- Allow users to enable/disable automatic startup via a toggle in General Settings
- Reflect real system state in the UI at all times
- Handle all `SMAppService.Status` states gracefully
- Open System Settings directly when user approval is required

**Non-Goals:**
- Launching the app hidden or minimized (out of scope — menu bar app is already unobtrusive)
- Supporting MDM/enterprise deployment configurations (beyond per-user SMAppService)
- Launching specific sub-features or agents at login
- Auto-starting dependent services or daemons

## Decisions

### D1: Use `SMAppService.mainApp` over `LSSharedFileList`

**Decision:** `SMAppService.mainApp` is the primary API.

**Rationale:**
- Apple-supported, non-deprecated API introduced in macOS 13
- Sandboxing-compatible (unlike `LSSharedFileList` which is blocked by sandbox)
- Clean registration/unregistration with no filesystem artifacts
- Returns a `Status` enum for reactive UI binding

**Alternative considered:** `LSSharedFileList` — deprecated by Apple, incompatible with sandboxed apps, no `Status` feedback.

**Alternative considered:** LaunchAgent plist — overkill for a menu bar utility, breaks sandbox, requires manual lifecycle management.

---

### D2: `LaunchAtLoginService` as a dedicated singleton

**Decision:** A dedicated `LaunchAtLoginService` singleton wraps `SMAppService.mainApp`.

```swift
@MainActor
class LaunchAtLoginService: ObservableObject {
    static let shared = LaunchAtLoginService()

    @Published private(set) var status: SMAppService.Status = .notRegistered
    // ...
}
```

**Rationale:**
- `SMAppService.mainApp` is a global shared instance — wrapping it in a service provides a stable `ObservableObject` interface for SwiftUI binding
- Centralizes error handling and status polling in one place
- Keeps `GeneralSettingsView` lean and declarative
- Allows future extension (e.g., observing status changes reactively) without touching views

**Alternative considered:** Calling `SMAppService.mainApp` directly in `GeneralSettingsView` — pollutes the view with `ServiceManagement` imports and error handling logic.

---

### D3: Status-aware toggle with approval handler

**Decision:** The toggle reflects `status` reactively and handles `.requiresApproval` with an explicit helper button.

```
┌─ General ───────────────────────────────────────────────┐
│  ☑ Show overlay notification                            │
│  ☑ Launch at Login                               [⚙️]  │
│          ↑ Toggle is OFF, status = .notRegistered       │
└────────────────────────────────────────────────────────┘

┌─ General ───────────────────────────────────────────────┐
│  ☑ Show overlay notification                            │
│  ☐ Launch at Login                    [Open Settings]  │
│          ↑ Toggle is ON but requires approval           │
└────────────────────────────────────────────────────────┘
```

**Rationale:**
- `.requiresApproval` means the toggle is enabled but the user hasn't granted permission yet — hiding or disabling the toggle would be confusing
- Showing a "Open System Settings" button directly resolves the UX friction
- The toggle state always matches the user's intent, not just the system state

---

### D4: No `@AppStorage` persistence for login item state

**Decision:** Do not mirror the launch-at-login state into `UserDefaults`.

**Rationale:**
- `SMAppService` itself is the source of truth. Persisting a separate `UserDefaults` flag creates a split-brain scenario where the two can diverge (e.g., after a system update or manual change in System Settings).
- The toggle simply reflects and controls `SMAppService.status`. No persistence needed.

**Alternative considered:** Dual-state with sync logic — adds complexity for no real benefit.

---

### D5: Module import strategy

**Decision:** Import `ServiceManagement` directly in `LaunchAtLoginService`.

**Rationale:**
- `ServiceManagement` is a system framework with no bundled dependencies
- No SPM package or third-party wrapper needed

---

## Risks / Trade-offs

| Risk | Mitigation |
|---|---|
| macOS prompts for approval on first register, confusing some users | Clear UI explanation + "Open System Settings" button when in `.requiresApproval` state |
| Status becomes `.notRegistered` after macOS system update | The service is queried on `onAppear` and via periodic status checks; toggle reflects reality |
| App is sandboxed (App Store build) and `SMAppService` is blocked | Confirmed: `SMAppService.mainApp` works in sandboxed apps on macOS 13+ |
| Frequent logout/login cycles needed for testing | Use `launchctl bootout gui/<uid>/<bundle-id>` as a dev workaround to simulate logout |
| Privacy description required in entitlements | No additional entitlements needed for `SMAppService` |

## Open Questions

- **Q1: Does the first `register()` call always trigger a system dialog, or does macOS sometimes silently register?**

  Some apps report a silent registration on first call. This is worth spike-testing early in implementation to calibrate the UX expectations. If it always prompts, we should show a brief tooltip after enabling: *"Approval may be required — click 'Open System Settings' if prompted."*

- **Q2: Should we use `SMAppService.Status` polling or rely on `@Published` observation?**

  `SMAppService.mainApp.status` is a computed property (no KVO). The practical approach is to read it on `GeneralSettingsView.onAppear` and after each toggle action. A timer-based poll (every 30s) could catch external changes (e.g., user disables in System Settings).

- **Q3: Do we need to handle `SMAppService.mainApp` on macOS versions before 13?**

  The app's minimum target is macOS 15.0+ (`#if canImport`). Safe to assume `SMAppService` is always available with no availability guards.
