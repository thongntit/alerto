import Foundation
import Combine
import UserNotifications
import AppKit

@MainActor
final class SystemNotificationService: NSObject, ObservableObject {
    static let shared = SystemNotificationService()

    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private override init() {
        super.init()
    }

    /// Wires the delegate and seeds the cached authorization status.
    func registerDelegate() {
        UNUserNotificationCenter.current().delegate = self
        refreshAuthorizationStatus()
    }

    func refreshAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                SystemNotificationService.shared.authorizationStatus = settings.authorizationStatus
            }
        }
    }

    /// Triggers the system prompt only when status is undetermined. No-op otherwise.
    func requestAuthorizationIfNeeded() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                SystemNotificationService.shared.authorizationStatus = settings.authorizationStatus
            }
            guard settings.authorizationStatus == .notDetermined else { return }
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
                Task { @MainActor in
                    SystemNotificationService.shared.refreshAuthorizationStatus()
                    if let error = error {
                        AppLogger.shared.error("System notification authorization error: \(error.localizedDescription)", category: .notification)
                    } else {
                        AppLogger.shared.info("System notification authorization granted=\(granted)", category: .notification)
                    }
                }
            }
        }
    }

    /// Posts a notification through UNUserNotificationCenter. Sound is delegated to
    /// UNNotificationSound so macOS Focus / DND can suppress it correctly.
    func post(_ notification: AgenticNotification, playSound: Bool, soundName: String) {
        requestAuthorizationIfNeeded()

        let parts = notification.displayContent
        let content = UNMutableNotificationContent()
        content.title = parts.title
        if let subtitle = parts.subtitle {
            content.subtitle = subtitle
        }
        content.body = parts.body
        content.sound = playSound ? UNNotificationSound(named: UNNotificationSoundName(soundName)) : nil
        content.userInfo = ["alertoNotificationID": notification.id.uuidString]

        let request = UNNotificationRequest(
            identifier: notification.id.uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            Task { @MainActor in
                if let error = error {
                    AppLogger.shared.error("System notification post failed: \(error.localizedDescription)", category: .notification)
                } else {
                    AppLogger.shared.info("System notification posted", category: .display)
                }
            }
        }
    }
}

extension SystemNotificationService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification,
                                            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            didReceive response: UNNotificationResponse,
                                            withCompletionHandler completionHandler: @escaping () -> Void) {
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
        }
        completionHandler()
    }
}
