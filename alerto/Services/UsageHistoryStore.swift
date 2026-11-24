import Foundation

/// Persists only provider-reported quota metadata for the local usage history view.
/// No credentials, prompts, responses, or request payloads are stored.
struct UsageHistoryStore {
    static let shared = UsageHistoryStore()

    static let enabledKey = "usageHistoryEnabled"
    static let historyKey = "usageHistory.v1"

    private let defaults: UserDefaults
    private let maxEntries: Int
    private let enabledDefaultsKey: String
    private let historyDefaultsKey: String

    init(
        defaults: UserDefaults = .standard,
        maxEntries: Int = 288,
        enabledKey: String = UsageHistoryStore.enabledKey,
        historyKey: String = UsageHistoryStore.historyKey
    ) {
        self.defaults = defaults
        self.maxEntries = max(1, maxEntries)
        self.enabledDefaultsKey = enabledKey
        self.historyDefaultsKey = historyKey
    }

    var isEnabled: Bool {
        defaults.object(forKey: enabledDefaultsKey) as? Bool ?? true
    }

    func load() -> [UsageSnapshot] {
        guard isEnabled,
              let data = defaults.data(forKey: historyDefaultsKey),
              let snapshots = try? JSONDecoder().decode([UsageSnapshot].self, from: data)
        else {
            return []
        }
        return Array(snapshots.suffix(maxEntries))
    }

    @discardableResult
    func append(_ snapshot: UsageSnapshot) -> [UsageSnapshot] {
        guard isEnabled else { return [] }

        var snapshots = load()
        if let lastIndex = snapshots.indices.last,
           abs(snapshots[lastIndex].generatedAt.timeIntervalSince(snapshot.generatedAt)) < 60 {
            snapshots[lastIndex] = snapshot
        } else {
            snapshots.append(snapshot)
        }

        snapshots = Array(snapshots.suffix(maxEntries))
        if let data = try? JSONEncoder().encode(snapshots) {
            defaults.set(data, forKey: historyDefaultsKey)
        }
        return snapshots
    }

    func clear() {
        defaults.removeObject(forKey: historyDefaultsKey)
    }
}
