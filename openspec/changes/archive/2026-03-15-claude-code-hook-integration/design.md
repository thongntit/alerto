## Context

Alerto is a macOS menu bar app that displays AI agent notifications. Currently, Claude Code integration requires manual URL scheme setup. We need to automatically inject Claude Code hooks to send HTTP notifications.

**Current State:**
- Alerto uses URL scheme (`alerto://notify`) for notifications
- Claude Code supports hooks that execute commands on events (TaskStart, TaskComplete, Stop)
- No automatic configuration mechanism exists

**Constraints:**
- Must work with Claude Code's existing hook system
- No external npm packages - integrate directly into the macOS app
- Idempotent installation (safe to re-run)
- Handle port conflicts gracefully

## Goals / Non-Goals

**Goals:**
- Automatically inject Claude Code hooks into `~/.claude/settings.json`
- Run HTTP server to receive notifications from hooks
- Provide UI toggle to enable/disable hook integration
- Support TaskStart, TaskComplete, and Stop events

**Non-Goals:**
- OpenCode support (dropped)
- MCP server integration
- URL scheme notifications (deprecated)

## Decisions

### 1. HTTP Server over URL Scheme

**Decision:** Use HTTP POST instead of URL scheme for hook notifications.

**Rationale:**
- URL scheme requires `open` command which is async and harder to debug
- HTTP POST allows structured JSON payload
- Better error handling and health checks

### 2. Idempotent Hook Installation

**Decision:** Use filter-by-id pattern for hook installation.

**Rationale:**
- Each hook has unique `id` field
- Remove existing hook with same id before adding new one
- Prevents duplicates on re-installation

### 3. Dynamic Port Selection

**Decision:** Try default port (21452), fallback to alternatives (21453, 21454).

**Rationale:**
- Avoid hardcoded port conflicts
- Alerto already uses 21452, try to maintain consistency

### 4. No External Dependencies

**Decision:** Use native Swift NIO or URLSession for HTTP server.

**Rationale:**
- Avoid adding dependencies for simple HTTP server
- Use lightweight approach with URLSession-based server or Vapor

**Alternatives Considered:**
- URLSession with custom server (lightweight, sufficient for our needs)
- Vapor framework (overkill for single endpoint)
- SwiftNIO (more complex setup)

## Risks / Trade-offs

- **[Risk] Claude Code settings.json format changes** → Mitigation: Version check, graceful degradation
- **[Risk] Port already in use** → Mitigation: Try alternative ports, show error if all fail
- **[Risk] User has custom hooks** → Mitigation: Only remove Alerto hooks by ID, preserve others

## Migration Plan

1. First launch: Detect Claude Code, prompt user to enable hooks
2. On enable: Write hooks to settings.json, start HTTP server
3. On disable: Remove only Alerto hooks, stop HTTP server
4. No migration needed - fresh feature

## Open Questions

- Should we support `Notification` hook event in addition to TaskStart/TaskComplete/Stop?
- Should we validate hooks were actually written (e.g., ask Claude Code to reload config)?
