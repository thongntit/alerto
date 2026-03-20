import Foundation
import Combine
import SwiftUI
import AppKit

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    private static let maxNotificationHistory = 100

    @Published var notifications: [AgenticNotification] = []
    @Published var showOverlay = false
    @Published var currentNotification: AgenticNotification?

    @AppStorage("playSound") private var playSound = true
    @AppStorage("selectedSound") private var selectedSound = "Glass"
    @AppStorage("showOverlay") private var showOverlaySetting = true
    @AppStorage("overlayDuration") private var overlayDuration = 3.0

    private var overlayTimer: Timer?

    private init() {}
    
    func handleNotification(source: NotificationSource, type: NotificationType, message: String, hookType: HookType? = nil, rawMessage: String? = nil) {
        let notification = AgenticNotification(source: source, type: type, message: message, hookType: hookType, rawMessage: rawMessage)
        AppLogger.shared.info("Received: source=\(source.rawValue), type=\(type.rawValue), message=\(String(message.prefix(256)))", category: .notification)

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.showNotification(notification)
        }
    }
    
    private func showNotification(_ notification: AgenticNotification) {
        currentNotification = notification

        if playSound {
            NSSound(named: NSSound.Name(selectedSound))?.play()
            AppLogger.shared.info("Sound played: \(selectedSound)", category: .display)
        } else {
            AppLogger.shared.debug("Sound skipped (setting disabled)", category: .display)
        }

        if showOverlaySetting {
            AppLogger.shared.info("Overlay shown", category: .display)
            showOverlay = true
            overlayTimer?.invalidate()
            overlayTimer = Timer.scheduledTimer(withTimeInterval: overlayDuration, repeats: false) { [weak self] _ in
                self?.dismissOverlay()
            }
            NotificationOverlayManager.shared.show(notification: notification, duration: overlayDuration)
        } else {
            AppLogger.shared.info("Overlay skipped (setting disabled)", category: .display)
            // If overlay is disabled, just add to history immediately
            dismissOverlay()
        }
    }
    
    func dismissOverlay() {
        showOverlay = false
        if let notification = currentNotification {
            notifications.insert(notification, at: 0)
            // Enforce max history limit
            if notifications.count > Self.maxNotificationHistory {
                notifications = Array(notifications.prefix(Self.maxNotificationHistory))
            }
            AppLogger.shared.info("Notification added to history", category: .notification)
        }
        currentNotification = nil
    }
    
    func clearAll() {
        notifications.removeAll()
    }
    
    func markAsRead(_ notification: AgenticNotification) {
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index].isRead = true
        }
    }
    
    var menubarIcon: String {
        let hasUnread = !notifications.filter { !$0.isRead }.isEmpty || currentNotification != nil
        return hasUnread ? "bell.badge.fill" : "bell.fill"
    }
    
    func markAllAsRead() {
        for i in 0..<notifications.count {
            notifications[i].isRead = true
        }
    }
}
