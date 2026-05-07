## 1. Core Logger Service

- [x] 1.1 Create `alerto/Services/AppLogger.swift` — define `LogLevel` (debug/info/warning/error) and `LogCategory` (http/notification/display/system) enums, both `CaseIterable` and `Comparable`
- [x] 1.2 Define `LogEntry` struct with `id: UUID`, `timestamp: Date`, `level: LogLevel`, `category: LogCategory`, `message: String`; add truncation to 256 chars in the initialiser
- [x] 1.3 Implement `AppLogger` as a `@MainActor ObservableObject` singleton with `@Published var entries: [LogEntry]` ring buffer (capacity 500)
- [x] 1.4 Add `log(level:category:message:)` method that checks the minimum level, creates a `LogEntry`, appends to the buffer (evicting oldest when full), and schedules a debounced disk write
- [x] 1.5 Add convenience methods: `debug(_:category:)`, `info(_:category:)`, `warning(_:category:)`, `error(_:category:)`

## 2. Persistence

- [x] 2.1 Implement `persistToDisk()` in `AppLogger` — serialise `entries` as JSON to `~/Library/Application Support/Alerto/app.log.json` on a background `Task`; debounce writes within a 1-second window
- [x] 2.2 Implement `loadFromDisk()` in `AppLogger` — read and decode `app.log.json` on initialisation, pre-populating the buffer (respecting capacity)
- [x] 2.3 Implement `clearPersistedFile()` — delete `app.log.json` from disk; call this from the clear action
- [x] 2.4 Add `Codable` conformance to `LogEntry`, `LogLevel`, and `LogCategory`

## 3. User Preference for Minimum Level

- [x] 3.1 Add `@AppStorage("logMinLevel") var minimumLevel: LogLevel` to `AppLogger`, defaulting to `.info` (`.debug` in DEBUG builds)
- [x] 3.2 Ensure `log(level:category:message:)` silently returns when `level < minimumLevel`

## 4. Instrument HTTP Server

- [x] 4.1 In `HTTPServerManager.handleNotify`: replace existing `print` / `logger` calls with `AppLogger.shared.info/warning/error` calls using category `.http`
- [x] 4.2 Log: request received (method + path), raw body string, parse result (HookPayload or NotifyRequest or failure), each validation error, and the final notification dispatched with resolved source/type/hookType

## 5. Instrument Notification Manager

- [x] 5.1 In `NotificationManager.handleNotification`: log entry received with source, type, and truncated message (category `.notification`)
- [x] 5.2 In `NotificationManager.showNotification`: log "overlay shown" or "overlay skipped (setting disabled)" (category `.display`)
- [x] 5.3 In `NotificationManager.showNotification`: log "sound played: <name>" or "sound skipped (setting disabled)" (category `.display`)
- [x] 5.4 In `NotificationManager.dismissOverlay`: log "notification added to history" (category `.notification`)

## 6. Log Viewer UI

- [x] 6.1 Create `alerto/Views/LogViewerView.swift` — `LogViewerView` as a SwiftUI `View` observing `AppLogger.shared`
- [x] 6.2 Implement the entry list: `List` of `LogEntryRow` sub-views showing timestamp (`HH:mm:ss.SSS`), colour-coded level badge, category label, and message
- [x] 6.3 Add a `Picker` / segmented control at the top for filter level (All / Info / Warning / Error); filter is applied in-memory on the `entries` array
- [x] 6.4 Add "Copy All" toolbar button — formats visible entries as `[timestamp] [LEVEL] [category] message`, one per line, and writes to `NSPasteboard`
- [x] 6.5 Add "Clear" toolbar button — calls `AppLogger.shared.entries.removeAll()` and `AppLogger.shared.clearPersistedFile()`
- [x] 6.6 Implement auto-scroll: use `ScrollViewReader` + `.onChange(of: entries.count)` to scroll to the top id when the list is at the newest entry

## 7. Wire into Settings

- [x] 7.1 Add `LogViewerView` as a new tab in `SettingsView` with label "Logs" and system image `doc.text.magnifyingglass`
- [x] 7.2 Add minimum log level picker to `LogViewerView` (or a sub-section of the Logs tab) that reads/writes `AppLogger.shared.minimumLevel` and persists via `@AppStorage`

## 8. Xcode Project Integration

- [x] 8.1 Add `AppLogger.swift` to the `Alerto` target in `alerto.xcodeproj`
- [x] 8.2 Add `LogViewerView.swift` to the `Alerto` target in `alerto.xcodeproj`
- [x] 8.3 Build and confirm no warnings or errors introduced by the new files
- [ ] 8.4 Run the app, send a test notification via `curl`, open Settings > Logs and confirm entries appear for the full request pipeline
