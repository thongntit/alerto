## Context

Agent Alert is a macOS menu bar app that receives HTTP POST requests on port 7531, parses them into `AgenticNotification` objects, and optionally shows an overlay and plays a sound. Currently the app emits debug output only via `print()` statements and the Swift `Logger` from the `Logging` package — neither of which is accessible to the end user at runtime.

When notifications are silently dropped (e.g., because the overlay setting is off, or because a parse step fails silently), there is no way for the user to diagnose the issue without attaching Xcode or running Console.app.

The change is purely additive: no HTTP API changes, no notification-behaviour changes.

## Goals / Non-Goals

**Goals:**

- Provide a structured, in-app log viewer so users can self-diagnose missed notifications.
- Capture every significant event: HTTP request received, body parsed/failed, notification created, display decision made (show overlay vs. skip), sound played, errors.
- Support four log levels (debug, info, warning, error) with a user-configurable minimum level.
- Persist the last N log entries across app restarts (optional, capped ring buffer on disk).
- Add a "Logs" tab in Settings that lists entries, allows filtering by level, and supports copy-to-clipboard and clear actions.

**Non-Goals:**

- Remote log shipping or crash reporting.
- Structured log export in JSON/CSV.
- Replacing the existing `Logging`/`OSLog` integration — the new system adds an in-app layer, does not remove system logging.
- Log rotation or multi-file management.

## Decisions

### Decision 1: Custom ring-buffer singleton over third-party logging library

**Choice**: Implement `AppLogger` as a lightweight `@MainActor` `ObservableObject` with an in-memory `[LogEntry]` ring buffer, capped at 500 entries.

**Rationale**: The codebase has no existing logging abstraction that feeds SwiftUI. Adding a dependency (e.g., SwiftyBeaver, CocoaLumberjack) would bring build complexity with no unique benefit for a simple log-viewer use case. A plain `@Published` array integrates directly into SwiftUI views without bridging overhead.

**Alternative considered**: `os.Logger` + Console.app — already present, but requires opening a separate Apple tool; not accessible to typical users.

### Decision 2: Log entries are value types (`struct LogEntry`)

**Choice**: `LogEntry` is a `struct` with `id: UUID`, `timestamp: Date`, `level: LogLevel`, `category: LogCategory`, and `message: String`.

**Rationale**: Value semantics make the ring buffer safe to pass to SwiftUI without `@ObservedObject` on individual entries. Categories (`http`, `notification`, `display`, `system`) allow per-category filtering without a heavier tagging system.

### Decision 3: Instrumentation added at call sites, not via method swizzling or proxy objects

**Choice**: Add `AppLogger.shared.log(...)` calls directly in `HTTPServerManager.handleNotify` and `NotificationManager.showNotification`.

**Rationale**: Keeps the call graph transparent and easy to follow during code review. Avoids AOP complexity that would be disproportionate for a small codebase.

### Decision 4: Persistence via a single JSON file in Application Support

**Choice**: On each new log entry, `AppLogger` serialises the ring buffer to `~/Library/Application Support/AgentAlert/app.log.json` asynchronously on a background task. On launch, it reads this file to pre-populate the in-memory buffer.

**Rationale**: Gives the user access to logs from the previous session without a complex database. The async write ensures the main thread is never blocked.

**Alternative considered**: `UserDefaults` — not suitable for arrays of arbitrary length.

### Decision 5: Log viewer in a new "Logs" tab in SettingsView

**Choice**: Add `LogViewerView` as a fifth tab in `SettingsView` (after About).

**Rationale**: Settings is already the natural home for diagnostic information; the window is already managed by `SettingsWindowManager`. Opening a dedicated second window would complicate window lifecycle management.

## Risks / Trade-offs

- **Disk I/O on every log write** → Mitigated by debouncing the JSON write (coalesce writes within a 1-second window using a `Task` + `sleep`).
- **Ring buffer grows stale on long sessions** → Capped at 500 entries; oldest entries are evicted first, preserving recent context.
- **Sensitive data in logs** → Log entries truncate message bodies to 256 characters and never log auth tokens or file paths beyond the cwd prefix.
- **Performance overhead of JSON serialisation** → Acceptable at ≤500 entries; profiling not required before shipping.

## Migration Plan

1. Add `AppLogger.swift` and `LogViewerView.swift` to the Xcode project target.
2. Wire `AppLogger` initialisation in `AgentAlertApp.swift` (or lazily via `AppLogger.shared`).
3. Add `AppLogger.shared.log(...)` calls to `HTTPServerManager` and `NotificationManager`.
4. Add the Logs tab to `SettingsView`.
5. No schema migrations, no API changes. Rollback: remove the four touched files and the tab addition.

## Open Questions

- Should the minimum log level default to `.info` or `.debug`? (Recommendation: `.info` for release builds; `.debug` in DEBUG builds.)
- Should "Copy All" copy plain text or JSON? (Recommendation: plain text for readability.)
