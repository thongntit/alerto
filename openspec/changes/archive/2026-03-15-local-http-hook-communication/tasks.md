## 1. Dependencies and Project Setup

- [x] 1.1 Add Hummingbird package dependency to Package.swift or Xcode project
- [x] 1.2 Create new Services/HTTPServerService.swift file

## 2. HTTP Server Core Implementation

- [x] 2.1 Implement HTTPServerService class with Hummingbird server initialization
- [x] 2.2 Implement server start/stop methods with localhost binding (127.0.0.1)
- [x] 2.3 Add port configuration property with default value 7531
- [x] 2.4 Implement graceful shutdown with 5-second timeout

## 3. Notification Endpoint

- [x] 3.1 Implement POST /notify endpoint handler
- [x] 3.2 Add JSON body parsing for notification parameters (source, type, message)
- [x] 3.3 Add query parameter parsing as alternative to JSON body
- [x] 3.4 Implement GET /notify endpoint with query parameter support
- [x] 3.5 Add request validation for required parameters (source, type, message)
- [x] 3.6 Add validation for valid source values (claude, opencode, cursor, windsurf, other)
- [x] 3.7 Add validation for valid type values (attention, idle, complete, question, error)
- [x] 3.8 Integrate with NotificationManager to display notifications
- [x] 3.9 Return success/error JSON responses

## 4. Health Check Endpoint

- [x] 4.1 Implement GET /health endpoint handler
- [x] 4.2 Return JSON response with status and uptime

## 5. Port Configuration UI

- [x] 5.1 Add httpPort property to UserDefaults/AppStorage
- [x] 5.2 Add port number input field to SettingsView
- [x] 5.3 Add port validation (1-65535 range)
- [x] 5.4 Implement server restart when port changes

## 6. Server Status and Control UI

- [x] 6.1 Add server status indicator to MenuBarView (Running/Stopped/Error)
- [x] 6.2 Display current port in menu bar when server is running
- [x] 6.3 Add "Start HTTP Server" button when server is stopped
- [x] 6.4 Add "Stop HTTP Server" button when server is running
- [x] 6.5 Add error message display when port conflict occurs

## 7. Server Lifecycle Management

- [x] 7.1 Start HTTP server automatically in AppDelegate.applicationDidFinishLaunching
- [x] 7.2 Implement graceful server shutdown in AppDelegate.applicationWillTerminate
- [x] 7.3 Create HTTPServerManager singleton to manage server state
- [x] 7.4 Add server status tracking (running/stopped/error)

## 8. Updated Integration Instructions

- [x] 8.1 Update Claude Code hook configuration in SettingsView to use curl command
- [x] 8.2 Update OpenCode plugin configuration in SettingsView to use HTTP fetch
- [x] 8.3 Make port number dynamic in integration instructions (use configured port)
- [x] 8.4 Add note about HTTP server requirement in settings

## 9. Error Handling

- [x] 9.1 Handle port already in use error with user-friendly message
- [x] 9.2 Add retry logic or user notification for server start failures
- [x] 9.3 Log server errors for debugging

## 10. Testing and Verification

- [x] 10.1 Test POST /notify with JSON body
- [x] 10.2 Test POST /notify with query parameters
- [x] 10.3 Test GET /notify with query parameters
- [x] 10.4 Test /health endpoint
- [x] 10.5 Test invalid parameter handling (400 responses)
- [x] 10.6 Test port conflict detection
- [x] 10.7 Test server start/stop from UI
- [x] 10.8 Test server restart on port change
- [x] 10.9 Test graceful shutdown on app quit
- [x] 10.10 Verify localhost-only binding (no network exposure)
