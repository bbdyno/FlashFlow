import ActivityKit
import SharedResources
import SwiftUI
import WidgetKit

private enum WidgetText {
    static var title: String { localized("widget.today.title", fallback: "Today's Study") }
    static var noDeck: String { localized("widget.deck.none", fallback: "All Decks") }
    static var remaining: String { localized("widget.remaining", fallback: "Remaining") }
    static var completed: String { localized("widget.completed", fallback: "Completed") }
    static var liveLabel: String { localized("live.label", fallback: "Studying") }
    static var doneShort: String { localized("live.done_short", fallback: "Done") }
    static var leftShort: String { localized("live.left_short", fallback: "Left") }
    static var syncIdle: String { localized("live.sync.idle", fallback: "Idle") }
    static var syncing: String { localized("live.sync.syncing", fallback: "Syncing") }
    static var synced: String { localized("live.sync.synced", fallback: "Synced") }
    static var syncFailed: String { localized("live.sync.failed", fallback: "Sync Failed") }
    static var complete: String { localized("live.complete", fallback: "Completed") }

    static func localized(_ key: String, fallback: String) -> String {
        SharedL10n.localized(key, fallback: fallback)
    }
}

private func syncStatusText(for state: StudySyncState) -> String {
    switch state {
    case .idle:
        return WidgetText.syncIdle
    case .syncing:
        return WidgetText.syncing
    case .synced:
        return WidgetText.synced
    case .failed:
        return WidgetText.syncFailed
    }
}

private func progressRatio(completedCount: Int, goalCount: Int, remainingCount: Int) -> Double {
    if goalCount <= 0 {
        return remainingCount == 0 ? 1 : 0
    }
    return min(1, max(0, Double(completedCount) / Double(goalCount)))
}

private func progressPercentText(completedCount: Int, goalCount: Int, remainingCount: Int) -> String {
    let ratio = progressRatio(completedCount: completedCount, goalCount: goalCount, remainingCount: remainingCount)
    return "\(Int((ratio * 100).rounded()))%"
}

private struct StudyStatusEntry: TimelineEntry {
    let date: Date
    let snapshot: StudyStatusSnapshot
}

private struct StudyStatusProvider: TimelineProvider {
    func placeholder(in context: Context) -> StudyStatusEntry {
        StudyStatusEntry(date: .now, snapshot: sampleSnapshot())
    }

    func getSnapshot(in context: Context, completion: @escaping (StudyStatusEntry) -> Void) {
        let snapshot = StudyStatusSharedStore.loadSnapshot() ?? sampleSnapshot()
        completion(StudyStatusEntry(date: .now, snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StudyStatusEntry>) -> Void) {
        let snapshot = StudyStatusSharedStore.loadSnapshot() ?? sampleSnapshot()
        let entry = StudyStatusEntry(date: .now, snapshot: snapshot)
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }

    private func sampleSnapshot() -> StudyStatusSnapshot {
        StudyStatusSnapshot(
            dayStart: Calendar.current.startOfDay(for: .now),
            goalCount: 40,
            completedCount: 14,
            dueLearningCount: 9,
            dueReviewCount: 17,
            selectedDeckTitle: "Core Deck",
            sessionState: .studying,
            syncState: .synced,
            lastSyncedAt: .now,
            updatedAt: .now
        )
    }
}

private struct StudyStatusCard: View {
    let snapshot: StudyStatusSnapshot
    let compact: Bool

    private var deckTitle: String {
        snapshot.selectedDeckTitle.isEmpty ? WidgetText.noDeck : snapshot.selectedDeckTitle
    }

    private var progressValue: Double {
        snapshot.progress
    }

    private var progressText: String {
        if snapshot.goalCount <= 0 {
            return "0%"
        }
        return "\(Int((progressValue * 100).rounded()))%"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 6 : 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(WidgetText.title)
                    .font(compact ? .caption : .headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Spacer(minLength: 6)
                Text(progressText)
                    .font(compact ? .caption2 : .subheadline)
                    .foregroundStyle(Color.white.opacity(0.78))
            }

            Text(deckTitle)
                .font(compact ? .caption : .subheadline)
                .foregroundStyle(Color.white.opacity(0.72))
                .lineLimit(1)

            ProgressView(value: progressValue)
                .progressViewStyle(.linear)
                .tint(Color(red: 0.41, green: 0.84, blue: 0.98))

            HStack(spacing: compact ? 8 : 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(WidgetText.completed)
                        .font(.caption2)
                        .foregroundStyle(Color.white.opacity(0.72))
                    Text("\(snapshot.completedCount)")
                        .font(compact ? .callout : .title3)
                        .fontWeight(.bold)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(WidgetText.remaining)
                        .font(.caption2)
                        .foregroundStyle(Color.white.opacity(0.72))
                    Text("\(snapshot.remainingCount)")
                        .font(compact ? .callout : .title3)
                        .fontWeight(.bold)
                }
                Spacer(minLength: 0)
            }
        }
        .foregroundStyle(.white)
        .padding(compact ? 10 : 12)
        .background(
            RoundedRectangle(cornerRadius: compact ? 15 : 17, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.05, green: 0.11, blue: 0.19),
                            Color(red: 0.09, green: 0.19, blue: 0.31),
                            Color(red: 0.12, green: 0.24, blue: 0.40)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: compact ? 15 : 17, style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 0.8)
                )
        )
        .containerBackground(for: .widget) {
            Color.black
        }
    }
}

struct StudyStatusWidget: Widget {
    private let kind = "StudyStatusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StudyStatusProvider()) { entry in
            StudyStatusWidgetView(entry: entry)
                .environment(\.colorScheme, .dark)
        }
        .configurationDisplayName(WidgetText.localized("widget.config.title", fallback: "Today's Study"))
        .description(WidgetText.localized("widget.config.description", fallback: "Quick glance at your learning progress and remaining cards."))
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

private struct StudyStatusWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: StudyStatusEntry

    var body: some View {
        switch family {
        case .systemSmall:
            StudyStatusCard(snapshot: entry.snapshot, compact: true)
        case .systemMedium:
            StudyStatusCard(snapshot: entry.snapshot, compact: false)
        case .accessoryRectangular:
            accessoryView
        default:
            StudyStatusCard(snapshot: entry.snapshot, compact: true)
        }
    }

    private var accessoryView: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                Text(WidgetText.title)
                    .font(.caption2)
                    .fontWeight(.semibold)
                Text(entry.snapshot.selectedDeckTitle.isEmpty ? WidgetText.noDeck : entry.snapshot.selectedDeckTitle)
                    .font(.caption2)
                    .foregroundStyle(Color.white.opacity(0.72))
                    .lineLimit(1)
            }
            Spacer(minLength: 6)
            Text("\(entry.snapshot.completedCount)/\(max(entry.snapshot.goalCount, entry.snapshot.completedCount))")
                .font(.caption)
                .fontWeight(.bold)
        }
        .foregroundStyle(.white)
    }
}

struct StudySessionLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: StudySessionActivityAttributes.self) { context in
            let ratio = progressRatio(
                completedCount: context.state.completedCount,
                goalCount: context.state.goalCount,
                remainingCount: context.state.remainingCount
            )
            let ratioText = progressPercentText(
                completedCount: context.state.completedCount,
                goalCount: context.state.goalCount,
                remainingCount: context.state.remainingCount
            )
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.state.remainingCount == 0 ? WidgetText.complete : WidgetText.liveLabel)
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text(context.state.deckTitle)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                    }
                    Spacer()
                    Text(syncStatusText(for: context.state.syncState))
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.14), in: Capsule())
                        .foregroundStyle(Color.white.opacity(0.8))
                }
                .padding(.top, 8)

                HStack(alignment: .lastTextBaseline, spacing: 8) {
                    Text(ratioText)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                    Text("\(context.state.completedCount)/\(max(context.state.goalCount, context.state.completedCount))")
                        .font(.subheadline)
                        .foregroundStyle(Color.white.opacity(0.78))
                }

                ProgressView(value: ratio)
                    .progressViewStyle(.linear)
                    .tint(Color(red: 0.41, green: 0.84, blue: 0.98))
                    .padding(.bottom, 8)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.05, green: 0.11, blue: 0.19),
                                Color(red: 0.09, green: 0.19, blue: 0.31),
                                Color(red: 0.12, green: 0.24, blue: 0.40)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.14), lineWidth: 0.8)
                    )
            )
            .padding(.horizontal, 4)
            .padding(.vertical, 10)
            .environment(\.colorScheme, .dark)
            .activityBackgroundTint(Color(red: 0.07, green: 0.13, blue: 0.21))
            .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            let ratio = progressRatio(
                completedCount: context.state.completedCount,
                goalCount: context.state.goalCount,
                remainingCount: context.state.remainingCount
            )
            let ratioText = progressPercentText(
                completedCount: context.state.completedCount,
                goalCount: context.state.goalCount,
                remainingCount: context.state.remainingCount
            )
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Label("\(context.state.completedCount)", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .fontWeight(.bold)
                        Text(WidgetText.doneShort)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Label("\(context.state.remainingCount)", systemImage: "clock.fill")
                            .font(.headline)
                            .fontWeight(.bold)
                            .labelStyle(.titleAndIcon)
                        Text(WidgetText.leftShort)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.deckTitle)
                        .font(.caption)
                        .lineLimit(1)
                        .padding(.vertical, 2)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        ProgressView(value: ratio)
                        HStack {
                            Text(ratioText)
                                .font(.caption)
                                .fontWeight(.semibold)
                            Spacer()
                            Text(syncStatusText(for: context.state.syncState))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 4)
                }
            } compactLeading: {
                Label("\(context.state.completedCount)", systemImage: "checkmark.circle.fill")
                    .font(.caption2)
            } compactTrailing: {
                Label("\(context.state.remainingCount)", systemImage: "clock.fill")
                    .font(.caption2)
            } minimal: {
                Text(ratioText)
                    .font(.caption2)
            }
        }
    }

}
