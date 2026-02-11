//
//  HomeViewModel.swift
//  FlashFlow
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
        case didSelectQueue(StudyQueue)
        case didSelectGrade(UserGrade)
        case didSwipeCard(SwipeDirection)
        case didReceiveExternalDataChange
    }

    struct Output {
        var didChangeLoading: @MainActor (Bool) -> Void
        var didUpdateDeckSummaries: @MainActor ([DeckSummary], UUID?) -> Void
        var didUpdateQueueSelection: @MainActor (StudyQueue) -> Void
        var didUpdateSchedulerMode: @MainActor (SchedulerMode) -> Void
        var didUpdateQueueCounts: @MainActor (QueueDueCounts) -> Void
        var didUpdateCard: @MainActor (StudyCard) -> Void
        var didUpdateHeatmap: @MainActor ([Date: Int]) -> Void
        var didShowEmptyState: @MainActor (String) -> Void
        var didReceiveError: @MainActor (String) -> Void

        init(
            didChangeLoading: @escaping @MainActor (Bool) -> Void = { _ in },
            didUpdateDeckSummaries: @escaping @MainActor ([DeckSummary], UUID?) -> Void = { _, _ in },
            didUpdateQueueSelection: @escaping @MainActor (StudyQueue) -> Void = { _ in },
            didUpdateSchedulerMode: @escaping @MainActor (SchedulerMode) -> Void = { _ in },
            didUpdateQueueCounts: @escaping @MainActor (QueueDueCounts) -> Void = { _ in },
            didUpdateCard: @escaping @MainActor (StudyCard) -> Void = { _ in },
            didUpdateHeatmap: @escaping @MainActor ([Date: Int]) -> Void = { _ in },
            didShowEmptyState: @escaping @MainActor (String) -> Void = { _ in },
            didReceiveError: @escaping @MainActor (String) -> Void = { _ in }
        ) {
            self.didChangeLoading = didChangeLoading
            self.didUpdateDeckSummaries = didUpdateDeckSummaries
            self.didUpdateQueueSelection = didUpdateQueueSelection
            self.didUpdateSchedulerMode = didUpdateSchedulerMode
            self.didUpdateQueueCounts = didUpdateQueueCounts
            self.didUpdateCard = didUpdateCard
            self.didUpdateHeatmap = didUpdateHeatmap
            self.didShowEmptyState = didShowEmptyState
            self.didReceiveError = didReceiveError
        }
    }

    private let repository: CardRepository
    private var output: Output

    private var selectedDeckID: UUID?
    private var selectedQueue: StudyQueue = .learning
    private var currentCardID: UUID?

    init(repository: CardRepository, output: Output = .init()) {
        self.repository = repository
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
        case let .didSelectQueue(queue):
            selectedQueue = queue
            output.didUpdateQueueSelection(queue)
            await presentNextCard()
        case let .didSelectGrade(grade):
            await applyGrade(grade)
        case let .didSwipeCard(direction):
            let mapped: UserGrade = (direction == .left) ? .again : .good
            await applyGrade(mapped)
        }
    }

    private func bootstrap() async {
        output.didChangeLoading(true)
        defer { output.didChangeLoading(false) }

        do {
            try await repository.prepare()
            output.didUpdateQueueSelection(selectedQueue)
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
            let mode = try await repository.schedulerMode()
            output.didUpdateSchedulerMode(mode)
            if summaries.isEmpty {
                selectedDeckID = nil
                currentCardID = nil
                output.didUpdateDeckSummaries([], nil)
                output.didUpdateQueueCounts(QueueDueCounts(learning: 0, review: 0))
                output.didUpdateHeatmap([:])
                output.didShowEmptyState("덱을 생성하고 첫 카드를 추가하면 학습을 시작할 수 있습니다.")
                return
            }

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
            output.didUpdateHeatmap([:])
            output.didShowEmptyState("덱을 선택해주세요.")
            return
        }

        do {
            enum DeckLoadResult: Sendable {
                case counts(QueueDueCounts)
                case heatmap([Date: Int])
                case nextCard(StudyCard?)
            }

            let repository = self.repository
            let queue = selectedQueue

            var counts = QueueDueCounts(learning: 0, review: 0)
            var heatmap: [Date: Int] = [:]
            var nextCard: StudyCard?

            // TaskGroup으로 초기 화면에 필요한 데이터를 동시에 요청합니다.
            // 저장소는 actor이므로 내부 상태 일관성은 actor 격리가 보장합니다.
            try await withThrowingTaskGroup(of: DeckLoadResult.self) { group in
                group.addTask {
                    .counts(try await repository.queueDueCounts(deckID: selectedDeckID))
                }
                group.addTask {
                    .heatmap(try await repository.reviewHeatmap(deckID: selectedDeckID, days: 140))
                }
                group.addTask {
                    .nextCard(try await repository.nextDueCard(deckID: selectedDeckID, queue: queue))
                }

                for try await result in group {
                    switch result {
                    case let .counts(value):
                        counts = value
                    case let .heatmap(value):
                        heatmap = value
                    case let .nextCard(value):
                        nextCard = value
                    }
                }
            }

            output.didUpdateQueueCounts(counts)
            output.didUpdateHeatmap(heatmap)

            if let nextCard {
                currentCardID = nextCard.id
                output.didUpdateCard(nextCard)
            } else {
                currentCardID = nil
                output.didShowEmptyState(emptyMessage(for: queue))
            }
        } catch {
            output.didReceiveError(Self.userFacingMessage(from: error))
        }
    }

    private func presentNextCard() async {
        guard let selectedDeckID else {
            currentCardID = nil
            output.didShowEmptyState("덱을 선택해주세요.")
            return
        }

        do {
            if let next = try await repository.nextDueCard(deckID: selectedDeckID, queue: selectedQueue) {
                currentCardID = next.id
                output.didUpdateCard(next)
                return
            }

            currentCardID = nil
            output.didShowEmptyState(emptyMessage(for: selectedQueue))
        } catch {
            output.didReceiveError(Self.userFacingMessage(from: error))
        }
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

    private func emptyMessage(for queue: StudyQueue) -> String {
        switch queue {
        case .learning:
            return "지금 학습할 Learning 카드가 없습니다."
        case .review:
            return "지금 복습할 Review 카드가 없습니다."
        }
    }

    private static func userFacingMessage(from error: Error) -> String {
        if let localized = error as? LocalizedError,
           let description = localized.errorDescription,
           !description.isEmpty {
            return description
        }
        return "요청을 처리하지 못했습니다. 잠시 후 다시 시도해주세요."
    }
}
