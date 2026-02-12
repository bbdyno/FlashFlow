//
//  CardTextSanitizerTests.swift
//  FlashForgeTests
//
//  Created by bbdyno on 2/12/26.
//

import XCTest
@testable import FlashForge

final class CardTextSanitizerTests: XCTestCase {
    func testNormalizeMultilineTrimsAndCollapsesBlankLines() {
        let raw = "\n  Front text  \n\n  \n  Next line  \n"

        let normalized = CardTextSanitizer.normalizeMultiline(raw)

        XCTAssertEqual(normalized, "Front text\n\nNext line")
    }

    func testNormalizeSingleLineFlattensLineBreaksAndTabs() {
        let raw = "  one \n\t two   three \r\n four "

        let normalized = CardTextSanitizer.normalizeSingleLine(raw)

        XCTAssertEqual(normalized, "one two three four")
    }

    func testPreviewLineShowsAdditionalLineCount() {
        let text = "Question line\nAnswer detail\nExtra clue"

        let preview = CardTextSanitizer.previewLine(from: text, emptyFallback: "Empty")

        XCTAssertEqual(preview, "Question line (+2 lines)")
    }

    func testPreviewLineUsesFallbackForWhitespaceOnlyText() {
        let preview = CardTextSanitizer.previewLine(from: "\n  \n\t", emptyFallback: "Empty")

        XCTAssertEqual(preview, "Empty")
    }

    func testLegacyNoNoteDetectionIgnoresCaseAndSpacing() {
        XCTAssertTrue(CardTextSanitizer.isLegacyNoNote("  no   Note \n"))
    }
}
