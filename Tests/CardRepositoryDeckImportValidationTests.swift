import XCTest
@testable import FlashForge

final class CardRepositoryDeckImportValidationTests: XCTestCase {
    private var sandboxRootURL: URL!

    override func setUpWithError() throws {
        sandboxRootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("FlashForgeDeckImportTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: sandboxRootURL, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let sandboxRootURL {
            try? FileManager.default.removeItem(at: sandboxRootURL)
        }
        sandboxRootURL = nil
    }

    func testImportDeckDataUsesDeckTitleAlias() async throws {
        let repositoryURL = sandboxRootURL.appendingPathComponent("alias", isDirectory: true)
        let repository = CardRepository(appSupportDirectoryOverride: repositoryURL)
        try await repository.prepare()

        let payload = """
        {
          "deckTitle": "Alias Deck",
          "cards": [
            {
              "front": "Front",
              "back": "Back",
              "note": "Note"
            }
          ]
        }
        """

        _ = try await repository.importDeckData(Data(payload.utf8))
        let summaries = try await repository.deckSummaries()
        XCTAssertEqual(summaries.first?.title, "Alias Deck")
    }

    func testImportDeckDataRejectsWhitespaceOnlyTitle() async throws {
        let repositoryURL = sandboxRootURL.appendingPathComponent("invalid-title", isDirectory: true)
        let repository = CardRepository(appSupportDirectoryOverride: repositoryURL)
        try await repository.prepare()

        let payload = """
        {
          "title": "   ",
          "cards": [
            {
              "front": "Front",
              "back": "Back",
              "note": "Note"
            }
          ]
        }
        """

        do {
            _ = try await repository.importDeckData(Data(payload.utf8))
            XCTFail("Expected invalidTitle error")
        } catch let error as CardRepository.RepositoryError {
            guard case .invalidTitle = error else {
                XCTFail("Expected invalidTitle, got \(error)")
                return
            }
        }
    }
}
