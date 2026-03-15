## ADDED Requirements

### Requirement: Hook payload parsing
The system SHALL be able to parse JSON payloads received from Claude Code hooks via HTTP POST request body.

#### Scenario: Valid JSON payload received
- **WHEN** HTTP server receives POST request with JSON body containing hook payload
- **THEN** system extracts the relevant fields based on hook type

#### Scenario: Invalid JSON payload received
- **WHEN** HTTP server receives POST request with malformed JSON
- **THEN** system falls back to default message and logs error

#### Scenario: Empty request body
- **WHEN** HTTP server receives POST request with empty body
- **THEN** system falls back to default message

### Requirement: Extract notification message content
The system SHALL extract the `message` field from Notification hook payloads and use it as the notification message.

#### Scenario: Notification hook with message
- **WHEN** hook payload contains `message` field
- **THEN** system uses that message content for notification display

#### Scenario: Notification hook without message
- **WHEN** hook payload lacks `message` field
- **THEN** system uses default message based on notification type

### Requirement: Extract hook event type
The system SHALL determine the hook event type from the payload to provide appropriate notification behavior.

#### Scenario: Notification event
- **WHEN** payload contains notification data
- **THEN** system displays attention-level notification with message content

#### Scenario: Stop event
- **WHEN** payload indicates Claude finished responding
- **THEN** system displays completion notification

### Requirement: Support backward compatibility
The system SHALL accept both old format (source/type/message as top-level fields) and new format (hook payload in request body).

#### Scenario: Old format request
- **WHEN** request contains source, type, message as top-level fields
- **THEN** system processes as before with default handling

#### Scenario: New format request with payload
- **WHEN** request contains hook payload object
- **THEN** system extracts message from payload
