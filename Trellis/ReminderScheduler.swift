import Foundation
import UserNotifications

struct ReminderPlan: Equatable, Sendable {
    let taskID: UUID
    let title: String
    let fireDate: Date
}

struct ReminderPlanner {
    func plans(for tasks: [GrowthTask], now: Date = .now) -> [ReminderPlan] {
        tasks.compactMap { task in
            guard
                let reminderAt = task.reminderAt,
                reminderAt > now
            else {
                return nil
            }
            return ReminderPlan(
                taskID: task.id,
                title: task.title,
                fireDate: reminderAt
            )
        }
        .sorted { $0.fireDate < $1.fireDate }
    }
}

@MainActor
final class LocalReminderScheduler {
    private let center = UNUserNotificationCenter.current()
    private let planner = ReminderPlanner()

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
        } catch {
            return false
        }
    }

    func schedule(_ tasks: [GrowthTask], now: Date = .now) async -> Int {
        let plans = planner.plans(for: tasks, now: now)
        var scheduledCount = 0

        for plan in plans {
            let content = UNMutableNotificationContent()
            content.title = "日程提醒"
            content.body = plan.title
            content.sound = .default
            content.threadIdentifier = "task-reminders"

            let components = Calendar.trellis.dateComponents(
                [.year, .month, .day, .hour, .minute],
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

            do {
                try await center.add(request)
                scheduledCount += 1
            } catch {
                continue
            }
        }

        return scheduledCount
    }
}
