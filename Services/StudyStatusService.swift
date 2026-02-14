import Foundation
#if canImport(ActivityKit)
import ActivityKit
#endif
#if canImport(WidgetKit)
import WidgetKit
#endif

@MainActor
final class StudyStatusService {
    static let shared = StudyStatusService()

    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func updateStudyProgress(
        counts: QueueDueCounts,
        completedCount: Int,
        selectedDeckTitle: String?,
        hasCurrentCard: Bool,
        now: Date = .now
    ) {
        var snapshot = normalizedSnapshot(for: now)
        let remaining = max(0, counts.total)
        let completed = max(0, completedCount)

        snapshot.goalCount = max(remaining + completed, remaining)
        snapshot.completedCount = completed
        snapshot.dueLearningCount = max(0, counts.learning)
        snapshot.dueReviewCount = max(0, counts.review)
        snapshot.selectedDeckTitle = selectedDeckTitle ?? ""
        snapshot.sessionState = sessionState(for: remaining, hasCurrentCard: hasCurrentCard)
        snapshot.updatedAt = now

        saveAndRefresh(snapshot)
    }

    func updateSyncStatus(
        isSyncing: Bool,
        lastSyncedAt: Date?,
        hasError: Bool,
        now: Date = .now
    ) {
        var snapshot = normalizedSnapshot(for: now)

        if isSyncing {
            snapshot.syncState = .syncing
        } else if hasError {
            snapshot.syncState = .failed
        } else if lastSyncedAt != nil {
            snapshot.syncState = .synced
        } else {
            snapshot.syncState = .idle
        }

        if let lastSyncedAt {
            snapshot.lastSyncedAt = lastSyncedAt
        }
        snapshot.updatedAt = now

        saveAndRefresh(snapshot)
    }

    private func normalizedSnapshot(for now: Date) -> StudyStatusSnapshot {
        let base = StudyStatusSharedStore.loadSnapshot() ?? StudyStatusSnapshot.empty(now: now, calendar: calendar)
        guard calendar.isDate(base.dayStart, inSameDayAs: now) else {
            return StudyStatusSnapshot.empty(now: now, calendar: calendar)
        }
        return base
    }

    private func sessionState(for remaining: Int, hasCurrentCard: Bool) -> StudySessionState {
        if remaining == 0 {
            return .completed
        }
        return hasCurrentCard ? .studying : .idle
    }

    private func saveAndRefresh(_ snapshot: StudyStatusSnapshot) {
        StudyStatusSharedStore.saveSnapshot(snapshot)
        reloadWidgets()
        Task {
            await updateLiveActivity(with: snapshot)
        }
    }

    private func reloadWidgets() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    private func updateLiveActivity(with snapshot: StudyStatusSnapshot) async {
        #if canImport(ActivityKit)
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            return
        }

        let deckTitle = snapshot.selectedDeckTitle.isEmpty ? "Study" : snapshot.selectedDeckTitle
        let contentState = StudySessionActivityAttributes.ContentState(
            goalCount: snapshot.goalCount,
            completedCount: snapshot.completedCount,
            remainingCount: snapshot.remainingCount,
            deckTitle: deckTitle,
            syncState: snapshot.syncState,
            updatedAt: snapshot.updatedAt
        )
        let content = ActivityContent(state: contentState, staleDate: snapshot.updatedAt.addingTimeInterval(30 * 60))

        if snapshot.sessionState == .idle || snapshot.sessionState == .paused {
            for activity in Activity<StudySessionActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            return
        }

        if let activity = Activity<StudySessionActivityAttributes>.activities.first {
            await activity.update(content)
            if snapshot.sessionState == .completed {
                await activity.end(content, dismissalPolicy: .default)
            }
            return
        }

        if snapshot.sessionState == .studying {
            do {
                let attributes = StudySessionActivityAttributes(sessionID: UUID().uuidString)
                _ = try Activity.request(attributes: attributes, content: content, pushType: nil)
            } catch {
                CrashReporter.record(error: error, context: "StudyStatusService.updateLiveActivity.request")
                return
            }
        }
        #endif
    }
}
