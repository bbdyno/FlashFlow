//
//  DeckDetailViewModel.swift
//  FlashForge
//
//  Created by bbdyno on 2/11/26.
//

import Foundation

@MainActor
final class DeckDetailViewModel {
    struct CardDraft: Sendable {
        let front: String
        let back: String
        let note: String
    }

    enum Input {
        case viewDidLoad
        case didTapReload
        case addCard(CardDraft)
        case updateCard(cardID: UUID, draft: CardDraft)
        case deleteCard(UUID)
    }

    struct Output {
        var didChangeLoading: @MainActor (Bool) -> Void
        var didUpdateDeckTitle: @MainActor (String) -> Void
        var didUpdateCards: @MainActor ([DeckCard]) -> Void
        var didReceiveError: @MainActor (String) -> Void

        init(
            didChangeLoading: @escaping @MainActor (Bool) -> Void = { _ in },
            didUpdateDeckTitle: @escaping @MainActor (String) -> Void = { _ in },
            didUpdateCards: @escaping @MainActor ([DeckCard]) -> Void = { _ in },
            didReceiveError: @escaping @MainActor (String) -> Void = { _ in }
        ) {
            self.didChangeLoading = didChangeLoading
            self.didUpdateDeckTitle = didUpdateDeckTitle
            self.didUpdateCards = didUpdateCards
            self.didReceiveError = didReceiveError
        }
    }

    private let repository: CardRepository
    private let deckID: UUID
    private var output: Output

    init(repository: CardRepository, deckID: UUID, output: Output = .init()) {
        self.repository = repository
        self.deckID = deckID
        self.output = output
    }

    func bind(output: Output) {
        self.output = output
    }

    func send(_ input: Input) async {
        switch input {
        case .viewDidLoad, .didTapReload:
            await refresh()
        case let .addCard(draft):
            await addCard(draft)
        case let .updateCard(cardID, draft):
            await updateCard(cardID: cardID, draft: draft)
        case let .deleteCard(cardID):
            await deleteCard(cardID)
        }
    }

    private func refresh() async {
        output.didChangeLoading(true)
        defer { output.didChangeLoading(false) }

        do {
            try await repository.prepare()
            let decks = try await repository.deckSummaries()
            if let deck = decks.first(where: { $0.id == deckID }) {
                output.didUpdateDeckTitle(deck.title)
            }

            let cards = try await repository.cards(in: deckID)
            output.didUpdateCards(cards)
        } catch {
            output.didReceiveError(Self.userFacingMessage(from: error))
        }
    }

    private func addCard(_ draft: CardDraft) async {
        do {
            _ = try await repository.addCard(
                to: deckID,
                front: draft.front,
                back: draft.back,
                note: draft.note
            )
            notifyDeckDataChanged()
            await refresh()
        } catch {
            output.didReceiveError(Self.userFacingMessage(from: error))
        }
    }

    private func updateCard(cardID: UUID, draft: CardDraft) async {
        do {
            try await repository.updateCard(
                deckID: deckID,
                cardID: cardID,
                front: draft.front,
                back: draft.back,
                note: draft.note
            )
            notifyDeckDataChanged()
            await refresh()
        } catch {
            output.didReceiveError(Self.userFacingMessage(from: error))
        }
    }

    private func deleteCard(_ cardID: UUID) async {
        do {
            try await repository.deleteCard(deckID: deckID, cardID: cardID)
            notifyDeckDataChanged()
            await refresh()
        } catch {
            output.didReceiveError(Self.userFacingMessage(from: error))
        }
    }

    private func notifyDeckDataChanged() {
        NotificationCenter.default.post(name: .deckDataDidChange, object: nil)
    }

    private static func userFacingMessage(from error: Error) -> String {
        if let localized = error as? LocalizedError,
           let description = localized.errorDescription,
           !description.isEmpty {
            return description
        }
        return "An error occurred while processing cards."
    }
}
