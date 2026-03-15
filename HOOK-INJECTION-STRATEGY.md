# Claude Code Hook Injection Strategy

## Overview

This document describes how Agent Alert automatically configures Claude Code hooks to send notifications via HTTP. The implementation is integrated directly into the Agent Alert macOS app - no separate npm package required.

---

## Architecture

### Notification Flow

```
Claude Code (Hook) → HTTP POST → Agent Alert (HTTP Server) → Overlay Notification
```

### Configuration Files

| Tool | Config File | Hooks Key |
|------|-------------|-----------|
| Claude Code | `~/.claude/settings.json` | `hooks` |

---

## Claude Code Hook Configuration

### Hook Structure

Each hook must have a unique `id` field for detection and idempotent installation:

```json
{
  "hooks": {
    "TaskStart": [
      {
        "id": "agent-alert:task-start",
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "curl -X POST http://localhost:AS_PORT/notify -H 'Content-Type: application/json' -d '{\"source\":\"claude\",\"type\":\"start\",\"message\":\"Task started: $PROMPT\"}'"
          }
        ]
      }
    ],
    "TaskComplete": [
      {
        "id": "agent-alert:task-complete",
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "curl -X POST http://localhost:AS_PORT/notify -H 'Content-Type: application/json' -d '{\"source\":\"claude\",\"type\":\"complete\",\"message\":\"Task completed: $PROMPT\"}'"
          }
        ]
      }
    ],
    "Notification": [
      {
        "id": "agent-alert:notification",
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "curl -X POST http://localhost:AS_PORT/notify -H 'Content-Type: application/json' -d '{\"source\":\"claude\",\"type\":\"attention\",\"message\":\"$NOTIFICATION\"}'"
          }
        ]
      }
    ]
  }
}
```

> **Note**: `AS_PORT` is a dynamic port that Agent Alert listens on (default: 21452)

---

## Implementation: ClaudeCodeHookManager

### Core Methods

```swift
class ClaudeCodeHookManager {

    // MARK: - Configuration Paths

    var settingsPath: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".claude/settings.json")
    }

    // MARK: - Detection

    func isHookInstalled(hookId: String) -> Bool {
        guard let settings = loadSettings(),
              let hooks = settings["hooks"] as? [String: [[String: Any]]] else {
            return false
        }

        for (_, eventHooks) in hooks {
            if eventHooks.contains(where: { ($0["id"] as? String) == hookId }) {
                return true
            }
        }
        return false
    }

    // MARK: - Installation (Idempotent)

    func installHook(event: String, hookConfig: [String: Any]) {
        var settings = loadSettings() ?? [:]

        var hooks = settings["hooks"] as? [String: [[String: Any]]] ?? [:]

        // Remove existing hook with same id (idempotent)
        let hookId = hookConfig["id"] as? String ?? ""
        hooks[event] = (hooks[event] ?? []).filter { ($0["id"] as? String) != hookId }

        // Add new hook
        hooks[event]?.append(hookConfig)

        settings["hooks"] = hooks
        saveSettings(settings)
    }

    // MARK: - Uninstallation

    func uninstallHook(event: String, hookId: String) {
        var settings = loadSettings() ?? [:]
        var hooks = settings["hooks"] as? [String: [[String: Any]]] ?? [:]

        hooks[event] = (hooks[event] ?? []).filter { ($0["id"] as? String) != hookId }

        // Clean up empty arrays
        if hooks[event]?.isEmpty == true {
            hooks.removeValue(forKey: event)
        }
        if hooks.isEmpty {
            settings.removeValue(forKey: "hooks")
        } else {
            settings["hooks"] = hooks
        }

        saveSettings(settings)
    }

    // MARK: - Private

    private func loadSettings() -> [String: Any]? {
        guard FileManager.default.fileExists(atPath: settingsPath.path) else { return nil }

        let data = try? Data(contentsOf: settingsPath)
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }

    private func saveSettings(_ settings: [String: Any]) {
        let data = try? JSONSerialization.data(withJSONObject: settings, options: .prettyPrinted)
        try? data?.write(to: settingsPath)
    }
}
```

---

## Agent Alert Hook Events

| Event | Description | Example Use Case |
|-------|-------------|------------------|
| `TaskStart` | When Claude Code starts a new task | "Starting research on..." |
| `TaskComplete` | When a task is completed | "Task completed: 5 files modified" |
| `Notification` | When Claude Code sends a notification | "Thinking..." |
| `Stop` | When Claude Code exits/stops | "Session ended" |

---

## HTTP Server Integration

The Agent Alert HTTP server receives notifications from Claude Code hooks:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/notify` | POST | Receive notification from hook |
| `/health` | GET | Health check for hook validation |

### Request Format

```json
{
  "source": "claude",
  "type": "start|complete|attention|...",
  "message": "Notification message"
}
```

---

## User Flow

1. **First Launch**: Agent Alert detects Claude Code and prompts to configure hooks
2. **Setup**: App writes hooks to `~/.claude/settings.json`
3. **Usage**: Claude Code automatically sends notifications via HTTP
4. **Uninstall**: User can remove hooks from Settings

---

## Summary

| Feature | Implementation |
|---------|---------------|
| Hook Detection | Check for `id` field in `settings.json` hooks |
| Installation | Filter by id + push (idempotent) |
| Uninstallation | Filter out by id, clean empty arrays |
| Notification Transport | HTTP POST via `curl` command |
| Port Configuration | Dynamic port (default 21452) |
