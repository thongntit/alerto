import SwiftUI
import AppKit

struct LogViewerView: View {
    @ObservedObject private var logger = AppLogger.shared
    @State private var filterLevel: LogLevel? = nil

    private var filteredEntries: [LogEntry] {
        let reversed = logger.entries.reversed() as [LogEntry]
        guard let filter = filterLevel else { return reversed }
        return reversed.filter { $0.level >= filter }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top controls
            HStack(spacing: 12) {
                Picker("Filter", selection: $filterLevel) {
                    Text("All").tag(Optional<LogLevel>.none)
                    Text("Info+").tag(Optional<LogLevel>.some(.info))
                    Text("Warning+").tag(Optional<LogLevel>.some(.warning))
                    Text("Error").tag(Optional<LogLevel>.some(.error))
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 300)

                Spacer()

                Button("Copy All") {
                    copyAll()
                }

                Button("Clear") {
                    logger.entries.removeAll()
                    logger.clearPersistedFile()
                }
                .foregroundColor(.red)
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)

            // Min level + entry count row
            HStack {
                Text("Minimum level:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Picker("", selection: Binding(
                    get: { logger.minimumLevel },
                    set: { logger.setMinimumLevel($0) }
                )) {
                    ForEach(LogLevel.allCases, id: \.self) { level in
                        Text(level.displayName).tag(level)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 100)

                Spacer()

                Text("\(filteredEntries.count) entries")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            Divider()

            if filteredEntries.isEmpty {
                Spacer()
                Text("No log entries")
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                ScrollViewReader { proxy in
                    List(filteredEntries) { entry in
                        LogEntryRow(entry: entry)
                            .id(entry.id)
                    }
                    .listStyle(.plain)
                    .onChange(of: logger.entries.count) { _, _ in
                        if let first = filteredEntries.first {
                            proxy.scrollTo(first.id, anchor: .top)
                        }
                    }
                }
            }
        }
    }

    private func copyAll() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        let text = filteredEntries.map { entry in
            "[\(formatter.string(from: entry.timestamp))] [\(entry.level.rawValue.uppercased())] [\(entry.category.rawValue)] \(entry.message)"
        }.joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}

// MARK: - LogEntryRow

struct LogEntryRow: View {
    let entry: LogEntry

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f
    }()

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(Self.timeFormatter.string(from: entry.timestamp))
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 90, alignment: .leading)

            Text(entry.level.rawValue.uppercased())
                .font(.system(.caption2, design: .monospaced))
                .fontWeight(.semibold)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(levelColor.opacity(0.2))
                .foregroundColor(levelColor)
                .cornerRadius(3)
                .frame(width: 60, alignment: .center)

            Text(entry.category.rawValue)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 72, alignment: .leading)

            Text(entry.message)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(3)
        }
        .padding(.vertical, 2)
    }

    private var levelColor: Color {
        switch entry.level {
        case .debug: return .secondary
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        }
    }
}
