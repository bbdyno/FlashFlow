//
//  Card.swift
//  FlashFlow
//
//  Created by bbdyno on 2/11/26.
//

import Foundation

enum CardState: String, Codable, Sendable {
    case new
    case learning
    case review
    case relearning
}

enum UserGrade: Int, CaseIterable, Codable, Sendable {
    case again = 1
    case hard = 2
    case good = 3
    case easy = 4
}

struct FSRSReviewState: Sendable, Identifiable, Codable {
    let id: UUID
    var stability: Double
    var difficulty: Double
    var reps: Int
    var scheduledDays: Int
    var lastReview: Date

    init(
        id: UUID,
        stability: Double = 0.4,
        difficulty: Double = 5.0,
        reps: Int = 0,
        scheduledDays: Int = 0,
        lastReview: Date = .now
    ) {
        self.id = id
        self.stability = stability
        self.difficulty = difficulty
        self.reps = reps
        self.scheduledDays = scheduledDays
        self.lastReview = lastReview
    }
}

struct Card: Sendable, Identifiable, Codable {
    let id: UUID
    var state: CardState
    var stepIndex: Int?
    var easeFactor: Double
    var interval: Int
    var dueDate: Date
    var reviewHistory: [Date]
    var fsrsState: FSRSReviewState?

    init(
        id: UUID = UUID(),
        state: CardState = .new,
        stepIndex: Int? = nil,
        easeFactor: Double = 2.5,
        interval: Int = 0,
        dueDate: Date = Date(),
        reviewHistory: [Date] = [],
        fsrsState: FSRSReviewState? = nil
    ) {
        self.id = id
        self.state = state
        self.stepIndex = stepIndex
        self.easeFactor = easeFactor
        self.interval = interval
        self.dueDate = dueDate
        self.reviewHistory = reviewHistory
        self.fsrsState = fsrsState
    }
}
