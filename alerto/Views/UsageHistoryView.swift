import Charts
import SwiftUI

struct UsageHistoryView: View {
    @ObservedObject var usageManager: UsageManager
    @AppStorage(UsageHistoryStore.enabledKey) private var historyEnabled = true
    @State private var selectedProvider: UsageProvider = .claude

    private var selectedUsage: ProviderUsage? {
        usageManager.snapshot?.usage(for: selectedProvider)
    }

    private var points: [UsageHistoryPoint] {
        usageManager.history.flatMap { snapshot -> [UsageHistoryPoint] in
            guard let usage = snapshot.usage(for: selectedProvider) else { return [] }
            return usage.limits.map { limit in
                UsageHistoryPoint(
                    date: snapshot.generatedAt,
                    window: limit.label,
                    usedPercent: limit.usedPercent
                )
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header

            if let selectedUsage {
                currentUsageSummary(selectedUsage)
            } else {
                Text("No current usage data for \(selectedProvider.displayName). Refresh from the menu bar to start tracking.")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Usage trend")
                        .font(.headline)
                    Spacer()
                    if let date = usageManager.lastRefreshAt ?? usageManager.history.last?.generatedAt {
                        Text("Updated \(date, style: .relative)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if !historyEnabled {
                    Text("Local usage history is disabled. Enable it in Settings > Integrations to collect future snapshots.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 36)
                } else if points.isEmpty {
                    Text("Usage history will appear after the next successful refresh.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 36)
                } else {
                    Chart(points) { point in
                        LineMark(
                            x: .value("Refresh", point.date),
                            y: .value("Used", point.usedPercent)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(by: .value("Window", point.window))

                        PointMark(
                            x: .value("Refresh", point.date),
                            y: .value("Used", point.usedPercent)
                        )
                        .foregroundStyle(by: .value("Window", point.window))
                    }
                    .chartYScale(domain: 0...100)
                    .chartYAxis {
                        AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let percent = value.as(Int.self) {
                                    Text("\(percent)%")
                                }
                            }
                        }
                    }
                    .chartForegroundStyleScale([
                        "Session": Color.blue,
                        "Weekly": Color.purple
                    ])
                    .chartLegend(position: .top, alignment: .leading)
                    .frame(height: 245)
                }
            }

            HStack {
                Text("Alerto stores only provider-reported percentages and reset times locally. It never stores prompts, responses, or credentials.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button("Clear History", role: .destructive) {
                    usageManager.clearUsageHistory()
                }
                .disabled(usageManager.history.isEmpty)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(NSColor.windowBackgroundColor))
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Picker("Provider", selection: $selectedProvider) {
                    ForEach(UsageProvider.allCases) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Usage History")
                .font(.title2.weight(.semibold))
            Text("Quota utilization over the locally retained refresh history. Exact token counts are not provided by the usage endpoints.")
                .font(.callout)
                .foregroundColor(.secondary)
        }
    }

    private func currentUsageSummary(_ usage: ProviderUsage) -> some View {
        HStack(spacing: 12) {
            ForEach(usage.limits) { limit in
                VStack(alignment: .leading, spacing: 4) {
                    Text(limit.label)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(limit.formattedUsed)
                        .font(.title3.weight(.semibold))
                    Text(limit.formattedRemaining)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let resetsAt = limit.resetsAt {
                        Text("Resets \(resetsAt, style: .relative)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
            }
        }
    }
}

private struct UsageHistoryPoint: Identifiable {
    let date: Date
    let window: String
    let usedPercent: Double

    var id: String {
        "\(date.timeIntervalSince1970)-\(window)"
    }
}
