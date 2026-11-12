import AlarmKit
import Foundation
import SwiftUI
import UserNotifications

struct ReminderPlan: Equatable, Sendable {
    let taskID: UUID
    let title: String
    let fireDate: Date
}

struct ReminderPlanner {
    func plans(for tasks: [GrowthTask], now: Date = .now) -> [ReminderPlan] {
        tasks.compactMap { task in
            guard let reminderAt = task.reminderAt else {
                return nil
            }

            // A minute-granularity DatePicker can be saved a few seconds after
            // the chosen minute. Treat the last minute as "now" instead of
            // silently dropping the reminder.
            guard reminderAt > now.addingTimeInterval(-60) else {
                return nil
            }
            return ReminderPlan(
                taskID: task.id,
                title: task.title,
                fireDate: max(
                    reminderAt,
                    now.addingTimeInterval(1)
                )
            )
        }
        .sorted { $0.fireDate < $1.fireDate }
    }
}

enum ReminderChannel: String, Sendable {
    case alarmKit
    case notification
    case unavailable
}

struct ReminderScheduleResult: Equatable, Sendable {
    let channel: ReminderChannel
    let eligibleCount: Int
    let scheduledCount: Int
    let failedCount: Int

    var isAuthorized: Bool {
        channel != .unavailable
    }
}

@MainActor
final class LocalReminderScheduler {
    private let center = UNUserNotificationCenter.current()
    private let planner = ReminderPlanner()

    func schedule(_ tasks: [GrowthTask], now: Date = .now) async -> ReminderScheduleResult {
        let plans = planner.plans(for: tasks, now: now)
        guard !plans.isEmpty else {
            return ReminderScheduleResult(
                channel: .notification,
                eligibleCount: 0,
                scheduledCount: 0,
                failedCount: 0
            )
        }

        let channel = await requestAuthorization()
        guard channel != .unavailable else {
            return ReminderScheduleResult(
                channel: .unavailable,
                eligibleCount: plans.count,
                scheduledCount: 0,
                failedCount: plans.count
            )
        }

        var scheduledCount = 0
        var failedCount = 0
        for plan in plans {
            do {
                switch channel {
                case .alarmKit:
                    if #available(iOS 26.0, *) {
                        try await scheduleAlarm(plan)
                    } else {
                        throw ReminderSchedulingError.alarmKitUnavailable
                    }
                case .notification:
                    try await scheduleNotification(plan)
                case .unavailable:
                    break
                }
                scheduledCount += 1
            } catch {
                failedCount += 1
            }
        }

        return ReminderScheduleResult(
            channel: channel,
            eligibleCount: plans.count,
            scheduledCount: scheduledCount,
            failedCount: failedCount
        )
    }

    func cancel(taskIDs: [UUID]) {
        let identifiers = taskIDs.map {
            "task-reminder-\($0.uuidString)"
        }
        center.removePendingNotificationRequests(
            withIdentifiers: identifiers
        )
        center.removeDeliveredNotifications(
            withIdentifiers: identifiers
        )

        if #available(iOS 26.0, *) {
            for taskID in taskIDs {
                try? AlarmManager.shared.cancel(id: taskID)
            }
        }
    }

    private func requestAuthorization() async -> ReminderChannel {
        if #available(iOS 26.0, *) {
            do {
                let state: AlarmManager.AuthorizationState
                if AlarmManager.shared.authorizationState == .notDetermined {
                    state = try await AlarmManager.shared.requestAuthorization()
                } else {
                    state = AlarmManager.shared.authorizationState
                }
                if state == .authorized {
                    return .alarmKit
                }
            } catch {
                // Fall through to a normal notification when AlarmKit cannot
                // be used. The UI reports which channel was actually used.
            }
        }

        do {
            let granted = try await center.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            return granted ? .notification : .unavailable
        } catch {
            return .unavailable
        }
    }

    @available(iOS 26.0, *)
    private func scheduleAlarm(_ plan: ReminderPlan) async throws {
        try? AlarmManager.shared.cancel(id: plan.taskID)

        let title = LocalizedStringResource(stringLiteral: plan.title)
        let snoozeButton = AlarmButton(
            text: "稍后 5 分钟",
            textColor: .white,
            systemImageName: "zzz"
        )
        let alert: AlarmPresentation.Alert
        if #available(iOS 26.1, *) {
            alert = AlarmPresentation.Alert(
                title: title,
                secondaryButton: snoozeButton,
                secondaryButtonBehavior: .countdown
            )
        } else {
            alert = AlarmPresentation.Alert(
                title: title,
                stopButton: AlarmButton(
                    text: "停止",
                    textColor: .white,
                    systemImageName: "stop.fill"
                ),
                secondaryButton: snoozeButton,
                secondaryButtonBehavior: .countdown
            )
        }
        let presentation = AlarmPresentation(alert: alert)
        let attributes = AlarmAttributes(
            presentation: presentation,
            metadata: nil as TrellisAlarmMetadata?,
            tintColor: .orange
        )
        let countdown = Alarm.CountdownDuration(
            preAlert: nil,
            postAlert: 5 * 60
        )
        let configuration = AlarmManager.AlarmConfiguration(
            countdownDuration: countdown,
            schedule: .fixed(plan.fireDate),
            attributes: attributes,
            sound: .default
        )

        _ = try await AlarmManager.shared.schedule(
            id: plan.taskID,
            configuration: configuration
        )
    }

    private func scheduleNotification(_ plan: ReminderPlan) async throws {
        let content = UNMutableNotificationContent()
        content.title = "日程提醒"
        content.body = plan.title
        content.sound = .default
        content.threadIdentifier = "task-reminders"

        let components = Calendar.trellis.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: plan.fireDate
        )
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: "task-reminder-\(plan.taskID.uuidString)",
            content: content,
            trigger: trigger
        )
        try await center.add(request)
    }
}

private struct TrellisAlarmMetadata: AlarmMetadata {}

private enum ReminderSchedulingError: Error {
    case alarmKitUnavailable
}
