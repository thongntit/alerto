## Context

The agent-alert app currently uses macOS URL schemes (`agent-alert://notify?...`) for receiving notification requests from external tools. When a hook executes `open 'agent-alert://...'`, macOS sends an Apple Event to the app, launching it if not running. This creates several issues:

1. **Process Re-activation**: Every hook call causes macOS to "summon" the app, interfering with normal app lifecycle
2. **No Clean Termination**: The app cannot cleanly quit because external hooks may re-launch it
3. **Limited Control**: No way to check if the server is running or configure communication parameters

The proposed solution replaces URL scheme communication with a local HTTP server that listens on localhost, allowing persistent background operation without process re-activation.

## Goals / Non-Goals

**Goals:**
- Add local HTTP server that runs on a configurable port (localhost only)
- Provide REST API for notification triggering (`/notify` endpoint)
- Enable health/status checking (`/health` endpoint)
- Allow graceful server startup and shutdown
- Support both URL scheme and HTTP simultaneously for migration
- Update integration instructions for Claude Code and OpenCode hooks

**Non-Goals:**
- Remote network access (localhost only for security)
- Authentication/authorization (trusted local environment)
- WebSocket or persistent connections
- Rate limiting (trusted sources)
- Removing the existing URL scheme handler (keep for backward compatibility)

## Decisions

### D1: HTTP Server Library - Hummingbird

**Decision**: Use Hummingbird as the HTTP server framework.

**Rationale**:
- Lightweight, designed for server-side Swift
- Native Swift concurrency support (async/await)
- No external dependencies beyond SwiftPM
- Simpler than Vapor for a single-endpoint use case
- Good macOS support

**Alternatives considered**:
- **Network.framework (raw)**: More control but significantly more boilerplate for HTTP parsing
- **Vapor**: Overkill for a simple notification endpoint, heavier dependency footprint
- **Swifter**: Less maintained, no async/await support

### D2: Port Configuration

**Decision**: Default port 7531, configurable via settings UI.

**Rationale**:
- High port number avoids conflicts with common services
- Configurable allows users to resolve port conflicts
- Store in UserDefaults for persistence

**Alternatives considered**:
- **Dynamic port assignment**: Harder for users to configure hooks
- **Unix socket**: More complex for cross-tool integration (curl doesn't work directly)

### D3: API Design

**Decision**: RESTful JSON API with query parameter support.

```
POST /notify
  Body: {"source": "claude", "type": "attention", "message": "..."}
  Query: ?source=claude&type=attention&message=...
  
GET /health
  Response: {"status": "ok", "uptime": 123}
```

**Rationale**:
- JSON body is modern and extensible
- Query params support allows simple `curl` calls without JSON
- Both formats supported for flexibility

### D4: Server Lifecycle

**Decision**: Server starts automatically on app launch, stops on quit. Manual toggle in settings.

**Rationale**:
- Automatic start ensures hooks always work
- Manual toggle allows debugging or temporary disable
- Graceful shutdown prevents dropped requests

### D5: Coexistence with URL Scheme

**Decision**: Keep URL scheme handler active alongside HTTP server.

**Rationale**:
- Backward compatibility during migration
- Users can switch gradually
- URL scheme as fallback if HTTP fails
- No breaking change for existing users

## Risks / Trade-offs

### R1: Port Conflicts
- **Risk**: Another process may already use the default port
- **Mitigation**: Allow port configuration in settings, show clear error message if port is occupied

### R2: Server Availability
- **Risk**: App must be running for HTTP server to work
- **Mitigation**: Keep URL scheme as fallback, add menu bar indicator showing server status

### R3: Breaking Hook Configurations
- **Risk**: Users must update their hook configurations to use HTTP
- **Mitigation**: Keep URL scheme working, provide clear migration instructions in settings UI

### R4: Security
- **Risk**: Local HTTP server could theoretically be accessed by other local processes
- **Mitigation**: Bind to localhost only (127.0.0.1), no network exposure. Trusted local environment assumption.

### R5: Memory/CPU Overhead
- **Risk**: HTTP server adds resource overhead
- **Mitigation**: Hummingbird is lightweight, minimal impact expected. Monitor in testing.
