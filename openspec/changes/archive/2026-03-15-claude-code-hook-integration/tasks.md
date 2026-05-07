## 1. HTTP Server Implementation

- [x] 1.1 Create HTTPServerService.swift with POST /notify and GET /health endpoints
- [x] 1.2 Add HTTP server startup/shutdown methods
- [x] 1.3 Integrate HTTP server with NotificationManager for display

## 2. Claude Code Hook Manager

- [x] 2.1 Create ClaudeCodeHookManager.swift
- [x] 2.2 Implement isClaudeCodeInstalled() detection method
- [x] 2.3 Implement isHookInstalled(hookId) detection method
- [x] 2.4 Implement installHook() with idempotent behavior
- [x] 2.5 Implement uninstallHook() to remove by ID prefix
- [x] 2.6 Implement getSettingsPath() and load/save methods

## 3. App Integration

- [x] 3.1 Register HTTP server in AlertoApp.swift on launch
- [x] 3.2 Add hook configuration to AppDelegate
- [x] 3.3 Add port storage in AppStorage

## 4. Settings UI

- [x] 4.1 Add Claude Code hook toggle in SettingsView
- [x] 4.2 Display hook installation status
- [x] 4.3 Show current port configuration
- [x] 4.4 Add manual install/remove buttons

## 5. Notification Types

- [x] 5.1 Add "start" and "stop" notification types to NotificationType enum
- [x] 5.2 Add corresponding icons and colors for new types

## 6. Testing

- [x] 6.1 Test HTTP server receives and processes notifications
- [x] 6.2 Test hook installation idempotency
- [x] 6.3 Test hook uninstallation preserves other hooks
- [x] 6.4 Test overlay displays correctly for each notification type
