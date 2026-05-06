## Why

Claude Code can trigger notifications for task lifecycle events (TaskStart, TaskComplete, Stop), but currently requires manual URL scheme configuration to integrate with Alerto. We need an automatic hook injection mechanism that configures Claude Code to send HTTP notifications to Alerto without user manual setup.

## What Changes

- Add **ClaudeCodeHookManager** to read/write Claude Code hook configuration in `~/.claude/settings.json`
- Add **HTTPServerService** to receive POST notifications from Claude Code hooks
- Add **Settings UI** toggle to enable/disable Claude Code hook integration
- Implement idempotent hook installation (safe to re-run without duplicates)
- Support TaskStart, TaskComplete, and Stop hook events

## Capabilities

### New Capabilities

- **claude-code-hook**: Inject Claude Code hooks to send HTTP notifications to Alerto
- **http-notification-receiver**: HTTP server endpoint to receive notifications from hooks

### Modified Capabilities

- *(none)* - This is a new feature with no existing spec modifications

## Impact

- New files: `Managers/ClaudeCodeHookManager.swift`, `Services/HTTPServerService.swift`
- Modified files: `AlertoApp.swift` (register HTTP server), `Views/SettingsView.swift` (hook toggle)
- No external dependencies required (uses native Swift NIO for HTTP)
