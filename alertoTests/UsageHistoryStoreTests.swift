import XCTest
@testable import Alerto

final class UsageHistoryStoreTests: XCTestCase {
    func testSnapshotsRoundTripAndAreCapped() throws {
        let defaults = try makeDefaults()
        let store = UsageHistoryStore(
            defaults: defaults,
            maxEntries: 2,
            enabledKey: "history-enabled",
            historyKey: "history"
        )

        _ = store.append(snapshot(at: 1_000, used: 10))
        _ = store.append(snapshot(at: 1_300, used: 20))
        let entries = store.append(snapshot(at: 1_600, used: 30))

        XCTAssertEqual(entries.map(\.generatedAt), [
            Date(timeIntervalSince1970: 1_300),
            Date(timeIntervalSince1970: 1_600)
        ])
        XCTAssertEqual(store.load(), entries)
    }

    func testSnapshotWithinOneMinuteReplacesLastEntry() throws {
        let defaults = try makeDefaults()
        let store = UsageHistoryStore(
            defaults: defaults,
            enabledKey: "history-enabled",
            historyKey: "history"
        )

        _ = store.append(snapshot(at: 1_000, used: 10))
        let entries = store.append(snapshot(at: 1_030, used: 40))

        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].generatedAt, Date(timeIntervalSince1970: 1_030))
        XCTAssertEqual(entries[0].usage(for: .claude)?.limits.first?.usedPercent, 40)
    }

    func testDisabledHistoryDoesNotPersist() throws {
        let defaults = try makeDefaults()
        defaults.set(false, forKey: "history-enabled")
        let store = UsageHistoryStore(
            defaults: defaults,
            enabledKey: "history-enabled",
            historyKey: "history"
        )

        XCTAssertTrue(store.append(snapshot(at: 1_000, used: 10)).isEmpty)
        XCTAssertTrue(store.load().isEmpty)
        XCTAssertNil(defaults.data(forKey: "history"))
    }

    private func makeDefaults() throws -> UserDefaults {
        let suiteName = "UsageHistoryStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defaults.set(true, forKey: "history-enabled")
        addTeardownBlock {
            defaults.removePersistentDomain(forName: suiteName)
        }
        return defaults
    }

    private func snapshot(at timestamp: TimeInterval, used: Double) -> UsageSnapshot {
        UsageSnapshot(
            generatedAt: Date(timeIntervalSince1970: timestamp),
            providers: [
                ProviderUsage(
                    provider: .claude,
                    plan: nil,
                    isStale: false,
                    limits: [
                        UsageLimit(
                            label: "Session",
                            remainingPercent: 100 - used,
                            resetsAt: Date(timeIntervalSince1970: timestamp + 1_000)
                        )
                    ]
                )
            ]
        )
    }
}
