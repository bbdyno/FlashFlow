//
//  FSRSScheduler.swift
//  FlashForge
//
//  Created by bbdyno on 2/11/26.
//

import Foundation

struct FSRSCard: Sendable, Codable {
    var stability: Double
    var difficulty: Double
    var elapsedDays: Int
    var scheduledDays: Int
    var reps: Int
    var state: CardState
    var lastReview: Date

    init(
        stability: Double = 0.4,
        difficulty: Double = 5.0,
        elapsedDays: Int = 0,
        scheduledDays: Int = 0,
        reps: Int = 0,
        state: CardState = .new,
        lastReview: Date = .now
    ) {
        self.stability = stability
        self.difficulty = difficulty
        self.elapsedDays = elapsedDays
        self.scheduledDays = scheduledDays
        self.reps = reps
        self.state = state
        self.lastReview = lastReview
    }
}

final class FSRSScheduler: @unchecked Sendable {
    private enum Constant {
        static let decay = -0.5
        static let factor = 19.0 / 81.0
        static let minimumStability = 0.1
        static let minimumDifficulty = 1.0
        static let maximumDifficulty = 10.0
    }

    let parameters: FSRSParameters

    init(parameters: FSRSParameters = .default) {
        self.parameters = parameters
    }

    func schedule(card: FSRSCard, grade: UserGrade) -> FSRSCard {
        var next = card
        next.reps += 1

        switch next.state {
        case .new:
            next = scheduleFirstReview(card: next, grade: grade)
        case .learning, .relearning:
            next = scheduleLearningLikeCard(card: next, grade: grade)
        case .review:
            next = scheduleReviewCard(card: next, grade: grade)
        }

        next.elapsedDays = 0
        next.lastReview = .now
        return next
    }

    func retrievability(stability: Double, elapsedDays: Int) -> Double {
        let s = max(Constant.minimumStability, stability)
        let t = Double(max(0, elapsedDays))
        return pow(1.0 + Constant.factor * t / s, Constant.decay)
    }

    private func scheduleFirstReview(card: FSRSCard, grade: UserGrade) -> FSRSCard {
        var next = card
        next.difficulty = initialDifficulty(for: grade)
        next.stability = initialStability(for: grade)

        switch grade {
        case .again:
            next.state = .learning
            next.scheduledDays = 0
        case .hard:
            next.state = .learning
            next.scheduledDays = 1
        case .good:
            next.state = .review
            next.scheduledDays = max(1, Int(next.stability.rounded()))
        case .easy:
            next.state = .review
            next.scheduledDays = max(2, Int((next.stability * 1.5).rounded()))
        }

        return next
    }

    private func scheduleLearningLikeCard(card: FSRSCard, grade: UserGrade) -> FSRSCard {
        var next = card

        switch grade {
        case .again:
            next.state = .relearning
            next.scheduledDays = 0
            next.stability = max(Constant.minimumStability, next.stability * 0.7)
        case .hard:
            next.state = .learning
            next.scheduledDays = 1
            next.stability = max(Constant.minimumStability, next.stability * 1.05)
        case .good:
            next.state = .review
            next.scheduledDays = max(1, Int((next.stability * 1.2).rounded()))
            next.stability = max(Constant.minimumStability, next.stability * 1.2)
        case .easy:
            next.state = .review
            next.scheduledDays = max(2, Int((next.stability * 1.6).rounded()))
            next.stability = max(Constant.minimumStability, next.stability * 1.6)
        }

        return next
    }

    private func scheduleReviewCard(card: FSRSCard, grade: UserGrade) -> FSRSCard {
        var next = card

        let elapsed = max(0, next.elapsedDays == 0 ? next.scheduledDays : next.elapsedDays)
        let r = retrievability(stability: next.stability, elapsedDays: elapsed)

        next.difficulty = updatedDifficulty(currentDifficulty: next.difficulty, grade: grade)
        next.stability = updatedStability(currentStability: next.stability, difficulty: next.difficulty, retrievability: r, grade: grade)

        if grade == .again {
            next.state = .relearning
            next.scheduledDays = 0
            return next
        }

        next.state = .review
        next.scheduledDays = nextIntervalDays(stability: next.stability, requestRetention: parameters.requestRetention)
        return next
    }

    private func updatedDifficulty(currentDifficulty: Double, grade: UserGrade) -> Double {
        // D' = D - w6 * (grade - 3), D' = w5 * D0 + (1 - w5) * D'
        let d0 = 5.0
        let delta = -w(6) * (Double(grade.rawValue) - 3.0)
        let updated = currentDifficulty + delta
        let blended = w(5) * d0 + (1.0 - w(5)) * updated
        return blended.clamped(to: Constant.minimumDifficulty...Constant.maximumDifficulty)
    }

    private func updatedStability(
        currentStability: Double,
        difficulty: Double,
        retrievability: Double,
        grade: UserGrade
    ) -> Double {
        let s = max(Constant.minimumStability, currentStability)
        let d = difficulty.clamped(to: Constant.minimumDifficulty...Constant.maximumDifficulty)
        let r = retrievability.clamped(to: 0.0...1.0)

        if grade == .again {
            // S' = w11 * D^-w12 * ((S+1)^w13 - 1) * exp(w14 * (1 - R))
            let raw = w(11) * pow(d, -w(12)) * (pow(s + 1.0, w(13)) - 1.0) * exp(w(14) * (1.0 - r))
            return max(Constant.minimumStability, raw)
        }

        // S' = S * (1 + exp(w8) * (11-D) * S^-w9 * (exp(w10 * (1-R)) - 1))
        let growth = exp(w(8)) * (11.0 - d) * pow(s, -w(9)) * (exp(w(10) * (1.0 - r)) - 1.0)
        let raw = s * (1.0 + growth)
        return max(Constant.minimumStability, raw)
    }

    private func nextIntervalDays(stability: Double, requestRetention: Double) -> Int {
        let s = max(Constant.minimumStability, stability)
        let retention = requestRetention.clamped(to: 0.7...0.99)

        // R = (1 + factor * t / S)^decay 를 t에 대해 풀어 next interval 계산
        let t = (s / Constant.factor) * (pow(retention, 1.0 / Constant.decay) - 1.0)
        return max(1, Int(t.rounded()))
    }

    private func initialDifficulty(for grade: UserGrade) -> Double {
        switch grade {
        case .again:
            return 7.5
        case .hard:
            return 6.5
        case .good:
            return 5.0
        case .easy:
            return 3.8
        }
    }

    private func initialStability(for grade: UserGrade) -> Double {
        switch grade {
        case .again:
            return 0.4
        case .hard:
            return 1.2
        case .good:
            return 2.4
        case .easy:
            return 3.6
        }
    }

    private func w(_ index1Based: Int) -> Double {
        let index = max(1, index1Based) - 1
        guard index < parameters.w.count else {
            return 1.0
        }
        return parameters.w[index]
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
