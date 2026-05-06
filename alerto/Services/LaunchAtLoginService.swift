import Foundation
import ServiceManagement
import Combine
import Logging

@MainActor
class LaunchAtLoginService: ObservableObject {
    static let shared = LaunchAtLoginService()

    @Published private(set) var status: SMAppService.Status

    private let logger = Logger(label: "com.alerto.launch-at-login")

    private init() {
        self.status = SMAppService.mainApp.status
        logger.debug("Launch at login status initialized: \(String(describing: self.status))")
    }

    /// Registers the app as a login item.
    func register() {
        do {
            try SMAppService.mainApp.register()
            refreshStatus()
            logger.info("Launch at login registered successfully")
        } catch {
            logger.error("Failed to register launch at login: \(error.localizedDescription)")
        }
    }

    /// Unregisters the app as a login item.
    func unregister() {
        do {
            try SMAppService.mainApp.unregister()
            refreshStatus()
            logger.info("Launch at login unregistered successfully")
        } catch {
            logger.error("Failed to unregister launch at login: \(error.localizedDescription)")
        }
    }

    /// Refreshes the current status from the system.
    func refreshStatus() {
        status = SMAppService.mainApp.status
        logger.debug("Launch at login status refreshed: \(String(describing: status))")
    }

    /// Whether the login item is currently enabled (either .enabled or .requiresApproval).
    var isEnabled: Bool {
        switch status {
        case .enabled:
            return true
        case .notRegistered:
            return false
        case .requiresApproval:
            return true
        @unknown default:
            return false
        }
    }
}
