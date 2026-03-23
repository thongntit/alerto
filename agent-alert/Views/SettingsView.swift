import SwiftUI
import Sparkle

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
            
            HTTPSettingsView()
                .tabItem {
                    Label("HTTP Server", systemImage: "network")
                }
            
            IntegrationsSettingsView()
                .tabItem {
                    Label("Integrations", systemImage: "link")
                }
            
            LogViewerView()
                .tabItem {
                    Label("Logs", systemImage: "doc.text.magnifyingglass")
                }

            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
    }
}

struct GeneralSettingsView: View {
    @AppStorage("showOverlay") private var showOverlay = true
    @AppStorage("overlayDuration") private var overlayDuration = 3.0
    @AppStorage("playSound") private var playSound = true
    @AppStorage("selectedSound") private var selectedSound = "Glass"
    
    let availableSounds = ["Glass", "Ping", "Pop", "Purr", "Blow", "Hero", "Submarine"]
    
    var body: some View {
        Form {
            Section("Notifications") {
                Toggle("Show overlay notification", isOn: $showOverlay)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Overlay duration")
                        Spacer()
                        Text("\(Int(overlayDuration))s")
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $overlayDuration, in: 1...10, step: 1)
                }
            }
            
            Section("Sound") {
                Toggle("Play sound", isOn: $playSound)
                
                if playSound {
                    Picker("Notification sound", selection: $selectedSound) {
                        ForEach(availableSounds, id: \.self) { sound in
                            Text(sound).tag(sound)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    HStack {
                        Spacer()
                        Button("Preview Sound") {
                            NSSound(named: NSSound.Name(selectedSound))?.play()
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct HTTPSettingsView: View {
    @StateObject private var serverManager = HTTPServerManager.shared
    @State private var portString: String = ""
    @State private var showPortError = false
    
    var body: some View {
        Form {
            Section("Server Status") {
                HStack {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 10, height: 10)
                    
                    Text(serverManager.status.displayText)
                    
                    Spacer()
                    
                    Button(serverManager.status == .stopped ? "Start" : "Stop") {
                        Task {
                            if serverManager.status == .stopped {
                                await serverManager.start()
                            } else {
                                await serverManager.stop()
                            }
                        }
                    }
                }
            }
            
            Section("Configuration") {
                HStack {
                    Text("Port")
                    Spacer()
                    TextField("Port", text: $portString)
                        .frame(width: 80)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: portString) { _, newValue in
                            if let port = Int(newValue), port >= 1 && port <= 65535 {
                                showPortError = false
                                Task {
                                    await serverManager.updatePort(port)
                                }
                            } else if !newValue.isEmpty {
                                showPortError = true
                            }
                        }
                }
                
                if showPortError {
                    Text("Port must be between 1 and 65535")
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                if case .error(let message) = serverManager.status {
                    Text(message)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            Section {
                Text("The HTTP server allows external tools to send notifications via HTTP requests instead of URL schemes. This prevents the app from being re-launched on each notification.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            portString = String(serverManager.port)
        }
    }
    
    private var statusColor: Color {
        switch serverManager.status {
        case .running:
            return .green
        case .stopped:
            return .gray
        case .error:
            return .red
        }
    }
}

struct IntegrationsSettingsView: View {
    @StateObject private var serverManager = HTTPServerManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Integrations")
                .font(.title2)
                .fontWeight(.semibold)

            ClaudeCodeIntegrationView(port: serverManager.port)

            Spacer()
        }
        .padding()
    }
}

struct ClaudeCodeIntegrationView: View {
    let port: Int

    @StateObject private var hookManager = ClaudeCodeHookManager.shared
    @State private var isInstalling = false
    @State private var installError: String?
    @State private var showSuccessMessage = false

    // Individual hook states
    @State private var hookStopEnabled = false
    @State private var hookNotificationEnabled = false
    @State private var hookSessionEndEnabled = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Status Section
            Section {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.title2)
                        .foregroundColor(.blue)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Claude Code")
                            .font(.headline)

                        Text(hookStatusText)
                            .font(.caption)
                            .foregroundColor(hookStatusColor)
                    }

                    Spacer()

                    if isInstalling {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }

            Divider()

            // Port Configuration
            Section("Server") {
                HStack {
                    Text("Port")
                    Spacer()
                    Text("\(port)")
                        .foregroundColor(.secondary)
                }
            }

            // Hook Events Section
            Section("Hooks") {
                Toggle("Stop - When main agent finishes", isOn: $hookStopEnabled)
                    .onChange(of: hookStopEnabled) { _, newValue in
                        toggleHook("stop", enabled: newValue)
                    }

                Toggle("Notification - When Claude needs attention", isOn: $hookNotificationEnabled)
                    .onChange(of: hookNotificationEnabled) { _, newValue in
                        toggleHook("notification", enabled: newValue)
                    }

                Toggle("SessionEnd - When session ends", isOn: $hookSessionEndEnabled)
                    .onChange(of: hookSessionEndEnabled) { _, newValue in
                        toggleHook("session-end", enabled: newValue)
                    }
            }
            .onAppear {
                refreshHookStates()
            }

            // Actions Section
            Section {
                HStack {
                    Button("Install All") {
                        installAllHooks()
                    }
                    .disabled(isInstalling || allHooksEnabled)

                    Button("Remove All") {
                        removeAllHooks()
                    }
                    .disabled(isInstalling || !anyHookEnabled)
                    .foregroundColor(.red)
                }

                if let error = installError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                if showSuccessMessage {
                    Text("Hooks updated successfully!")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }

            // Info Section
            Section {
                Text("Check individual hooks to enable/disable them. Use Install All/Remove All for bulk operations.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var hookStatusText: String {
        if !hookManager.isClaudeCodeInstalled() {
            return "Claude Code not detected"
        }
        if hookManager.isAnyHookInstalled() {
            let count = [hookStopEnabled, hookNotificationEnabled, hookSessionEndEnabled].filter { $0 }.count
            return "\(count) hook(s) enabled"
        }
        return "No hooks installed"
    }

    private var hookStatusColor: Color {
        if !hookManager.isClaudeCodeInstalled() {
            return .orange
        }
        if hookManager.isAnyHookInstalled() {
            return .green
        }
        return .secondary
    }

    private var allHooksEnabled: Bool {
        hookStopEnabled && hookNotificationEnabled && hookSessionEndEnabled
    }

    private var anyHookEnabled: Bool {
        hookStopEnabled || hookNotificationEnabled || hookSessionEndEnabled
    }

    private func refreshHookStates() {
        hookStopEnabled = hookManager.isHookInstalled(hookId: "agent-alert:stop")
        hookNotificationEnabled = hookManager.isHookInstalled(hookId: "agent-alert:notification")
        hookSessionEndEnabled = hookManager.isHookInstalled(hookId: "agent-alert:session-end")
    }

    private func toggleHook(_ hookName: String, enabled: Bool) {
        isInstalling = true
        installError = nil
        showSuccessMessage = false

        do {
            if enabled {
                try hookManager.installHook(name: hookName, port: port)
            } else {
                try hookManager.uninstallHook(name: hookName)
            }
            showSuccessMessage = true
        } catch {
            installError = "Failed to \(enabled ? "install" : "remove"): \(error.localizedDescription)"
            // Revert state on error
            refreshHookStates()
        }

        isInstalling = false
    }

    private func installAllHooks() {
        isInstalling = true
        installError = nil
        showSuccessMessage = false

        do {
            try hookManager.installHooks(port: port)
            refreshHookStates()
            showSuccessMessage = true
        } catch {
            installError = "Failed to install: \(error.localizedDescription)"
        }

        isInstalling = false
    }

    private func removeAllHooks() {
        isInstalling = true
        installError = nil
        showSuccessMessage = false

        do {
            try hookManager.uninstallHooks()
            refreshHookStates()
            showSuccessMessage = true
        } catch {
            installError = "Failed to remove: \(error.localizedDescription)"
        }

        isInstalling = false
    }
}

struct OpenCodeIntegrationView: View {
    let port: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("OpenCode integration is no longer supported.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct CodeBlockView: View {
    let code: String
    @State private var codeText: String = ""
    
    var body: some View {
        TextEditor(text: $codeText)
            .font(.system(.caption, design: .monospaced))
            .padding(4)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(6)
            .frame(height: 150)
            .onAppear {
                codeText = code
            }
    }
}

struct AboutView: View {
    @ObservedObject var notificationManager = NotificationManager.shared
    @AppStorage("SUEnableAutomaticChecks") private var automaticallyChecksForUpdates = true

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    private var updaterController: SPUStandardUpdaterController? {
        UpdaterManager.shared.updaterController
    }

    var body: some View {
        VStack(spacing: 20) {
            Image("AppIcon")
                .resizable()
                .frame(width: 64, height: 64)
                .cornerRadius(12)

            Text("AgentAlert")
                .font(.title)
                .fontWeight(.bold)

            Text("Version \(appVersion)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("A macOS notification app for Claude Code")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()

            Divider()

            VStack(spacing: 12) {
                Toggle("Automatically check for updates", isOn: $automaticallyChecksForUpdates)
                    .toggleStyle(.switch)

                Button("Check for Updates") {
                    if let uc = updaterController {
                        print("[Updater] Check for Updates clicked — triggering check")
                        uc.checkForUpdates(nil)
                    } else {
                        print("[Updater] Check for Updates clicked but updaterController is nil")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(updaterController?.updater.canCheckForUpdates == false)
            }
            .padding(.horizontal)

            Spacer()

            VStack(spacing: 12) {
                Text("Test Notifications")
                    .font(.headline)

                Button("Test Notification") {
                    notificationManager.handleNotification(
                        source: .claude,
                        type: .complete,
                        message: "Test notification"
                    )
                }
                .buttonStyle(.borderedProminent)

                HStack(spacing: 12) {
                    Button("Mark All Read") {
                        notificationManager.markAllAsRead()
                    }

                    Button("Clear All") {
                        notificationManager.clearAll()
                    }
                    .foregroundColor(.red)
                }
            }
            .padding()
        }
        .padding()
    }
}
