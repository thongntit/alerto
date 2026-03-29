## Why

When notifications fail to appear, it is impossible to determine whether the problem is in Agent Alert (e.g., the HTTP server did not receive the request, parsing failed, or the overlay was suppressed) or in Claude Code (e.g., the hook never fired). A structured, persistent logging system would capture every step of the notification pipeline and surface that information directly inside the app, eliminating guesswork during debugging.

## What Changes

- Introduce a singleton `AppLogger` service that writes timestamped, levelled log entries to an in-memory ring buffer and optionally to a persisted log file on disk.
- Instrument `HTTPServerManager` to log every incoming request, raw body, parse result, and validation outcome.
- Instrument `NotificationManager` to log every display decision (overlay shown, overlay skipped, sound played, added to history).
- Add a **Logs** tab to `SettingsView` with a scrollable, filterable list of log entries and a "Copy All" / "Clear" action.
- Expose log level as a user preference (Debug / Info / Warning / Error) so power users can increase verbosity without recompiling.

## Capabilities

### New Capabilities

- `app-logger`: Central logging service — ring-buffer storage, log levels, file persistence, and a `@Published` log entries array for SwiftUI consumption.
- `log-viewer`: In-app log viewer UI — a new "Logs" tab in `SettingsView` that lists, filters, and lets the user copy or clear log entries.

### Modified Capabilities

<!-- No existing spec-level requirements are changing; instrumentation of existing managers is an implementation detail. -->

## Impact

- **New files**: `AppLogger.swift` (service), `LogViewerView.swift` (SwiftUI view)
- **Modified files**: `HTTPServerService.swift` (add structured log calls), `NotificationManager.swift` (add display-decision logging), `SettingsView.swift` (add Logs tab)
- **No new dependencies** — uses Swift's built-in `os.Logger` / `OSLog` for system-level emission and a custom ring buffer for the in-app viewer
- **No breaking changes** to the HTTP API or existing notification behaviour
