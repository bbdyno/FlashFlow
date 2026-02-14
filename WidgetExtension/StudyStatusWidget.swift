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

private enum WidgetPalette {
    static let backgroundTop = Color(red: 0.04, green: 0.10, blue: 0.19)
    static let backgroundMid = Color(red: 0.08, green: 0.18, blue: 0.33)
    static let backgroundBottom = Color(red: 0.03, green: 0.07, blue: 0.14)
    static let highlight = Color(red: 0.35, green: 0.84, blue: 0.95).opacity(0.16)
    static let glow = Color(red: 0.22, green: 0.80, blue: 0.87).opacity(0.22)
    static let cardBorder = Color.white.opacity(0.16)

    static let textPrimary = Color.white.opacity(0.96)
    static let textSecondary = Color.white.opacity(0.74)

    static let track = Color.white.opacity(0.18)
    static let accentStart = Color(red: 0.28, green: 0.74, blue: 0.86)
    static let accentEnd = Color(red: 0.22, green: 0.80, blue: 0.87)

    static let surface = Color.white.opacity(0.08)
    static let surfaceBorder = Color.white.opacity(0.13)
    static let badgeFill = Color.white.opacity(0.11)
    static let badgeBorder = Color.white.opacity(0.14)
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

private func syncStatusIcon(for state: StudySyncState) -> String {
    switch state {
    case .idle:
        return "pause.circle.fill"
    case .syncing:
        return "arrow.triangle.2.circlepath.circle.fill"
    case .synced:
        return "checkmark.circle.fill"
    case .failed:
        return "exclamationmark.triangle.fill"
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

private func goalBaselineCount(goalCount: Int, completedCount: Int) -> Int {
    max(goalCount, completedCount)
}

private func completionText(completedCount: Int, goalCount: Int) -> String {
    "\(completedCount)/\(goalBaselineCount(goalCount: goalCount, completedCount: completedCount))"
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

private struct WidgetCardBackground: View {
    var body: some View {
        ContainerRelativeShape()
            .fill(
                LinearGradient(
                    colors: [
                        WidgetPalette.backgroundTop,
                        WidgetPalette.backgroundMid,
                        WidgetPalette.backgroundBottom
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(alignment: .topTrailing) {
                Circle()
                    .fill(WidgetPalette.highlight)
                    .frame(width: 120, height: 120)
                    .blur(radius: 24)
                    .offset(x: 34, y: -36)
            }
            .overlay(alignment: .bottomLeading) {
                Circle()
                    .fill(WidgetPalette.glow)
                    .frame(width: 96, height: 96)
                    .blur(radius: 20)
                    .offset(x: -28, y: 32)
            }
            .overlay(
                ContainerRelativeShape()
                    .stroke(WidgetPalette.cardBorder, lineWidth: 0.8)
            )
    }
}

private struct WidgetProgressBar: View {
    let value: Double
    let height: CGFloat

    private var clampedValue: Double {
        min(1, max(0, value))
    }

    var body: some View {
        GeometryReader { proxy in
            let fillWidth = proxy.size.width * clampedValue
            let minimumVisibleWidth = min(proxy.size.width, 8)
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(WidgetPalette.track)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [WidgetPalette.accentStart, WidgetPalette.accentEnd],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: clampedValue == 0 ? 0 : max(minimumVisibleWidth, fillWidth))
            }
        }
        .frame(height: height)
    }
}

private struct WidgetMetricCard: View {
    let title: String
    let value: Int
    let systemImage: String
    let compact: Bool

    var body: some View {
        Group {
            if compact {
                HStack(spacing: 5) {
                    Label(title, systemImage: systemImage)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .foregroundStyle(WidgetPalette.textSecondary)
                    Spacer(minLength: 4)
                    Text(value.formatted())
                        .font(.callout)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                        .foregroundStyle(WidgetPalette.textPrimary)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Label(title, systemImage: systemImage)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .foregroundStyle(WidgetPalette.textSecondary)
                    Text(value.formatted())
                        .font(.title3)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                        .foregroundStyle(WidgetPalette.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, compact ? 7 : 10)
        .padding(.vertical, compact ? 4 : 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: compact ? 9 : 12, style: .continuous)
                .fill(WidgetPalette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: compact ? 9 : 12, style: .continuous)
                .stroke(WidgetPalette.surfaceBorder, lineWidth: 0.8)
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
        progressPercentText(
            completedCount: snapshot.completedCount,
            goalCount: snapshot.goalCount,
            remainingCount: snapshot.remainingCount
        )
    }

    private var completedGoalText: String {
        completionText(completedCount: snapshot.completedCount, goalCount: snapshot.goalCount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 7 : 9) {
            header
            progressSection
            HStack(spacing: compact ? 5 : 7) {
                WidgetMetricCard(
                    title: WidgetText.completed,
                    value: snapshot.completedCount,
                    systemImage: "checkmark.circle.fill",
                    compact: compact
                )
                WidgetMetricCard(
                    title: WidgetText.remaining,
                    value: snapshot.remainingCount,
                    systemImage: "clock.fill",
                    compact: compact
                )
            }
        }
        .padding(.horizontal, compact ? 10 : 12)
        .padding(.vertical, compact ? 12 : 13)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            WidgetCardBackground()
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 7) {
            VStack(alignment: .leading, spacing: compact ? 1 : 2) {
                Text(WidgetText.title)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(WidgetPalette.textSecondary)
                    .lineLimit(1)
                Text(deckTitle)
                    .font(compact ? .footnote : .subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(WidgetPalette.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Spacer(minLength: 6)

            if !compact {
                syncBadge
            }
        }
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: compact ? 4 : 5) {
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(progressText)
                    .font(.system(size: compact ? 20 : 26, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(WidgetPalette.textPrimary)
                Text(completedGoalText)
                    .font(compact ? .caption2 : .caption)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .foregroundStyle(WidgetPalette.textSecondary)
                Spacer(minLength: 0)
            }
            WidgetProgressBar(value: progressValue, height: compact ? 4 : 5)
        }
    }

    private var syncBadge: some View {
        Label(syncStatusText(for: snapshot.syncState), systemImage: syncStatusIcon(for: snapshot.syncState))
            .font(.caption2)
            .fontWeight(.medium)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .foregroundStyle(WidgetPalette.textSecondary)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(WidgetPalette.badgeFill)
            )
            .overlay(
                Capsule()
                    .stroke(WidgetPalette.badgeBorder, lineWidth: 0.8)
            )
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
        .description(
            WidgetText.localized(
                "widget.config.description",
                fallback: "Quick glance at your learning progress and remaining cards."
            )
        )
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
        let snapshot = entry.snapshot
        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(snapshot.selectedDeckTitle.isEmpty ? WidgetText.noDeck : snapshot.selectedDeckTitle)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Spacer(minLength: 4)
                Text(
                    progressPercentText(
                        completedCount: snapshot.completedCount,
                        goalCount: snapshot.goalCount,
                        remainingCount: snapshot.remainingCount
                    )
                )
                .font(.caption2)
                .fontWeight(.semibold)
                .monospacedDigit()
                .foregroundStyle(.secondary)
            }

            ProgressView(value: snapshot.progress)
                .progressViewStyle(.linear)
                .tint(WidgetPalette.accentEnd)

            HStack(spacing: 10) {
                Label(snapshot.completedCount.formatted(), systemImage: "checkmark.circle.fill")
                    .lineLimit(1)
                Spacer(minLength: 8)
                Label(snapshot.remainingCount.formatted(), systemImage: "clock.fill")
                    .lineLimit(1)
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
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
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(context.state.remainingCount == 0 ? WidgetText.complete : WidgetText.liveLabel)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(WidgetPalette.textSecondary)
                        Text(context.state.deckTitle)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .foregroundStyle(WidgetPalette.textPrimary)
                    }
                    Spacer(minLength: 8)
                    Label(
                        syncStatusText(for: context.state.syncState),
                        systemImage: syncStatusIcon(for: context.state.syncState)
                    )
                        .font(.caption2)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(WidgetPalette.badgeFill, in: Capsule())
                        .overlay(
                            Capsule()
                                .stroke(WidgetPalette.badgeBorder, lineWidth: 0.8)
                        )
                        .foregroundStyle(WidgetPalette.textSecondary)
                }

                HStack(alignment: .lastTextBaseline, spacing: 8) {
                    Text(ratioText)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(WidgetPalette.textPrimary)
                    Text(
                        completionText(
                            completedCount: context.state.completedCount,
                            goalCount: context.state.goalCount
                        )
                    )
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .foregroundStyle(WidgetPalette.textSecondary)
                }

                WidgetProgressBar(value: ratio, height: 7)

                HStack(spacing: 8) {
                    WidgetMetricCard(
                        title: WidgetText.completed,
                        value: context.state.completedCount,
                        systemImage: "checkmark.circle.fill",
                        compact: true
                    )
                    WidgetMetricCard(
                        title: WidgetText.remaining,
                        value: context.state.remainingCount,
                        systemImage: "clock.fill",
                        compact: true
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                WidgetPalette.backgroundTop,
                                WidgetPalette.backgroundMid,
                                WidgetPalette.backgroundBottom
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(WidgetPalette.cardBorder, lineWidth: 0.8)
                    )
            )
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
            .environment(\.colorScheme, .dark)
            .activityBackgroundTint(WidgetPalette.backgroundTop)
            .activitySystemActionForegroundColor(WidgetPalette.textPrimary)
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
                        Label {
                            Text(context.state.completedCount.formatted())
                                .monospacedDigit()
                        } icon: {
                            Image(systemName: "checkmark.circle.fill")
                        }
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
                        Label {
                            Text(context.state.remainingCount.formatted())
                                .monospacedDigit()
                        } icon: {
                            Image(systemName: "clock.fill")
                        }
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
                    Text(context.state.deckTitle.isEmpty ? WidgetText.noDeck : context.state.deckTitle)
                        .font(.caption)
                        .lineLimit(1)
                        .padding(.vertical, 2)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        ProgressView(value: ratio)
                            .tint(WidgetPalette.accentEnd)
                        HStack {
                            Text(ratioText)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .monospacedDigit()
                            Spacer()
                            Label(
                                syncStatusText(for: context.state.syncState),
                                systemImage: syncStatusIcon(for: context.state.syncState)
                            )
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .padding(.top, 4)
                }
            } compactLeading: {
                Label {
                    Text(context.state.completedCount.formatted())
                        .monospacedDigit()
                } icon: {
                    Image(systemName: "checkmark.circle.fill")
                }
                    .font(.caption2)
            } compactTrailing: {
                Label {
                    Text(context.state.remainingCount.formatted())
                        .monospacedDigit()
                } icon: {
                    Image(systemName: "clock.fill")
                }
                    .font(.caption2)
            } minimal: {
                Text(ratioText)
                    .font(.caption2)
                    .monospacedDigit()
            }
            .keylineTint(WidgetPalette.accentEnd)
        }
    }

}
