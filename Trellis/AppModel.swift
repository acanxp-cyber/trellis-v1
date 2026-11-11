import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    private(set) var data: AppData = .empty
    private(set) var isLoading = true
    var errorMessage: String?

    private let repository: any AppRepository
    private var hasLoaded = false

    init(repository: any AppRepository) {
        self.repository = repository
    }

    static func live() -> AppModel {
        if ProcessInfo.processInfo.environment["TRELLIS_UI_TEST"] == "1" {
            return AppModel(repository: UITestAppRepository())
        }

        do {
            return AppModel(repository: try LocalAppRepository.makeDefault())
        } catch {
            return AppModel(
                repository: UnavailableAppRepository(startupError: error)
            )
        }
    }

    func bootstrap() async {
        guard !hasLoaded else {
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            data = try await repository.load()
            hasLoaded = true
        } catch {
            present(error)
        }
        isLoading = false
    }

    @discardableResult
    func addTask(title: String) async -> Bool {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return false
        }

        var next = data
        next.tasks.append(GrowthTask(title: trimmed))
        return await commit(next)
    }

    func toggleTask(id: GrowthTask.ID) async {
        var next = data
        guard let index = next.tasks.firstIndex(where: { $0.id == id }) else {
            return
        }

        if next.tasks[index].completedAt == nil {
            next.tasks[index].completedAt = .now
        } else {
            next.tasks[index].completedAt = nil
        }
        await commit(next)
    }

    @discardableResult
    func addScheduledTasks(_ drafts: [VoiceTaskDraft]) async -> Bool {
        let tasks = drafts.compactMap { draft -> GrowthTask? in
            let title = draft.title.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            guard !title.isEmpty else {
                return nil
            }
            return GrowthTask(
                id: draft.id,
                title: title,
                area: "日程",
                scheduledAt: draft.scheduledAt,
                reminderAt: draft.reminderAt
            )
        }
        guard !tasks.isEmpty else {
            return false
        }

        var next = data
        next.tasks.append(contentsOf: tasks)
        return await commit(next)
    }

    @discardableResult
    func addRecord(text: String) async -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return false
        }

        var next = data
        next.records.append(QuickRecord(text: trimmed))
        return await commit(next)
    }

    @discardableResult
    func completeReview(
        wins: String,
        shift: String,
        focus: [String]
    ) async -> Bool {
        let trimmedFocus = focus.map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard WeeklyReview.isValid(wins: wins, focus: trimmedFocus) else {
            return false
        }

        let weekStart = WeeklyReview.startOfWeek(containing: .now)
        let review = WeeklyReview(
            weekStart: weekStart,
            wins: wins.trimmingCharacters(in: .whitespacesAndNewlines),
            shift: shift.trimmingCharacters(in: .whitespacesAndNewlines),
            focus: trimmedFocus
        )

        var next = data
        next.reviews.removeAll { existing in
            Calendar.trellis.isDate(
                existing.weekStart,
                inSameDayAs: weekStart
            )
        }
        next.reviews.append(review)
        return await commit(next)
    }

    func exportData() async -> Data? {
        do {
            return try await repository.exportData()
        } catch {
            present(error)
            return nil
        }
    }

    func clearError() {
        errorMessage = nil
    }

    var currentWeekReview: WeeklyReview? {
        let start = WeeklyReview.startOfWeek(containing: .now)
        return data.reviews.first {
            Calendar.trellis.isDate($0.weekStart, inSameDayAs: start)
        }
    }

    var openTasks: [GrowthTask] {
        data.tasks
            .filter { !$0.isCompleted }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var completedTaskCount: Int {
        data.tasks.filter(\.isCompleted).count
    }

    @discardableResult
    private func commit(_ next: AppData) async -> Bool {
        do {
            try await repository.save(next)
            data = next
            return true
        } catch {
            present(error)
            return false
        }
    }

    private func present(_ error: Error) {
        errorMessage = (error as? LocalizedError)?.errorDescription
            ?? "操作失败，请稍后重试。"
    }
}

