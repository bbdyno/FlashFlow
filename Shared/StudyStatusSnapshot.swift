import Foundation

enum StudySessionState: String, Codable, Hashable, Sendable {
    case idle
    case studying
    case paused
    case completed
}

enum StudySyncState: String, Codable, Hashable, Sendable {
    case idle
    case syncing
    case synced
    case failed
}

struct StudyStatusSnapshot: Codable, Hashable, Sendable {
    var dayStart: Date
    var goalCount: Int
    var completedCount: Int
    var dueLearningCount: Int
    var dueReviewCount: Int
    var selectedDeckTitle: String
    var sessionState: StudySessionState
    var syncState: StudySyncState
    var lastSyncedAt: Date?
    var updatedAt: Date

    var remainingCount: Int {
        max(0, dueLearningCount + dueReviewCount)
    }

    var progress: Double {
        if goalCount <= 0 {
            return remainingCount == 0 ? 1 : 0
        }
        let ratio = Double(completedCount) / Double(goalCount)
        return min(1, max(0, ratio))
    }

    static func empty(now: Date = .now, calendar: Calendar = .current) -> StudyStatusSnapshot {
        StudyStatusSnapshot(
            dayStart: calendar.startOfDay(for: now),
            goalCount: 0,
            completedCount: 0,
            dueLearningCount: 0,
            dueReviewCount: 0,
            selectedDeckTitle: "",
            sessionState: .idle,
            syncState: .idle,
            lastSyncedAt: nil,
            updatedAt: now
        )
    }
}

enum StudyStatusSharedStore {
    static let appGroupIdentifier = "group.com.bbdyno.app.flashFlow"
    static let snapshotKey = "FlashForge.StudyStatusSnapshot.v1"

    static func loadSnapshot() -> StudyStatusSnapshot? {
        guard let data = defaults.data(forKey: snapshotKey) else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(StudyStatusSnapshot.self, from: data)
    }

    static func saveSnapshot(_ snapshot: StudyStatusSnapshot) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(snapshot) else {
            return
        }
        defaults.set(data, forKey: snapshotKey)
    }

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    }
}
