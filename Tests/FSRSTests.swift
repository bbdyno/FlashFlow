//
//  FSRSTests.swift
//  FlashForge
//
//  Created by bbdyno on 2/11/26.
//

import XCTest
@testable import FlashForge

final class FSRSTests: XCTestCase {
    func testNewCardGoodThenReviewIncreasesInterval() {
        let scheduler = FSRSScheduler(parameters: .default)

        var card = FSRSCard(
            stability: 0.4,
            difficulty: 5.0,
            elapsedDays: 0,
            scheduledDays: 0,
            reps: 0,
            state: .new,
            lastReview: Date()
        )

        card = scheduler.schedule(card: card, grade: .easy)
        XCTAssertEqual(card.state, .review)
        XCTAssertGreaterThanOrEqual(card.scheduledDays, 1)

        let firstInterval = card.scheduledDays
        card.elapsedDays = firstInterval
        let repsBeforeSecondReview = card.reps

        card = scheduler.schedule(card: card, grade: .easy)
        XCTAssertEqual(card.state, .review)
        XCTAssertGreaterThanOrEqual(card.scheduledDays, 1)
        XCTAssertGreaterThan(card.reps, repsBeforeSecondReview)
    }
}
