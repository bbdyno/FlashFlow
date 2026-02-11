//
//  FlashCard.swift
//  FlashFlow
//
//  Created by bbdyno on 2/11/26.
//

import Foundation

struct FlashCard: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let title: String
    let subtitle: String
    let detail: String
    let imageName: String

    init(
        id: UUID = UUID(),
        title: String,
        subtitle: String,
        detail: String,
        imageName: String
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.detail = detail
        self.imageName = imageName
    }
}

struct FlashCardText: Hashable, Codable, Sendable {
    let title: String
    let subtitle: String
    let detail: String
}
