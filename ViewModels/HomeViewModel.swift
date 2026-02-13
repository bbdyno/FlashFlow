//
//  HomeViewModel.swift
//  FlashForge
//
//  Created by bbdyno on 2/11/26.
//

import Foundation

@MainActor
final class HomeViewModel {
    enum Input {
        case viewDidLoad
        case didTapReload
        case didSelectDeck(UUID)
        case didSelectGrade(UserGrade)
        case didReceiveExternalDataChange
    }

    struct Output {
        var didChangeLoading: @MainActor (Bool) -> Void
        var didUpdateDeckSummaries: @MainActor ([DeckSummary], UUID?) -> Void
        var didUpdateQueueCounts: @MainActor (QueueDueCounts) -> Void
        var didUpdateCard: @MainActor (StudyCard) -> Void
        var didShowEmptyState: @MainActor (String) -> Void
        var didReceiveError: @MainActor (String) -> Void

        init(
            didChangeLoading: @escaping @MainActor (Bool) -> Void = { _ in },
            didUpdateDeckSummaries: @escaping @MainActor ([DeckSummary], UUID?) -> Void = { _, _ in },
            didUpdateQueueCounts: @escaping @MainActor (QueueDueCounts) -> Void = { _ in },
            didUpdateCard: @escaping @MainActor (StudyCard) -> Void = { _ in },
            didShowEmptyState: @escaping @MainActor (String) -> Void = { _ in },
            didReceiveError: @escaping @MainActor (String) -> Void = { _ in }
        ) {
            self.didChangeLoading = didChangeLoading
            self.didUpdateDeckSummaries = didUpdateDeckSummaries
            self.didUpdateQueueCounts = didUpdateQueueCounts
            self.didUpdateCard = didUpdateCard
            self.didShowEmptyState = didShowEmptyState
            self.didReceiveError = didReceiveError
        }
    }

    private let repository: CardRepository
    private let studyStatusService: StudyStatusService
    private var output: Output

    private var selectedDeckID: UUID?
    private var currentCardID: UUID?
    private var latestDeckSummaries: [DeckSummary] = []

    init(
        repository: CardRepository,
        studyStatusService: StudyStatusService = .shared,
        output: Output = .init()
    ) {
        self.repository = repository
        self.studyStatusService = studyStatusService
        self.output = output
    }

    func bind(output: Output) {
        self.output = output
    }

    func send(_ input: Input) async {
        switch input {
        case .viewDidLoad:
            await bootstrap()
        case .didTapReload, .didReceiveExternalDataChange:
            await reloadDecksAndCurrentCard(resetDeckSelection: false)
        case let .didSelectDeck(deckID):
            selectedDeckID = deckID
            await refreshCurrentDeckState()
        case let .didSelectGrade(grade):
            await applyGrade(grade)
        }
    }

    private func bootstrap() async {
        output.didChangeLoading(true)
        defer { output.didChangeLoading(false) }

        do {
            try await repository.prepare()
            await reloadDecksAndCurrentCard(resetDeckSelection: true)
        } catch {
            output.didReceiveError(Self.userFacingMessage(from: error))
        }
    }

    private func reloadDecksAndCurrentCard(resetDeckSelection: Bool) async {
        output.didChangeLoading(true)
        defer { output.didChangeLoading(false) }

        do {
            let summaries = try await repository.deckSummaries()
            if summaries.isEmpty {
                latestDeckSummaries = []
                selectedDeckID = nil
                currentCardID = nil
                output.didUpdateDeckSummaries([], nil)
                output.didUpdateQueueCounts(QueueDueCounts(learning: 0, review: 0))
                output.didShowEmptyState("Create a deck and add your first card to begin.")
                studyStatusService.updateStudyProgress(
                    counts: QueueDueCounts(learning: 0, review: 0),
                    completedCount: 0,
                    selectedDeckTitle: nil,
                    hasCurrentCard: false
                )
                return
            }

            latestDeckSummaries = summaries
            if resetDeckSelection || selectedDeckID == nil || !summaries.contains(where: { $0.id == selectedDeckID }) {
                selectedDeckID = summaries.first?.id
            }

            output.didUpdateDeckSummaries(summaries, selectedDeckID)
            await refreshCurrentDeckState()
        } catch {
            output.didReceiveError(Self.userFacingMessage(from: error))
        }
    }

    private func refreshCurrentDeckState() async {
        guard let selectedDeckID else {
            currentCardID = nil
            output.didUpdateQueueCounts(QueueDueCounts(learning: 0, review: 0))
            output.didShowEmptyState("Please select a deck.")
            studyStatusService.updateStudyProgress(
                counts: QueueDueCounts(learning: 0, review: 0),
                completedCount: 0,
                selectedDeckTitle: nil,
                hasCurrentCard: false
            )
            return
        }

        do {
            let counts = try await repository.queueDueCounts(deckID: selectedDeckID)
            let nextCard = try await nextDueCard(deckID: selectedDeckID)
            let completedToday = try await repository.reviewCountToday(deckID: selectedDeckID)

            output.didUpdateQueueCounts(counts)

            if let nextCard {
                currentCardID = nextCard.id
                output.didUpdateCard(nextCard)
            } else {
                currentCardID = nil
                output.didShowEmptyState(emptyMessage())
            }

            studyStatusService.updateStudyProgress(
                counts: counts,
                completedCount: completedToday,
                selectedDeckTitle: selectedDeckTitle(for: selectedDeckID),
                hasCurrentCard: nextCard != nil
            )
        } catch {
            output.didReceiveError(Self.userFacingMessage(from: error))
        }
    }

    private func nextDueCard(deckID: UUID) async throws -> StudyCard? {
        if let learning = try await repository.nextDueCard(deckID: deckID, queue: .learning) {
            return learning
        }
        return try await repository.nextDueCard(deckID: deckID, queue: .review)
    }

    private func applyGrade(_ grade: UserGrade) async {
        guard let selectedDeckID, let currentCardID else {
            return
        }

        do {
            try await repository.review(deckID: selectedDeckID, cardID: currentCardID, grade: grade)
            await refreshCurrentDeckState()
        } catch {
            output.didReceiveError(Self.userFacingMessage(from: error))
        }
    }

    private func emptyMessage() -> String {
        "No cards due today."
    }

    private func selectedDeckTitle(for deckID: UUID) -> String? {
        latestDeckSummaries.first(where: { $0.id == deckID })?.title
    }

    private static func userFacingMessage(from error: Error) -> String {
        if let localized = error as? LocalizedError,
           let description = localized.errorDescription,
           !description.isEmpty {
            return description
        }
        return "We couldn't process your request. Please try again."
    }
}
