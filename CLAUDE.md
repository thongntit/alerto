# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Agent Alert** is a macOS menu bar application that displays intelligent notifications from AI agents and tools without interrupting your workflow. It runs as a menu bar utility (LSUIElement = true) with no dock icon.

## Commands

### Build and Run

```bash
# Build the project
xcodebuild -project agent-alert.xcodeproj -scheme agentic-notifier -configuration Release build

# Build with derived data
xcodebuild -project agent-alert.xcodeproj -scheme agentic-notifier -configuration Release -derivedDataPath build build

# Open in Xcode
open agent-alert.xcodeproj
```

### URL Scheme Testing

```bash
# Test notification
open "agent-alert://test"
```

## Architecture

### Core Components

- **AgentAlertApp.swift**: Main entry point using SwiftUI App with `@NSApplicationDelegateAdaptor`. Registers URL scheme handler and overlay manager on launch.
- **NotificationManager** (Singleton): Central hub for notification state, handles display, sound playback, and manages notification queue/history.
- **URLSchemeHandler** (Singleton): Processes incoming `agent-alert://` URLs using Apple Event Manager. Supports `notify` and `test` endpoints.
- **HTTPServerService**: Local HTTP server for receiving notifications via POST requests.
- **NotificationOverlayManager**: Manages overlay window display.

### Models

- **Notification.swift**: Defines `NotificationSource` (claude, opencode, cursor, windsurf, other), `NotificationType` (complete, permission, question, idle, attention, error), and `AgenticNotification` struct.

### Views

- **MenuBarView**: SwiftUI menu bar interface accessible via system menu bar icon.
- **SettingsView**: Configuration panel for sound preferences and notification history.
- **NotificationOverlayView**: Floating overlay displayed for incoming notifications.

## URL Scheme

The app registers the `agent-alert://` URL scheme.

| Path | Parameters | Description |
|------|------------|-------------|
| `agent-alert://notify` | `source`, `type`, `message` | Send a notification |
| `agent-alert://test` | - | Trigger test notification |

**Notification Sources**: claude, opencode, cursor, windsurf, other
**Notification Types**: complete, permission, question, idle, attention, error

## System Requirements

- macOS 14.0+
- Xcode 15.0+
- Swift 5.9+

## CI/CD

GitHub Actions workflow (`.github/workflows/release.yml`) builds a DMG on GitHub releases using the `agentic-notifier` scheme.
