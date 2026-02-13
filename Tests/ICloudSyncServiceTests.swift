import XCTest
@testable import FlashForge

final class ICloudSyncServiceTests: XCTestCase {
    private var sandboxRootURL: URL!

    override func setUpWithError() throws {
        sandboxRootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("FlashForgeICloudSyncTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: sandboxRootURL, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let sandboxRootURL {
            try? FileManager.default.removeItem(at: sandboxRootURL)
        }
        sandboxRootURL = nil
    }

    func testBootstrapPullsRemoteSnapshotWhenLocalIsEmpty() async throws {
        let cloudURL = sandboxRootURL.appendingPathComponent("cloud", isDirectory: true)

        let sourceRepositoryURL = sandboxRootURL.appendingPathComponent("source", isDirectory: true)
        let sourceRepository = CardRepository(appSupportDirectoryOverride: sourceRepositoryURL)
        try await sourceRepository.prepare()
        let sourceDeck = try await sourceRepository.createDeck(title: "Cloud Deck")
        _ = try await sourceRepository.addCard(
            to: sourceDeck.id,
            front: "Q",
            back: "A",
            note: "N"
        )

        let sourceDefaults = UserDefaults(suiteName: "ICloudSyncSource-\(UUID().uuidString)")!
        let sourceService = ICloudSyncService(
            repository: sourceRepository,
            userDefaults: sourceDefaults,
            containerURLOverride: cloudURL
        )
        await sourceService.bootstrap()
        await sourceService.handleLocalDataDidChange()

        let targetRepositoryURL = sandboxRootURL.appendingPathComponent("target", isDirectory: true)
        let targetRepository = CardRepository(appSupportDirectoryOverride: targetRepositoryURL)
        try await targetRepository.prepare()

        let targetDefaults = UserDefaults(suiteName: "ICloudSyncTarget-\(UUID().uuidString)")!
        let targetService = ICloudSyncService(
            repository: targetRepository,
            userDefaults: targetDefaults,
            containerURLOverride: cloudURL
        )
        await targetService.bootstrap()

        let summaries = try await targetRepository.deckSummaries()
        XCTAssertEqual(summaries.count, 1)
        XCTAssertEqual(summaries.first?.title, "Cloud Deck")
    }

    func testSyncFromCloudNowAppliesRemoteReset() async throws {
        let cloudURL = sandboxRootURL.appendingPathComponent("cloud-reset", isDirectory: true)

        let sourceRepositoryURL = sandboxRootURL.appendingPathComponent("source-reset", isDirectory: true)
        let sourceRepository = CardRepository(appSupportDirectoryOverride: sourceRepositoryURL)
        try await sourceRepository.prepare()
        let sourceDeck = try await sourceRepository.createDeck(title: "To Reset")
        _ = try await sourceRepository.addCard(
            to: sourceDeck.id,
            front: "Front",
            back: "Back",
            note: ""
        )

        let sourceDefaults = UserDefaults(suiteName: "ICloudSyncResetSource-\(UUID().uuidString)")!
        let sourceService = ICloudSyncService(
            repository: sourceRepository,
            userDefaults: sourceDefaults,
            containerURLOverride: cloudURL
        )
        await sourceService.bootstrap()
        await sourceService.handleLocalDataDidChange()

        let targetRepositoryURL = sandboxRootURL.appendingPathComponent("target-reset", isDirectory: true)
        let targetRepository = CardRepository(appSupportDirectoryOverride: targetRepositoryURL)
        try await targetRepository.prepare()
        let targetDefaults = UserDefaults(suiteName: "ICloudSyncResetTarget-\(UUID().uuidString)")!
        let targetService = ICloudSyncService(
            repository: targetRepository,
            userDefaults: targetDefaults,
            containerURLOverride: cloudURL
        )
        await targetService.bootstrap()

        try await sourceRepository.resetAllData()
        await sourceService.handleLocalDataDidChange()
        await targetService.syncFromCloudNow()

        let hasDecks = try await targetRepository.hasAnyDecks()
        XCTAssertFalse(hasDecks)
    }
}
