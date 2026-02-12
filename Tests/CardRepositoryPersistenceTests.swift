//
//  CardRepositoryPersistenceTests.swift
//  FlashForgeTests
//
//  Created by bbdyno on 2/12/26.
//

import XCTest
@testable import FlashForge

final class CardRepositoryPersistenceTests: XCTestCase {
    private var sandboxRootURL: URL!

    override func setUpWithError() throws {
        sandboxRootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("FlashForgeTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: sandboxRootURL, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let sandboxRootURL {
            try? FileManager.default.removeItem(at: sandboxRootURL)
        }
        sandboxRootURL = nil
    }

    func testBackupExportImportReflectsIntoSwiftDataStore() async throws {
        let sourceURL = sandboxRootURL.appendingPathComponent("source", isDirectory: true)
        let targetURL = sandboxRootURL.appendingPathComponent("target", isDirectory: true)

        let sourceRepository = CardRepository(appSupportDirectoryOverride: sourceURL)
        try await sourceRepository.prepare()

        let deck = try await sourceRepository.createDeck(title: "Biology")
        _ = try await sourceRepository.addCard(
            to: deck.id,
            front: "What is ATP?",
            back: "Adenosine triphosphate\nEnergy currency of cells",
            note: "Cell biology"
        )

        let backupData = try await sourceRepository.exportBackupData()

        let targetRepository = CardRepository(appSupportDirectoryOverride: targetURL)
        try await targetRepository.prepare()
        let targetHasDecks = try await targetRepository.hasAnyDecks()
        XCTAssertFalse(targetHasDecks)

        try await targetRepository.importBackupData(backupData)

        let summaries = try await targetRepository.deckSummaries()
        XCTAssertEqual(summaries.count, 1)
        XCTAssertEqual(summaries.first?.title, "Biology")

        guard let deckID = summaries.first?.id else {
            XCTFail("Imported deck id missing")
            return
        }

        let cards = try await targetRepository.cards(in: deckID)
        XCTAssertEqual(cards.count, 1)
        XCTAssertEqual(cards[0].content.title, "What is ATP?")
        XCTAssertEqual(cards[0].content.detail, "Adenosine triphosphate\nEnergy currency of cells")
        XCTAssertEqual(cards[0].content.subtitle, "Cell biology")
    }

    func testPrepareMigratesLegacyJsonStoreIntoSwiftData() async throws {
        struct LegacyStore: Codable {
            let decks: [Deck]
            let schedulerMode: SchedulerMode
        }

        let migrationURL = sandboxRootURL.appendingPathComponent("migration", isDirectory: true)
        try FileManager.default.createDirectory(at: migrationURL, withIntermediateDirectories: true)

        let legacyDeck = Deck(
            title: "Legacy Deck",
            cards: [
                DeckCard(
                    content: FlashCard(
                        title: "Legacy Front",
                        subtitle: "Legacy Note",
                        detail: "Legacy Back",
                        imageName: "book.closed.fill"
                    )
                )
            ]
        )

        let legacyStore = LegacyStore(decks: [legacyDeck], schedulerMode: .sm2)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let legacyData = try encoder.encode(legacyStore)

        let legacyStorageURL = migrationURL.appendingPathComponent("storage.json")
        try legacyData.write(to: legacyStorageURL, options: .atomic)

        let repository = CardRepository(appSupportDirectoryOverride: migrationURL)
        try await repository.prepare()

        let hasDecks = try await repository.hasAnyDecks()
        XCTAssertTrue(hasDecks)

        let schedulerMode = try await repository.schedulerMode()
        XCTAssertEqual(schedulerMode, .fsrs)

        let summaries = try await repository.deckSummaries()
        XCTAssertEqual(summaries.count, 1)
        XCTAssertEqual(summaries.first?.title, "Legacy Deck")

        XCTAssertFalse(FileManager.default.fileExists(atPath: legacyStorageURL.path))
    }
}
