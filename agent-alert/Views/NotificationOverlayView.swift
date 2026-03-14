import SwiftUI

struct NotificationOverlayView: View {
    var notification: AgenticNotification?
    @State private var isAnimating = false
    
    var body: some View {
        if let notification = notification {
            HStack(spacing: 16) {
                Image(systemName: notification.source.icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(notification.source.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(notification.message)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(2)
                }
                
                Spacer(minLength: 8)
                
                Image(systemName: notification.type.icon)
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                    .scaleEffect(isAnimating ? 1.15 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: notification.type.color),
                                Color(hex: notification.type.color).opacity(0.85)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: Color.black.opacity(0.25), radius: 16, x: 0, y: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .padding(8)
            .onAppear {
                isAnimating = true
            }
        }
    }
}
