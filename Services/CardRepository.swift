//
//  CardRepository.swift
//  FlashFlow
//
//  Created by bbdyno on 2/11/26.
//

import Foundation

actor CardRepository {
    enum RepositoryError: LocalizedError, Sendable {
        case invalidTitle
        case invalidCardContent
        case deckNotFound
        case cardNotFound
        case persistenceFailed

        var errorDescription: String? {
            switch self {
            case .invalidTitle:
                return "덱 이름을 입력해주세요."
            case .invalidCardContent:
                return "카드 앞면과 뒷면을 모두 입력해주세요."
            case .deckNotFound:
                return "선택한 덱을 찾을 수 없습니다."
            case .cardNotFound:
                return "선택한 카드를 찾을 수 없습니다."
            case .persistenceFailed:
                return "데이터 저장 중 오류가 발생했습니다."
            }
        }
    }

    private struct Store: Codable, Sendable {
        var decks: [Deck]
        var schedulerMode: SchedulerMode

        init(
            decks: [Deck] = [],
            schedulerMode: SchedulerMode = .sm2
        ) {
            self.decks = decks
            self.schedulerMode = schedulerMode
        }

        private enum CodingKeys: String, CodingKey {
            case decks
            case schedulerMode
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            decks = try container.decodeIfPresent([Deck].self, forKey: .decks) ?? []
            schedulerMode = try container.decodeIfPresent(SchedulerMode.self, forKey: .schedulerMode) ?? .sm2
        }
    }

    // Actor로 스토리지 상태를 직렬화해 CRUD/스케줄 갱신이 thread-safe 하게 동작합니다.
    private var store = Store()
    private var hasLoaded = false

    private let ankiScheduler: AnkiScheduler
    private let fsrsScheduler: FSRSScheduler
    private let calendar: Calendar
    private let fileManager: FileManager
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(
        ankiScheduler: AnkiScheduler = AnkiScheduler(),
        fsrsScheduler: FSRSScheduler = FSRSScheduler(parameters: .default),
        calendar: Calendar = .current,
        fileManager: FileManager = .default
    ) {
        self.ankiScheduler = ankiScheduler
        self.fsrsScheduler = fsrsScheduler
        self.calendar = calendar
        self.fileManager = fileManager

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601

        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    func prepare() throws {
        try loadIfNeeded()
    }

    func hasAnyDecks() throws -> Bool {
        try loadIfNeeded()
        return !store.decks.isEmpty
    }

    func schedulerMode() throws -> SchedulerMode {
        try loadIfNeeded()
        return store.schedulerMode
    }

    func updateSchedulerMode(_ mode: SchedulerMode) throws {
        try loadIfNeeded()
        guard store.schedulerMode != mode else {
            return
        }

        store.schedulerMode = mode
        try persist()
    }

    func deckSummaries(now: Date = .now) throws -> [DeckSummary] {
        try loadIfNeeded()
        return store.decks.map { deck in
            DeckSummary(
                id: deck.id,
                title: deck.title,
                totalCardCount: deck.cards.count,
                dueCounts: dueCounts(for: deck, now: now)
            )
        }
        .sorted { lhs, rhs in
            lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }
    }

    func createDeck(title: String) throws -> Deck {
        try loadIfNeeded()

        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw RepositoryError.invalidTitle
        }

        let deck = Deck(title: trimmed)
        store.decks.append(deck)
        try persist()
        return deck
    }

    func renameDeck(deckID: UUID, title: String) throws {
        try loadIfNeeded()

        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw RepositoryError.invalidTitle
        }

        guard let deckIndex = store.decks.firstIndex(where: { $0.id == deckID }) else {
            throw RepositoryError.deckNotFound
        }

        store.decks[deckIndex].title = trimmed
        try persist()
    }

    func deleteDeck(deckID: UUID) throws {
        try loadIfNeeded()
        guard let deckIndex = store.decks.firstIndex(where: { $0.id == deckID }) else {
            throw RepositoryError.deckNotFound
        }

        store.decks.remove(at: deckIndex)
        try persist()
    }

    func cards(in deckID: UUID) throws -> [DeckCard] {
        try loadIfNeeded()
        guard let deck = store.decks.first(where: { $0.id == deckID }) else {
            throw RepositoryError.deckNotFound
        }

        return deck.cards.sorted { lhs, rhs in
            lhs.content.title.localizedCaseInsensitiveCompare(rhs.content.title) == .orderedAscending
        }
    }

    func addCard(
        to deckID: UUID,
        front: String,
        back: String,
        note: String
    ) throws -> DeckCard {
        try loadIfNeeded()

        let normalized = try normalizedCardContent(front: front, back: back, note: note)
        guard let deckIndex = store.decks.firstIndex(where: { $0.id == deckID }) else {
            throw RepositoryError.deckNotFound
        }

        let content = FlashCard(
            title: normalized.front,
            subtitle: normalized.note,
            detail: normalized.back,
            imageName: suggestedImageName(from: normalized.front)
        )
        let card = DeckCard(content: content)

        store.decks[deckIndex].cards.append(card)
        try persist()
        return card
    }

    func updateCard(
        deckID: UUID,
        cardID: UUID,
        front: String,
        back: String,
        note: String
    ) throws {
        try loadIfNeeded()

        let normalized = try normalizedCardContent(front: front, back: back, note: note)
        guard let deckIndex = store.decks.firstIndex(where: { $0.id == deckID }) else {
            throw RepositoryError.deckNotFound
        }
        guard let cardIndex = store.decks[deckIndex].cards.firstIndex(where: { $0.id == cardID }) else {
            throw RepositoryError.cardNotFound
        }

        var target = store.decks[deckIndex].cards[cardIndex]
        target.content = FlashCard(
            id: target.content.id,
            title: normalized.front,
            subtitle: normalized.note,
            detail: normalized.back,
            imageName: target.content.imageName
        )
        store.decks[deckIndex].cards[cardIndex] = target
        try persist()
    }

    func deleteCard(deckID: UUID, cardID: UUID) throws {
        try loadIfNeeded()

        guard let deckIndex = store.decks.firstIndex(where: { $0.id == deckID }) else {
            throw RepositoryError.deckNotFound
        }
        guard let cardIndex = store.decks[deckIndex].cards.firstIndex(where: { $0.id == cardID }) else {
            throw RepositoryError.cardNotFound
        }

        store.decks[deckIndex].cards.remove(at: cardIndex)
        try persist()
    }

    func queueDueCounts(deckID: UUID, now: Date = .now) throws -> QueueDueCounts {
        try loadIfNeeded()
        guard let deck = store.decks.first(where: { $0.id == deckID }) else {
            throw RepositoryError.deckNotFound
        }
        return dueCounts(for: deck, now: now)
    }

    func nextDueCard(deckID: UUID, queue: StudyQueue, now: Date = .now) throws -> StudyCard? {
        try loadIfNeeded()

        guard let deck = store.decks.first(where: { $0.id == deckID }) else {
            throw RepositoryError.deckNotFound
        }

        let candidates = deck.cards.filter { entry in
            entry.schedule.dueDate <= now && matches(queue: queue, state: entry.schedule.state)
        }

        guard let next = candidates.sorted(by: cardSort).first else {
            return nil
        }

        return StudyCard(
            deckID: deck.id,
            deckTitle: deck.title,
            schedule: next.schedule,
            content: next.content
        )
    }

    @discardableResult
    func review(deckID: UUID, cardID: UUID, grade: UserGrade, now: Date = .now) throws -> Card {
        try loadIfNeeded()

        guard let deckIndex = store.decks.firstIndex(where: { $0.id == deckID }) else {
            throw RepositoryError.deckNotFound
        }
        guard let cardIndex = store.decks[deckIndex].cards.firstIndex(where: { $0.id == cardID }) else {
            throw RepositoryError.cardNotFound
        }

        var card = store.decks[deckIndex].cards[cardIndex]
        card.schedule.reviewHistory.append(now)
        card.schedule = scheduleCard(card.schedule, grade: grade, now: now)
        store.decks[deckIndex].cards[cardIndex] = card

        try persist()
        return card.schedule
    }

    func reviewHeatmap(deckID: UUID, days: Int = 140, now: Date = .now) throws -> [Date: Int] {
        try loadIfNeeded()

        guard let deck = store.decks.first(where: { $0.id == deckID }) else {
            throw RepositoryError.deckNotFound
        }

        var summary: [Date: Int] = [:]
        for card in deck.cards {
            for timestamp in card.schedule.reviewHistory {
                let date = calendar.startOfDay(for: timestamp)
                summary[date, default: 0] += 1
            }
        }

        let today = calendar.startOfDay(for: now)
        for offset in 0..<max(1, days) {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else {
                continue
            }
            summary[date, default: 0] += 0
        }
        return summary
    }

    private func loadIfNeeded() throws {
        guard !hasLoaded else {
            return
        }

        let url = try storageFileURL()
        guard fileManager.fileExists(atPath: url.path) else {
            store = Store()
            try persist()
            hasLoaded = true
            return
        }

        let data = try Data(contentsOf: url)
        store = try decoder.decode(Store.self, from: data)
        hasLoaded = true
    }

    private func scheduleCard(_ card: Card, grade: UserGrade, now: Date) -> Card {
        switch store.schedulerMode {
        case .sm2:
            return ankiScheduler.schedule(card: card, grade: grade, now: now)
        case .fsrs:
            return scheduleWithFSRSHybrid(card: card, grade: grade, now: now)
        }
    }

    private func scheduleWithFSRSHybrid(card: Card, grade: UserGrade, now: Date) -> Card {
        switch card.state {
        case .new, .learning, .relearning:
            // FSRS 모드에서도 learning/relearning 단계는 Anki step 로직(분 단위)을 유지합니다.
            var next = ankiScheduler.schedule(card: card, grade: grade, now: now)
            if next.state == .review {
                next.fsrsState = seededFSRSState(from: next, now: now)
            }
            return next
        case .review:
            // Review 단계만 FSRS 수식을 적용해 안정성/난이도/다음 interval을 계산합니다.
            return scheduleReviewWithFSRS(card: card, grade: grade, now: now)
        }
    }

    private func scheduleReviewWithFSRS(card: Card, grade: UserGrade, now: Date) -> Card {
        let fsrsInput = makeFSRSCard(from: card, now: now)
        let fsrsOutput = fsrsScheduler.schedule(card: fsrsInput, grade: grade)

        if grade == .again {
            // FSRS의 실패 난이도/안정성 갱신값은 유지하면서, due는 relearning step(분 단위)로 설정합니다.
            var relearning = ankiScheduler.schedule(card: card, grade: grade, now: now)
            relearning.fsrsState = FSRSReviewState(
                id: card.id,
                stability: fsrsOutput.stability,
                difficulty: fsrsOutput.difficulty,
                reps: fsrsOutput.reps,
                scheduledDays: fsrsOutput.scheduledDays,
                lastReview: now
            )
            return relearning
        }

        var next = card
        next.state = .review
        next.stepIndex = nil
        next.interval = max(1, fsrsOutput.scheduledDays)
        next.dueDate = calendar.date(byAdding: .day, value: next.interval, to: now) ?? now
        next.fsrsState = FSRSReviewState(
            id: card.id,
            stability: fsrsOutput.stability,
            difficulty: fsrsOutput.difficulty,
            reps: fsrsOutput.reps,
            scheduledDays: fsrsOutput.scheduledDays,
            lastReview: now
        )
        return next
    }

    private func makeFSRSCard(from card: Card, now: Date) -> FSRSCard {
        let baseline = card.fsrsState ?? seededFSRSState(from: card, now: now)
        let elapsed = daysBetween(baseline.lastReview, and: now)

        return FSRSCard(
            stability: baseline.stability,
            difficulty: baseline.difficulty,
            elapsedDays: elapsed,
            scheduledDays: max(0, baseline.scheduledDays),
            reps: baseline.reps,
            state: card.state,
            lastReview: baseline.lastReview
        )
    }

    private func seededFSRSState(from card: Card, now: Date) -> FSRSReviewState {
        FSRSReviewState(
            id: card.id,
            stability: max(0.4, Double(max(1, card.interval))),
            difficulty: 5.0,
            reps: max(1, card.reviewHistory.count),
            scheduledDays: max(0, card.interval),
            lastReview: now
        )
    }

    private func daysBetween(_ start: Date, and end: Date) -> Int {
        let from = calendar.startOfDay(for: start)
        let to = calendar.startOfDay(for: end)
        return max(0, calendar.dateComponents([.day], from: from, to: to).day ?? 0)
    }

    private func persist() throws {
        do {
            let data = try encoder.encode(store)
            try data.write(to: storageFileURL(), options: .atomic)
        } catch {
            throw RepositoryError.persistenceFailed
        }
    }

    private func storageFileURL() throws -> URL {
        let rootURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = rootURL.appendingPathComponent("FlashFlow", isDirectory: true)
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory.appendingPathComponent("storage.json")
    }

    private func dueCounts(for deck: Deck, now: Date) -> QueueDueCounts {
        let dueCards = deck.cards.filter { $0.schedule.dueDate <= now }
        let learning = dueCards.filter { matches(queue: .learning, state: $0.schedule.state) }.count
        let review = dueCards.filter { matches(queue: .review, state: $0.schedule.state) }.count
        return QueueDueCounts(learning: learning, review: review)
    }

    private func matches(queue: StudyQueue, state: CardState) -> Bool {
        switch queue {
        case .learning:
            return state == .new || state == .learning || state == .relearning
        case .review:
            return state == .review
        }
    }

    private func cardSort(lhs: DeckCard, rhs: DeckCard) -> Bool {
        if lhs.schedule.dueDate != rhs.schedule.dueDate {
            return lhs.schedule.dueDate < rhs.schedule.dueDate
        }

        let leftPriority = statePriority(lhs.schedule.state)
        let rightPriority = statePriority(rhs.schedule.state)
        if leftPriority != rightPriority {
            return leftPriority < rightPriority
        }

        return lhs.id.uuidString < rhs.id.uuidString
    }

    private func statePriority(_ state: CardState) -> Int {
        switch state {
        case .learning:
            return 0
        case .relearning:
            return 1
        case .review:
            return 2
        case .new:
            return 3
        }
    }

    private func normalizedCardContent(front: String, back: String, note: String) throws -> (front: String, back: String, note: String) {
        let trimmedFront = front.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBack = back.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedFront.isEmpty, !trimmedBack.isEmpty else {
            throw RepositoryError.invalidCardContent
        }
        return (trimmedFront, trimmedBack, trimmedNote.isEmpty ? "No Note" : trimmedNote)
    }

    private func suggestedImageName(from seed: String) -> String {
        let candidates = [
            "book.closed.fill",
            "brain.head.profile",
            "bolt.fill",
            "checkmark.seal.fill",
            "clock.arrow.circlepath",
            "sparkles",
            "graduationcap.fill"
        ]
        let sum = seed.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return candidates[sum % candidates.count]
    }
}
