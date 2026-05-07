## ADDED Requirements

### Requirement: HTTP Server Startup

The system SHALL start an HTTP server to receive notifications from Claude Code hooks.

#### Scenario: HTTP server starts successfully
- **WHEN** Alerto launches
- **AND** hook integration is enabled
- **THEN** the system SHALL start the HTTP server on the configured port
- **AND** be ready to receive POST requests

### Requirement: Notification Endpoint

The system SHALL expose a POST endpoint to receive notifications.

#### Scenario: Valid notification received
- **WHEN** HTTP server receives POST request to `/notify`
- **AND** request body contains valid JSON with source, type, and message
- **THEN** the system SHALL display a notification overlay
- **AND** play the configured sound

#### Scenario: Invalid request received
- **WHEN** HTTP server receives POST request to `/notify`
- **AND** request body is invalid JSON
- **THEN** the system SHALL return HTTP 400 Bad Request

### Requirement: Health Check Endpoint

The system SHALL expose a GET endpoint for health checks.

#### Scenario: Health check requested
- **WHEN** HTTP server receives GET request to `/health`
- **THEN** the system SHALL return HTTP 200 OK
- **AND** response body SHALL contain `{ "status": "ok" }`

### Requirement: Notification Display

The system SHALL display notifications with appropriate formatting.

#### Scenario: TaskStart notification display
- **WHEN** HTTP server receives notification with type "start"
- **THEN** the system SHALL display overlay with "Task started" message
- **AND** use the appropriate icon for start type

#### Scenario: TaskComplete notification display
- **WHEN** HTTP server receives notification with type "complete"
- **THEN** the system SHALL display overlay with completion message
- **AND** use the appropriate icon for complete type

#### Scenario: Stop notification display
- **WHEN** HTTP server receives notification with type "stop"
- **THEN** the system SHALL display overlay indicating Claude Code stopped
- **AND** use the appropriate icon for stop type

### Requirement: HTTP Server Shutdown

The system SHALL gracefully shut down the HTTP server when disabled.

#### Scenario: Hook integration disabled
- **WHEN** the user disables hook integration
- **THEN** the system SHALL stop the HTTP server
- **AND** release the port
