import AppKit
import SwiftUI

final class UsageHistoryWindowManager {
    static let shared = UsageHistoryWindowManager()

    private var historyWindow: NSWindow?

    private init() {}

    func showHistory() {
        if let existingWindow = historyWindow {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let historyView = UsageHistoryView(usageManager: UsageManager.shared)
            .frame(width: 700, height: 520)
        let hostingController = NSHostingController(rootView: AnyView(historyView))

        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 900, height: 700)
        let windowWidth: CGFloat = 700
        let windowHeight: CGFloat = 520
        let xPos = screenFrame.origin.x + (screenFrame.width - windowWidth) / 2
        let yPos = screenFrame.origin.y + (screenFrame.height - windowHeight) / 2

        let window = NSWindow(
            contentRect: NSRect(x: xPos, y: yPos, width: windowWidth, height: windowHeight),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.contentViewController = hostingController
        window.title = "Alerto Usage History"
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.hidesOnDeactivate = false

        historyWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
