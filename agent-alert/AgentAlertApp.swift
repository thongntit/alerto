import SwiftUI
import Combine
import Sparkle

@main
struct AgentAlertApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var notificationManager = NotificationManager.shared

    var body: some Scene {
        MenuBarExtra("AgentAlert", systemImage: notificationManager.menubarIcon) {
            MenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
}

// MARK: - Updater Delegate

class UpdaterDelegate: NSObject, SPUUpdaterDelegate {
    func updater(_ updater: SPUUpdater, didFinishInitializationSuccessfully successfully: Bool) {
        print("[UpdaterDelegate] didFinishInitializationSuccessfully: \(successfully)")
    }

    func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        print("[UpdaterDelegate] didNotFindUpdate")
    }

    func updater(_ updater: SPUUpdater, didFindValidUpdate newVersion: String) {
        print("[UpdaterDelegate] didFindValidUpdate: \(newVersion)")
    }

    func updater(_ updater: SPUUpdater, failedToFetchUpdateDataWithError error: Error) {
        print("[UpdaterDelegate] failedToFetchUpdateDataWithError: \(error)")
    }

    func updater(_ updater: SPUUpdater, willInstallUpdateWithVersion version: String) {
        print("[UpdaterDelegate] willInstallUpdate: \(version)")
    }
}

// MARK: - Updater Manager (Singleton)

@MainActor
class UpdaterManager: ObservableObject {
    static let shared = UpdaterManager()

    @Published private(set) var updaterController: SPUStandardUpdaterController?
    private let delegate = UpdaterDelegate()

    private init() {
        initialize()
    }

    private func initialize() {
        print("[UpdaterManager] Initializing...")

        // Log bundle info for debugging
        print("[UpdaterManager] Bundle ID: \(Bundle.main.bundleIdentifier ?? "nil")")
        print("[UpdaterManager] SUFeedURL: \(Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") ?? "nil")")
        print("[UpdaterManager] SUPublicEDKey: set = \(Bundle.main.object(forInfoDictionaryKey: "SUPublicEDKey") != nil)")

        do {
            print("[UpdaterManager] Creating SPUStandardUpdaterController...")
            let controller = try SPUStandardUpdaterController(
                startingUpdater: false,
                updaterDelegate: delegate,
                userDriverDelegate: nil
            )
            print("[UpdaterManager] SPUStandardUpdaterController created OK")

            print("[UpdaterManager] Starting updater...")
            try controller.updater.start()
            print("[UpdaterManager] updater.start() succeeded")
            self.updaterController = controller
        } catch {
            print("[UpdaterManager] Updater FAILED: \(error)")
            self.updaterController = nil
        }
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    @MainActor var updaterManager: UpdaterManager { UpdaterManager.shared }

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("[AppDelegate] applicationDidFinishLaunching")
        URLSchemeHandler.shared.registerHandler()
        NotificationOverlayManager.shared.setup()

        // Trigger initialization by accessing the singleton
        _ = updaterManager.updaterController
        print("[AppDelegate] UpdaterManager shared initialized")

        Task {
            await HTTPServerManager.shared.start()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        Task {
            await HTTPServerManager.shared.stop()
        }
    }
}
