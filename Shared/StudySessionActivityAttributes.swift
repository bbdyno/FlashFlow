import ActivityKit
import Foundation

struct StudySessionActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var goalCount: Int
        var completedCount: Int
        var remainingCount: Int
        var deckTitle: String
        var syncState: StudySyncState
        var updatedAt: Date
    }

    var sessionID: String
}
