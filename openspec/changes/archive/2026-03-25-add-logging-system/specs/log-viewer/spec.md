## ADDED Requirements

### Requirement: Logs tab in Settings
The system SHALL add a "Logs" tab to `SettingsView` that displays all entries from `AppLogger`'s ring buffer in reverse-chronological order (newest first).

#### Scenario: Logs tab visible in Settings
- **WHEN** the user opens the Settings window
- **THEN** a "Logs" tab SHALL be present alongside the existing General, HTTP Server, Integrations, and About tabs

#### Scenario: Entries listed newest-first
- **WHEN** the Logs tab is displayed
- **THEN** the most recently logged entry SHALL appear at the top of the list

### Requirement: Log entry row display
Each log entry row SHALL display: timestamp (formatted as `HH:mm:ss.SSS`), level badge (colour-coded: debug=gray, info=blue, warning=orange, error=red), category label, and message text.

#### Scenario: Colour-coded level badge
- **WHEN** an error-level entry is rendered
- **THEN** the level badge SHALL be red

### Requirement: Filter by log level
The Logs tab SHALL provide a segmented picker to filter entries by minimum level (All / Info / Warning / Error). Selecting a level SHALL hide entries below that level without deleting them.

#### Scenario: Filter hides lower-level entries
- **WHEN** the user selects "Warning" in the filter picker
- **THEN** only warning and error entries SHALL be visible in the list

#### Scenario: All filter restores full list
- **WHEN** the user selects "All" in the filter picker
- **THEN** all entries at or above the stored minimum level SHALL be visible

### Requirement: Copy all logs to clipboard
The Logs tab SHALL provide a "Copy All" button that copies all currently visible log entries to the system clipboard as plain text (one entry per line: `[timestamp] [level] [category] message`).

#### Scenario: Copy All writes to clipboard
- **WHEN** the user clicks "Copy All"
- **THEN** the clipboard SHALL contain a plain-text representation of every currently visible log entry

### Requirement: Clear log buffer
The Logs tab SHALL provide a "Clear" button that empties the in-memory ring buffer and deletes the persisted JSON file.

#### Scenario: Clear empties the list
- **WHEN** the user clicks "Clear"
- **THEN** the log list SHALL immediately show zero entries and the JSON file SHALL be deleted

### Requirement: Auto-scroll to latest entry
When a new log entry is appended while the Logs tab is open, the list SHALL scroll to show the newest entry if the user was already at the top of the list.

#### Scenario: New entry triggers scroll
- **WHEN** the user is viewing the Logs tab with the list scrolled to the top (newest entry)
- **THEN** a new incoming log entry SHALL appear at the top and the view SHALL remain at the top without requiring manual scroll

### Requirement: Minimum level preference persisted
The user's selected minimum log level SHALL be stored in `UserDefaults` and restored on next launch.

#### Scenario: Preference survives restart
- **WHEN** the user sets the minimum level to "Warning" and restarts the app
- **THEN** the minimum level SHALL still be "Warning" and debug/info calls SHALL be discarded
