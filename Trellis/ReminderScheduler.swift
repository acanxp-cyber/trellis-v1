import Foundation

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
