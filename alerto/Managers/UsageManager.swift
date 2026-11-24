import Foundation
import Combine

/// Refreshes direct, read-only Claude Code and Codex quota requests on a conservative cadence.
@MainActor
final class UsageManager: ObservableObject {
    static let shared = UsageManager()

    @Published private(set) var snapshot: UsageSnapshot?
    @Published private(set) var history: [UsageSnapshot]
    @Published private(set) var providerErrors: [UsageProvider: String] = [:]
    @Published private(set) var providerErrorKinds: [UsageProvider: UsageFetchError] = [:]
    @Published private(set) var isRefreshing = false
    @Published private(set) var lastRefreshAt: Date?

    private let client: UsageClient
    private let historyStore: UsageHistoryStore
    private var refreshTimer: Timer?
    private var lastAttemptAt: Date?

    init(
        client: UsageClient = UsageClient(),
        historyStore: UsageHistoryStore? = nil
    ) {
        self.client = client
        self.historyStore = historyStore ?? UsageHistoryStore()
        self.history = self.historyStore.load()
        startAutomaticRefresh()
    }

    deinit {
        refreshTimer?.invalidate()
    }

    func clearUsageHistory() {
        historyStore.clear()
        history = []
    }

    /// Automatic refreshes are spaced five minutes apart. Manual refreshes are coalesced for
    /// 30 seconds to avoid accidental API hammering.
    func refresh(manual: Bool = false) async {
        guard !isRefreshing else { return }
        let now = Date()
        let minimumInterval: TimeInterval = manual ? 30 : 5 * 60
        guard lastAttemptAt.map({ now.timeIntervalSince($0) >= minimumInterval }) ?? true else { return }

        isRefreshing = true
        lastAttemptAt = now
        defer { isRefreshing = false }

        // Automatic refreshes stay file-only. A manual refresh may bootstrap the
        // cache from Claude Code's Keychain when the file is missing or stale.
        async let claude = result { try await client.fetchClaude(allowKeychainBootstrap: manual) }
        async let codex = result { try await client.fetchCodex() }

        let results: [(UsageProvider, Result<ProviderUsage, Error>)] = [
            (.claude, await claude),
            (.codex, await codex)
        ]

        var updated = UsageSnapshot(generatedAt: now, providers: snapshot?.providers ?? [])
        var errors: [UsageProvider: String] = [:]
        var errorKinds: [UsageProvider: UsageFetchError] = [:]
        var didReceiveUsage = false
        for (provider, result) in results {
            switch result {
            case .success(let usage):
                didReceiveUsage = true
                updated.replace(usage)
            case .failure(let error):
                updated.markStale(provider)
                errors[provider] = error.localizedDescription
                if let usageError = error as? UsageFetchError {
                    errorKinds[provider] = usageError
                }
            }
        }

        snapshot = updated.providers.isEmpty ? nil : updated
        if didReceiveUsage {
            history = historyStore.append(updated)
        }
        providerErrors = errors
        providerErrorKinds = errorKinds
        lastRefreshAt = Date()
    }

    private func startAutomaticRefresh() {
        Task { [weak self] in
            await self?.refresh()
        }

        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5 * 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refresh()
            }
        }
    }

    private func result<T>(_ operation: () async throws -> T) async -> Result<T, Error> {
        do {
            return .success(try await operation())
        } catch {
            return .failure(error)
        }
    }
}
