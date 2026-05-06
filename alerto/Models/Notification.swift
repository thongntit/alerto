import Foundation

enum NotificationSource: String, Codable, CaseIterable {
    case claude = "claude"
    case opencode = "opencode"
    case cursor = "cursor"
    case windsurf = "windsurf"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .claude: return "Claude Code"
        case .opencode: return "OpenCode"
        case .cursor: return "Cursor"
        case .windsurf: return "Windsurf"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .claude: return "brain.head.profile"
        case .opencode: return "chevron.left.forwardslash.chevron.right"
        case .cursor: return "cursorarrow"
        case .windsurf: return "wind"
        case .other: return "app.fill"
        }
    }
}

enum NotificationType: String, Codable, CaseIterable {
    case complete = "complete"
    case permission = "permission"
    case question = "question"
    case idle = "idle"
    case attention = "attention"
    case error = "error"
    case start = "start"
    case stop = "stop"

    var color: String {
        switch self {
        case .complete: return "#4ECDC4"
        case .permission: return "#FFE66D"
        case .question: return "#95E1D3"
        case .idle: return "#F38181"
        case .attention: return "#FF6B6B"
        case .error: return "#E74C3C"
        case .start: return "#3498DB"
        case .stop: return "#95A5A6"
        }
    }

    var icon: String {
        switch self {
        case .complete: return "checkmark.circle.fill"
        case .permission: return "lock.shield.fill"
        case .question: return "questionmark.circle.fill"
        case .idle: return "clock.fill"
        case .attention: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        case .start: return "play.circle.fill"
        case .stop: return "stop.circle.fill"
        }
    }
}

/// Represents which Claude Code hook triggered the notification
enum HookType: String, Codable {
    case notification = "Notification"
    case stop = "Stop"
    case subagentStop = "SubagentStop"
    case sessionEnd = "SessionEnd"
    case userPromptSubmit = "UserPromptSubmit"
    case permissionRequest = "PermissionRequest"
    case unknown = "unknown"
}

struct AgenticNotification: Identifiable, Codable {
    var id = UUID()
    let source: NotificationSource
    let type: NotificationType
    let message: String
    let timestamp: Date
    var isRead: Bool = false

    // New fields for detailed hook information
    let hookType: HookType?
    let rawMessage: String?

    init(source: NotificationSource, type: NotificationType, message: String, hookType: HookType? = nil, rawMessage: String? = nil) {
        self.source = source
        self.type = type
        self.message = message
        self.timestamp = Date()
        self.isRead = false
        self.hookType = hookType
        self.rawMessage = rawMessage
    }

    /// Returns a truncated version of the message for display in notifications
    var truncatedMessage: String {
        let maxLength = 200
        if message.count > maxLength {
            return String(message.prefix(maxLength)) + "..."
        }
        return message
    }
}
