## Why

Currently, Agent Alert displays hardcoded notification messages when Claude Code triggers hooks (like "Claude needs your input" or "Task completed"). This provides limited value since users can't see what's actually happening. Claude Code hooks expose rich contextual information including message content, prompts, and tool details that could make notifications far more useful.

## What Changes

- Add support for parsing Claude Code hook payloads (JSON via stdin)
- Extract message content from the `Notification` hook event
- Extract prompt text from the `UserPromptSubmit` hook event
- Extract tool/permission details from `PermissionRequest` hook events
- Display actual message content in notifications instead of generic messages
- Add hook event type detection to show context (e.g., "Claude is waiting for input", "Permission needed")
- Support multiple hook types with different notification behaviors

### New Capabilities

- **hook-payload-parsing**: Parse JSON payloads from Claude Code hooks via stdin and extract relevant fields
- **notification-content-display**: Show actual message/prompt content in notifications instead of generic messages
- **multi-hook-support**: Support Notification, Stop, UserPromptSubmit, and PermissionRequest hook events with appropriate messaging

### Modified Capabilities

- None - this is a net-new feature

## Impact

- New parsing logic in URLSchemeHandler or dedicated hook processor
- Updated NotificationManager to handle richer content
- Modified NotificationOverlayView to display longer message content
- No external API changes or dependency updates required
