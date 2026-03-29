## ADDED Requirements

### Requirement: HTTP Server Starts Automatically

The system SHALL start the HTTP notification server automatically when the application launches.

#### Scenario: Server starts on app launch
- **WHEN** the application finishes launching
- **THEN** the HTTP server SHALL be running on the configured port
- **AND** the server SHALL be bound to localhost (127.0.0.1) only

#### Scenario: Server uses configured port
- **WHEN** the application launches with a configured port setting
- **THEN** the HTTP server SHALL listen on that port
- **AND** the default port SHALL be 7531 if not configured

### Requirement: Notification Endpoint

The system SHALL provide an HTTP endpoint to receive notification requests.

#### Scenario: POST notification with JSON body
- **WHEN** a POST request is sent to `/notify` with JSON body `{"source": "claude", "type": "attention", "message": "..."}`
- **THEN** the system SHALL parse the request and display the notification
- **AND** return HTTP 200 with body `{"success": true}`

#### Scenario: POST notification with query parameters
- **WHEN** a POST request is sent to `/notify?source=opencode&type=idle&message=...`
- **THEN** the system SHALL parse query parameters and display the notification
- **AND** return HTTP 200 with body `{"success": true}`

#### Scenario: GET notification with query parameters
- **WHEN** a GET request is sent to `/notify?source=claude&type=attention&message=...`
- **THEN** the system SHALL parse query parameters and display the notification
- **AND** return HTTP 200 with body `{"success": true}`

#### Scenario: Missing required parameters
- **WHEN** a request to `/notify` is missing `source`, `type`, or `message`
- **THEN** the system SHALL return HTTP 400 with body `{"error": "Missing required parameter: <name>"}`

#### Scenario: Invalid source value
- **WHEN** a request to `/notify` contains an invalid `source` value
- **THEN** the system SHALL return HTTP 400 with body `{"error": "Invalid source: <value>"}`

#### Scenario: Invalid type value
- **WHEN** a request to `/notify` contains an invalid `type` value
- **THEN** the system SHALL return HTTP 400 with body `{"error": "Invalid type: <value>"}`

### Requirement: Health Check Endpoint

The system SHALL provide an HTTP endpoint to check server health status.

#### Scenario: Health check returns status
- **WHEN** a GET request is sent to `/health`
- **THEN** the system SHALL return HTTP 200 with body `{"status": "ok", "uptime": <seconds>}`

### Requirement: Port Configuration

The system SHALL allow users to configure the HTTP server port.

#### Scenario: User changes port
- **WHEN** user changes the port setting to a valid port number (1-65535)
- **THEN** the system SHALL save the new port configuration
- **AND** restart the HTTP server on the new port

#### Scenario: Port conflict detected
- **WHEN** the server cannot start because the port is already in use
- **THEN** the system SHALL display an error message indicating the port conflict
- **AND** continue retrying or allow user to change port

### Requirement: Server Status Indicator

The system SHALL display the HTTP server status in the menu bar.

#### Scenario: Server running indicator
- **WHEN** the HTTP server is running successfully
- **THEN** the menu bar SHALL indicate "HTTP: Running on port <port>"

#### Scenario: Server stopped indicator
- **WHEN** the HTTP server is stopped
- **THEN** the menu bar SHALL indicate "HTTP: Stopped"

#### Scenario: Server error indicator
- **WHEN** the HTTP server encounters an error (e.g., port conflict)
- **THEN** the menu bar SHALL indicate "HTTP: Error - <error message>"

### Requirement: Manual Server Control

The system SHALL allow users to manually start and stop the HTTP server.

#### Scenario: User stops server
- **WHEN** user clicks "Stop HTTP Server" in settings or menu
- **THEN** the HTTP server SHALL stop accepting new connections
- **AND** complete any in-flight requests gracefully

#### Scenario: User starts server
- **WHEN** user clicks "Start HTTP Server" in settings or menu while server is stopped
- **THEN** the HTTP server SHALL start on the configured port

### Requirement: Graceful Shutdown

The system SHALL shut down the HTTP server gracefully when the application quits.

#### Scenario: App quits with server running
- **WHEN** the application is about to quit
- **THEN** the HTTP server SHALL stop accepting new connections
- **AND** complete any in-flight requests before shutting down
- **AND** the shutdown SHALL complete within 5 seconds

### Requirement: Updated Hook Integration Instructions

The system SHALL display updated integration instructions using HTTP instead of URL scheme.

#### Scenario: Claude Code hook configuration displayed
- **WHEN** user views settings
- **THEN** the Claude Code hook configuration SHALL show HTTP-based curl command
- **AND** the configuration SHALL use the currently configured port

#### Scenario: OpenCode plugin configuration displayed
- **WHEN** user views settings
- **THEN** the OpenCode plugin configuration SHALL show HTTP-based fetch example
- **AND** the configuration SHALL use the currently configured port
