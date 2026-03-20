import SwiftUI
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

class AppDelegate: NSObject, NSApplicationDelegate {
    let updaterController: SPUStandardUpdaterController

    override init() {
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        URLSchemeHandler.shared.registerHandler()
        NotificationOverlayManager.shared.setup()

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
