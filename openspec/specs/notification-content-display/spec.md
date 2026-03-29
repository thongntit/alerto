## ADDED Requirements

### Requirement: Display hook message in notification
The system SHALL display the actual message content from Claude Code hooks in notifications instead of hardcoded messages.

#### Scenario: Notification with message content
- **WHEN** hook provides message content
- **THEN** notification displays the actual message text

#### Scenario: Message truncation
- **WHEN** message content exceeds 200 characters
- **THEN** system truncates with "..." and shows full text in overlay

### Requirement: Show hook type context
The system SHALL display the hook event type as context in the notification.

#### Scenario: Notification hook
- **WHEN** Notification hook triggers
- **THEN** notification shows "Claude needs your input" as title with message as body

#### Scenario: Stop hook
- **WHEN** Stop hook triggers
- **THEN** notification shows "Claude finished" as title

### Requirement: Rich notification content
The system SHALL support notification titles, bodies, and subtitles for better context.

#### Scenario: Full notification context
- **WHEN** notification has title, body, and subtitle
- **THEN** all three are displayed appropriately based on notification type

#### Scenario: Minimal notification
- **WHEN** only message is available
- **THEN** system uses sensible defaults for missing fields
