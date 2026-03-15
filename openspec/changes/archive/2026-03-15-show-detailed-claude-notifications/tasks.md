## 1. Update HTTP Server to Parse Hook Payloads

- [x] 1.1 Add HookPayload struct to handle JSON payload from Claude Code hooks
- [x] 1.2 Update handleNotify to extract message from payload fields
- [x] 1.3 Add backward compatibility for old format (source/type/message)
- [x] 1.4 Add hook event type detection from payload

## 2. Update Claude Code Hook Manager

- [x] 2.1 Modify hook commands to pipe stdin content to HTTP endpoint
- [x] 2.2 Use curl's -d @- to read from stdin with hook payload
- [x] 2.3 Update hook configuration to pass structured data

## 3. Update Notification Model

- [x] 3.1 Add hookType field to track which hook triggered notification
- [x] 3.2 Add message content field to AgenticNotification
- [x] 3.3 Update NotificationType to include hook-specific types

## 4. Update Notification Display

- [x] 4.1 Modify NotificationOverlayView to display message content
- [x] 4.2 Add message truncation at 200 characters
- [x] 4.3 Show full message in overlay detail view

## 5. Testing

- [x] 5.1 Test with Notification hook payload
- [x] 5.2 Test backward compatibility with old format
- [x] 5.3 Verify message truncation behavior
