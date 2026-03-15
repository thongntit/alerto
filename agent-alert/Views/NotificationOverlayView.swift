import SwiftUI

struct NotificationOverlayView: View {
    var notification: AgenticNotification?
    @State private var isAnimating = false

    var body: some View {
        if let notification = notification {
            HStack(spacing: 16) {
                iconView(for: notification)
                    .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 4) {
                    // Show hook type context if available
                    if let hookType = notification.hookType, hookType != .unknown {
                        Text(hookContextTitle(for: hookType))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    Text(notification.source.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)

                    // Show truncated message content
                    Text(notification.truncatedMessage)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(3)
                }

                Spacer(minLength: 8)

                Image(systemName: notification.type.icon)
                    .font(.system(size: 22))
                    .foregroundStyle(.white)
                    .scaleEffect(isAnimating ? 1.15 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
            .padding(16)
            .notificationBackground(for: notification)
            .padding(8)
            .onAppear {
                isAnimating = true
            }
        }
    }

    @ViewBuilder
    private func iconView(for notification: AgenticNotification) -> some View {
        if #available(macOS 26.0, *) {
            Image(systemName: notification.source.icon)
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .glassEffect(.regular, in: .capsule)
        } else {
            Image(systemName: notification.source.icon)
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(
                    Capsule()
                        .fill(Color(hex: notification.type.color).opacity(0.3))
                )
        }
    }

    /// Returns a human-readable context title based on the hook type
    private func hookContextTitle(for hookType: HookType) -> String {
        switch hookType {
        case .notification:
            return "Claude needs your input"
        case .stop:
            return "Claude finished responding"
        case .subagentStop:
            return "Subagent completed"
        case .sessionEnd:
            return "Session ended"
        case .userPromptSubmit:
            return "Processing your prompt"
        case .permissionRequest:
            return "Permission requested"
        case .unknown:
            return ""
        }
    }
}

// MARK: - Platform-Specific Background Modifier

struct NotificationBackgroundModifier: ViewModifier {
    let notification: AgenticNotification

    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content
                .glassEffect(
                    .regular.tint(Color(hex: notification.type.color).opacity(0.6)),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
        } else {
            content
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: notification.type.color).opacity(0.25),
                                    Color(hex: notification.type.color).opacity(0.1)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 6)
        }
    }
}

extension View {
    func notificationBackground(for notification: AgenticNotification) -> some View {
        modifier(NotificationBackgroundModifier(notification: notification))
    }
}
