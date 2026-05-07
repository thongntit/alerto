import Foundation
import AppKit
import SwiftUI

class SettingsWindowManager {
    static let shared = SettingsWindowManager()

    private var settingsWindow: NSWindow?

    private init() {}

    func showSettings() {
        if let existingWindow = settingsWindow {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        createSettingsWindow()
    }

    private func createSettingsWindow() {
        let settingsView = SettingsView()
            .frame(width: 550, height: 500)

        let hostingController = NSHostingController(rootView: AnyView(settingsView))

        // Calculate centered position
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let windowWidth: CGFloat = 550
        let windowHeight: CGFloat = 500
        let xPos = screenFrame.origin.x + (screenFrame.width - windowWidth) / 2
        let yPos = screenFrame.origin.y + (screenFrame.height - windowHeight) / 2

        let window = NSWindow(
            contentRect: NSRect(x: xPos, y: yPos, width: windowWidth, height: windowHeight),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.contentViewController = hostingController
        window.title = "Alerto Settings"
        window.isReleasedWhenClosed = false

        // Make window float above other windows and stay visible
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.hidesOnDeactivate = false

        self.settingsWindow = window

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func closeSettings() {
        settingsWindow?.close()
    }
}
