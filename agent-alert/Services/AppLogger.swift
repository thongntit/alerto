import Foundation
import SwiftUI
import Combine

// MARK: - LogLevel

enum LogLevel: String, CaseIterable, Comparable, Codable {
    case debug
    case info
    case warning
    case error

    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }

    private var sortOrder: Int {
        switch self {
        case .debug: return 0
        case .info: return 1
        case .warning: return 2
        case .error: return 3
        }
    }

    var displayName: String { rawValue.capitalized }
}

// MARK: - LogCategory

enum LogCategory: String, CaseIterable, Comparable, Codable {
    case http
    case notification
    case display
    case system

    static func < (lhs: LogCategory, rhs: LogCategory) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var displayName: String { rawValue.capitalized }
}

// MARK: - LogEntry

struct LogEntry: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let level: LogLevel
    let category: LogCategory
    let message: String

    init(level: LogLevel, category: LogCategory, message: String) {
        self.id = UUID()
        self.timestamp = Date()
        self.level = level
        self.category = category
        self.message = message.count > 256 ? String(message.prefix(256)) : message
    }
}

// MARK: - AppLogger

@MainActor
class AppLogger: ObservableObject {
    static let shared = AppLogger()

    @Published var entries: [LogEntry] = []
    @Published var minimumLevel: LogLevel

    private let capacity = 500
    private var debounceTask: Task<Void, Never>?

    private static var logFileURL: URL? {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        return appSupport.appendingPathComponent("AgentAlert/app.log.json")
    }

    private init() {
        let savedLevel = UserDefaults.standard.string(forKey: "logMinLevel").flatMap(LogLevel.init)
        #if DEBUG
        self.minimumLevel = savedLevel ?? .debug
        #else
        self.minimumLevel = savedLevel ?? .info
        #endif
        loadFromDisk()
    }

    // MARK: - Logging

    func log(level: LogLevel, category: LogCategory, message: String) {
        guard level >= minimumLevel else { return }
        let entry = LogEntry(level: level, category: category, message: message)
        if entries.count >= capacity {
            entries.removeFirst()
        }
        entries.append(entry)
        schedulePersist()
    }

    func debug(_ message: String, category: LogCategory = .system) {
        log(level: .debug, category: category, message: message)
    }

    func info(_ message: String, category: LogCategory = .system) {
        log(level: .info, category: category, message: message)
    }

    func warning(_ message: String, category: LogCategory = .system) {
        log(level: .warning, category: category, message: message)
    }

    func error(_ message: String, category: LogCategory = .system) {
        log(level: .error, category: category, message: message)
    }

    // MARK: - Minimum Level Persistence

    func setMinimumLevel(_ level: LogLevel) {
        minimumLevel = level
        UserDefaults.standard.set(level.rawValue, forKey: "logMinLevel")
    }

    // MARK: - Persistence

    private func schedulePersist() {
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard !Task.isCancelled else { return }
            self?.persistToDisk()
        }
    }

    func persistToDisk() {
        let snapshot = entries
        guard let url = Self.logFileURL else { return }
        Task.detached(priority: .background) {
            do {
                let dir = url.deletingLastPathComponent()
                try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
                let data = try JSONEncoder().encode(snapshot)
                try data.write(to: url, options: .atomic)
            } catch {
                // Silent failure — logging must not disrupt the main app
            }
        }
    }

    func loadFromDisk() {
        guard let url = Self.logFileURL,
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([LogEntry].self, from: data) else {
            return
        }
        entries = Array(decoded.suffix(capacity))
    }

    func clearPersistedFile() {
        guard let url = Self.logFileURL else { return }
        try? FileManager.default.removeItem(at: url)
    }
}
