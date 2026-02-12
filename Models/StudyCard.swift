//
//  StudyCard.swift
//  FlashForge
//
//  Created by bbdyno on 2/11/26.
//

import Foundation

struct StudyCard: Identifiable, Sendable {
    let deckID: UUID
    let deckTitle: String
    let schedule: Card
    let content: FlashCard

    var id: UUID {
        schedule.id
    }
}
