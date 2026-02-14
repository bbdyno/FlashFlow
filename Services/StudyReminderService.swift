//
//  StudyReminderService.swift
//  FlashForge
//
//  Created by bbdyno on 2/11/26.
//

import Foundation
import UserNotifications

struct StudyReminderSettings: Sendable {
    var isEnabled: Bool
    var hour: Int
    var minute: Int
}

enum StudyReminderError: LocalizedError, Equatable {
    case permissionDenied
    case schedulingFailed

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Notification permission is required to enable reminders."
        case .schedulingFailed:
            return "Could not schedule reminder notifications."
        }
    }
}

@MainActor
final class StudyReminderService {
    static let shared = StudyReminderService()

    private let notificationCenter: UNUserNotificationCenter
    private let defaults: UserDefaults
    private let calendar: Calendar

    private let enabledKey = "flashflow.reminder.enabled"
    private let hourKey = "flashflow.reminder.hour"
    private let minuteKey = "flashflow.reminder.minute"
    private let reminderIdentifier = "flashflow.study.reminder"

    init(
        notificationCenter: UNUserNotificationCenter = .current(),
        defaults: UserDefaults = .standard,
        calendar: Calendar = .current
    ) {
        self.notificationCenter = notificationCenter
        self.defaults = defaults
        self.calendar = calendar
    }

    func loadSettings() -> StudyReminderSettings {
        let hour = defaults.object(forKey: hourKey) as? Int ?? 20
        let minute = defaults.object(forKey: minuteKey) as? Int ?? 0
        let enabled = defaults.object(forKey: enabledKey) as? Bool ?? false
        return StudyReminderSettings(isEnabled: enabled, hour: hour, minute: minute)
    }

    func update(isEnabled: Bool, time: Date) async throws -> StudyReminderSettings {
        let components = calendar.dateComponents([.hour, .minute], from: time)
        let hour = components.hour ?? 20
        let minute = components.minute ?? 0

        if isEnabled {
            let granted = await requestAuthorizationIfNeeded()
            guard granted else {
                throw StudyReminderError.permissionDenied
            }
            do {
                try await scheduleReminder(hour: hour, minute: minute)
                let settings = StudyReminderSettings(isEnabled: true, hour: hour, minute: minute)
                save(settings)
                return settings
            } catch {
                CrashReporter.record(error: error, context: "StudyReminderService.update.scheduleReminder")
                throw StudyReminderError.schedulingFailed
            }
        } else {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])
            let settings = StudyReminderSettings(isEnabled: false, hour: hour, minute: minute)
            save(settings)
            return settings
        }
    }

    func disableWithoutPrompt() {
        let settings = loadSettings()
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])
        save(
            StudyReminderSettings(
                isEnabled: false,
                hour: settings.hour,
                minute: settings.minute
            )
        )
    }

    private func save(_ settings: StudyReminderSettings) {
        defaults.set(settings.isEnabled, forKey: enabledKey)
        defaults.set(settings.hour, forKey: hourKey)
        defaults.set(settings.minute, forKey: minuteKey)
    }

    private func requestAuthorizationIfNeeded() async -> Bool {
        let status = await notificationAuthorizationStatus()
        switch status {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            do {
                return try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
            } catch {
                CrashReporter.record(error: error, context: "StudyReminderService.requestAuthorizationIfNeeded")
                return false
            }
        @unknown default:
            return false
        }
    }

    private func notificationAuthorizationStatus() async -> UNAuthorizationStatus {
        await withCheckedContinuation { continuation in
            notificationCenter.getNotificationSettings { settings in
                continuation.resume(returning: settings.authorizationStatus)
            }
        }
    }

    private func scheduleReminder(hour: Int, minute: Int) async throws {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let content = UNMutableNotificationContent()
        content.title = "FlashForge Study Reminder"
        content.body = "Time to review your cards."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: reminderIdentifier, content: content, trigger: trigger)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            notificationCenter.add(request) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
