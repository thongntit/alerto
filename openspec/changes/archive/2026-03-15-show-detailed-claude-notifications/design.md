## Context

Agent Alert currently integrates with Claude Code hooks to show notifications when Claude needs attention or finishes tasks. However, the current implementation uses hardcoded messages in curl commands (e.g., "Claude needs attention", "Claude Code stopped"), which provides limited value to users.

Claude Code hooks expose rich contextual information through JSON payloads:
- **Notification hook**: Provides `message` content when Claude needs input/permission
- **Stop hook**: Provides `stop_hook_active` flag when Claude finishes responding
- **UserPromptSubmit**: Provides the actual `prompt` text from the user
- **PermissionRequest**: Provides `tool_name` and `tool_input` details

The current implementation ignores this data and sends hardcoded messages. We can leverage this data to show meaningful notifications.

## Goals / Non-Goals

**Goals:**
- Parse JSON payloads from Claude Code hook events
- Extract and display actual message content from hooks
- Show what Claude Code is asking the user (prompts, permissions)
- Support multiple hook types with appropriate notification behavior

**Non-Goals:**
- Support all 13 Claude Code hook events (focus on high-value ones)
- Store or persist hook data beyond display
- Add complex natural language processing of messages

## Decisions

### 1. Hook Payload Delivery Method

**Decision**: Use `command` type hooks that read from stdin and pipe JSON to HTTP endpoint.

**Rationale**: Claude Code hooks support both command and URI types. Command hooks can read hook payload from stdin. We'll modify curl commands to pipe stdin content.

**Alternative Considered**: Using URI hooks - simpler but can't pass payload data.

### 2. Message Extraction Strategy

**Decision**: Extract the most relevant field per hook type:
- Notification: Use `message` field directly
- Stop: Use generic "Completed" message (no payload in Stop hook)
- Future hooks: Extract relevant fields based on hook type

**Rationale**: Different hooks provide different payloads. We extract the most user-relevant information for each.

### 3. Notification Display

**Decision**: Display extracted message in both notification title and body, with hook type as subtitle.

**Rationale**: Users need context about what triggered the notification (input needed, task complete, etc.).

### 4. Backward Compatibility

**Decision**: Support both old (hardcoded) and new (payload) message formats.

**Rationale**: Existing users shouldn't break if they have old hook configs. The HTTP endpoint will accept both formats.

## Risks / Trade-offs

- **[Risk]**: Hook payload format may change with Claude Code updates
  - **Mitigation**: Add validation and fallback to defaults if parsing fails

- **[Risk]**: Long messages may truncate in notifications
  - **Mitigation**: Truncate at 200 characters with "..." suffix, show full in overlay

- **[Risk]**: Some hooks don't provide useful payload data
  - **Mitigation**: Use sensible defaults for hooks without payload

## Migration Plan

1. Update hook configurations in ClaudeCodeHookManager to pass stdin content
2. Update HTTP server to parse JSON payloads from request body
3. Add hook event type detection
4. Update NotificationManager to handle rich content
5. Users will automatically get improved notifications after updating hooks via the app

No migration needed for end users - they can re-install hooks from settings to get the new behavior.
