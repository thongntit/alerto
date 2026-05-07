## ADDED Requirements

### Requirement: Log entry structure
The system SHALL define a `LogEntry` value type with the fields: `id` (UUID), `timestamp` (Date), `level` (LogLevel enum: debug/info/warning/error), `category` (LogCategory enum: http/notification/display/system), and `message` (String, max 256 characters).

#### Scenario: Message truncation
- **WHEN** a log message longer than 256 characters is submitted
- **THEN** the stored message SHALL be truncated to 256 characters with a trailing ellipsis

### Requirement: Singleton AppLogger service
The system SHALL provide an `AppLogger` singleton (`AppLogger.shared`) that is the single point of entry for emitting log entries throughout the app.

#### Scenario: Log entry recorded
- **WHEN** any component calls `AppLogger.shared.log(level:category:message:)`
- **THEN** a `LogEntry` with the given level, category, message, and current timestamp SHALL be appended to the in-memory ring buffer

### Requirement: Ring buffer with configurable capacity
The in-memory log buffer SHALL be capped at 500 entries. When the buffer is full, the oldest entry SHALL be evicted before a new one is inserted.

#### Scenario: Buffer overflow eviction
- **WHEN** the buffer already contains 500 entries and a new entry is logged
- **THEN** the oldest entry SHALL be removed and the new entry appended, keeping the count at 500

### Requirement: Minimum log level filter
`AppLogger` SHALL respect a user-configurable minimum log level. Log calls below the minimum level SHALL be silently discarded without creating a `LogEntry`.

#### Scenario: Entry below minimum level discarded
- **WHEN** the minimum level is set to `.warning` and a `.debug` message is logged
- **THEN** no entry SHALL be added to the ring buffer

#### Scenario: Entry at or above minimum level recorded
- **WHEN** the minimum level is set to `.info` and an `.info` message is logged
- **THEN** the entry SHALL be added to the ring buffer

### Requirement: Persist log entries across sessions
`AppLogger` SHALL asynchronously serialise the ring buffer to a JSON file at `~/Library/Application Support/Alerto/app.log.json` within one second of any new entry being added.

#### Scenario: Persistence after logging
- **WHEN** a log entry is added
- **THEN** the JSON file SHALL be updated within 1 second reflecting the new entry

### Requirement: Restore log entries on launch
On initialisation, `AppLogger` SHALL attempt to read `app.log.json` and pre-populate the in-memory ring buffer with any previously persisted entries.

#### Scenario: Entries visible after restart
- **WHEN** the app is relaunched after previous log entries were persisted
- **THEN** those entries SHALL appear in the in-memory buffer (up to the ring buffer capacity)

### Requirement: Instrument HTTP request pipeline
`HTTPServerManager` SHALL emit log entries via `AppLogger` for: request received, raw body, parse outcome (success/failure), validation errors, and the final notification dispatched.

#### Scenario: Successful request logged end-to-end
- **WHEN** a valid POST to `/notify` is processed
- **THEN** at least four log entries SHALL exist: request received, body parsed, notification type resolved, notification dispatched

#### Scenario: Parse failure logged
- **WHEN** the POST body cannot be decoded as `HookPayload` or `NotifyRequest`
- **THEN** a `.warning` entry in the `http` category SHALL be logged

### Requirement: Instrument notification display pipeline
`NotificationManager` SHALL emit log entries via `AppLogger` for: notification received, overlay shown or skipped (with reason), sound played or skipped (with reason), and notification added to history.

#### Scenario: Overlay suppressed reason logged
- **WHEN** the overlay setting is disabled and a notification arrives
- **THEN** a `.info` entry SHALL be logged with message indicating overlay was skipped because the setting is off
