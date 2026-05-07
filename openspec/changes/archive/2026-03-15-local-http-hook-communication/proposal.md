## Why

The current URL scheme-based hook communication (`open 'alerto://...'`) causes macOS to re-launch or re-activate the app on every hook invocation, preventing clean app termination and creating unnecessary process overhead. Switching to local HTTP socket communication allows the app to run as a persistent background server that receives requests without being "summoned," enabling proper lifecycle management and eliminating the re-launch behavior.

## What Changes

- Add local HTTP server that listens on a configurable port (default: localhost only)
- Create REST API endpoint `/notify` to receive notification requests
- Add `/health` endpoint for server status checking
- Update hook integration instructions to use `curl` instead of `open` URL scheme
- Add port configuration in settings UI
- Add server status indicator in menu bar (running/stopped)
- Implement graceful server startup/shutdown
- **BREAKING**: Hooks must be updated from URL scheme to HTTP calls

## Capabilities

### New Capabilities

- `http-notification-server`: Local HTTP server for receiving notification requests from external tools (Claude Code, OpenCode, etc.)

### Modified Capabilities

None - this is a new communication channel that coexists with the existing URL scheme handler.

## Impact

- **New Files**: HTTP server implementation, server management logic
- **Modified Files**: SettingsView (port config, updated instructions), MenuBarView (server status), AppDelegate (server lifecycle)
- **Dependencies**: May need to add HTTP server library (Hummingbird, Vapor, or use Network.framework)
- **Configuration**: New setting for HTTP port number
- **Users**: Must update their hook configurations from URL scheme to HTTP calls
