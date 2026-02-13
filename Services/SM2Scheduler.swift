//
//  SM2Scheduler.swift
//  FlashForge
//
//  Created by bbdyno on 2/11/26.
//

import Foundation

struct SM2Scheduler: Sendable {
    struct Configuration: Sendable {
        let learningSteps: [TimeInterval]
        let relearningSteps: [TimeInterval]
        let graduatingIntervalDays: Int
        let easyIntervalDays: Int
        let minimumEaseFactor: Double

        init(
            learningSteps: [TimeInterval] = [60, 600], // 1m, 10m
            relearningSteps: [TimeInterval] = [600],    // 10m
            graduatingIntervalDays: Int = 1,
            easyIntervalDays: Int = 4,
            minimumEaseFactor: Double = 1.3
        ) {
            self.learningSteps = learningSteps
            self.relearningSteps = relearningSteps
            self.graduatingIntervalDays = graduatingIntervalDays
            self.easyIntervalDays = easyIntervalDays
            self.minimumEaseFactor = minimumEaseFactor
        }
    }

    private let configuration: Configuration
    private let calendar: Calendar

    init(
        configuration: Configuration = .init(),
        calendar: Calendar = .current
    ) {
        self.configuration = configuration
        self.calendar = calendar
    }

    func schedule(card: Card, grade: UserGrade, now: Date = .now) -> Card {
        switch card.state {
        case .new, .learning:
            return scheduleLearning(card: card, grade: grade, now: now)
        case .review:
            return scheduleReview(card: card, grade: grade, now: now)
        case .relearning:
            return scheduleRelearning(card: card, grade: grade, now: now)
        }
    }

    private func scheduleLearning(card: Card, grade: UserGrade, now: Date) -> Card {
        var next = card

        switch grade {
        case .again, .hard:
            // 학습 단계 실패: 1분 스텝(Step 1)으로 복귀
            next.state = .learning
            next.stepIndex = 0
            next.interval = 0
            next.dueDate = now.addingTimeInterval(configuration.learningSteps[safe: 0] ?? 60)
        case .good:
            let currentStep = next.stepIndex ?? 0
            let targetStep = max(1, currentStep + 1)

            if targetStep >= configuration.learningSteps.count {
                // 마지막 학습 스텝 통과: review로 졸업, 1일 인터벌
                next.state = .review
                next.stepIndex = nil
                next.interval = configuration.graduatingIntervalDays
                next.dueDate = calendar.date(byAdding: .day, value: next.interval, to: now) ?? now
            } else {
                // 다음 학습 스텝(10분)으로 이동
                next.state = .learning
                next.stepIndex = targetStep
                next.interval = 0
                next.dueDate = now.addingTimeInterval(configuration.learningSteps[safe: targetStep] ?? 600)
            }
        case .easy:
            next.state = .review
            next.stepIndex = nil
            next.easeFactor = max(configuration.minimumEaseFactor, next.easeFactor + 0.15)
            next.interval = configuration.easyIntervalDays
            next.dueDate = calendar.date(byAdding: .day, value: next.interval, to: now) ?? now
        }

        return next
    }

    private func scheduleReview(card: Card, grade: UserGrade, now: Date) -> Card {
        var next = card

        if grade == .again {
            // Review 실패: lapse -> relearning으로 강등
            next.state = .relearning
            next.stepIndex = 0
            next.interval = 0
            next.easeFactor = max(configuration.minimumEaseFactor, next.easeFactor - 0.20)
            next.dueDate = now.addingTimeInterval(configuration.learningSteps[safe: 0] ?? 60)
            return next
        }

        let quality = sm2Quality(for: grade)
        next.easeFactor = updatedEaseFactor(currentEase: next.easeFactor, quality: quality)

        let proposedInterval: Double
        switch grade {
        case .hard:
            proposedInterval = max(1, Double(max(1, next.interval)) * 1.2)
        case .good:
            proposedInterval = next.interval <= 1 ? 6 : Double(next.interval) * next.easeFactor
        case .easy:
            proposedInterval = next.interval <= 1 ? 8 : Double(next.interval) * next.easeFactor * 1.30
        case .again:
            proposedInterval = 1
        }

        next.state = .review
        next.stepIndex = nil
        next.interval = max(1, Int(proposedInterval.rounded()))
        next.dueDate = calendar.date(byAdding: .day, value: next.interval, to: now) ?? now
        return next
    }

    private func scheduleRelearning(card: Card, grade: UserGrade, now: Date) -> Card {
        var next = card
        let currentStep = next.stepIndex ?? 0

        switch grade {
        case .again:
            next.state = .relearning
            next.stepIndex = 0
            next.interval = 0
            next.dueDate = now.addingTimeInterval(configuration.learningSteps[safe: 0] ?? 60)
        case .hard:
            let delay = (configuration.relearningSteps[safe: currentStep] ?? 600) * 1.5
            next.state = .relearning
            next.stepIndex = currentStep
            next.interval = 0
            next.dueDate = now.addingTimeInterval(delay)
        case .good, .easy:
            let targetStep = currentStep + 1
            if targetStep >= configuration.relearningSteps.count {
                next.state = .review
                next.stepIndex = nil
                let baseInterval = max(1, next.interval)
                next.interval = grade == .easy ? max(baseInterval, 2) : baseInterval
                next.dueDate = calendar.date(byAdding: .day, value: next.interval, to: now) ?? now
            } else {
                next.state = .relearning
                next.stepIndex = targetStep
                next.interval = 0
                next.dueDate = now.addingTimeInterval(configuration.relearningSteps[targetStep])
            }
        }

        return next
    }

    private func sm2Quality(for grade: UserGrade) -> Int {
        switch grade {
        case .again:
            return 0
        case .hard:
            return 3
        case .good:
            return 4
        case .easy:
            return 5
        }
    }

    private func updatedEaseFactor(currentEase: Double, quality: Int) -> Double {
        let q = Double(quality)
        let delta = 0.1 - (5.0 - q) * (0.08 + (5.0 - q) * 0.02)
        return max(configuration.minimumEaseFactor, currentEase + delta)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else {
            return nil
        }
        return self[index]
    }
}
