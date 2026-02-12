//
//  Deck.swift
//  FlashForge
//
//  Created by bbdyno on 2/11/26.
//

import Foundation

enum StudyQueue: Int, CaseIterable, Sendable {
    case learning
    case review

    var title: String {
        switch self {
        case .learning:
            return "Learning"
        case .review:
            return "Review"
        }
    }
}

struct QueueDueCounts: Hashable, Sendable {
    let learning: Int
    let review: Int

    var total: Int {
        learning + review
    }
}

struct DeckCard: Identifiable, Codable, Sendable {
    let id: UUID
    var content: FlashCard
    var schedule: Card

    init(
        id: UUID = UUID(),
        content: FlashCard,
        schedule: Card? = nil
    ) {
        self.id = id
        self.content = content
        self.schedule = schedule ?? Card(id: id)
    }
}

struct Deck: Identifiable, Codable, Sendable {
    let id: UUID
    var title: String
    var createdAt: Date
    var cards: [DeckCard]

    init(
        id: UUID = UUID(),
        title: String,
        createdAt: Date = .now,
        cards: [DeckCard] = []
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.cards = cards
    }
}

struct DeckSummary: Identifiable, Hashable, Sendable {
    let id: UUID
    let title: String
    let totalCardCount: Int
    let dueCounts: QueueDueCounts
}

struct BackupPreview: Sendable {
    let deckCount: Int
    let cardCount: Int
    let reviewCount: Int
}
