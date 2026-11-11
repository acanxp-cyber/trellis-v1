import Foundation

actor UITestAppRepository: AppRepository {
    private let data: AppData

    init() {
        let now = Date.now
        let taskOne = GrowthTask(
            title: "把本周最重要的事做完",
            area: "工作",
            createdAt: now.addingTimeInterval(-300)
        )
        let taskTwo = GrowthTask(
            title: "完成 15 分钟基础训练",
            area: "训练",
            createdAt: now.addingTimeInterval(-240)
        )
        var taskThree = GrowthTask(
            title: "整理今天留下的记录",
            area: "成长",
            createdAt: now.addingTimeInterval(-180)
        )
        taskThree.completedAt = now.addingTimeInterval(-60)

        data = AppData(
            tasks: [taskOne, taskTwo, taskThree],
            records: [
                QuickRecord(
                    text: "今天把一个拖了很久的决定写清楚了，心里轻了一点。",
                    createdAt: now.addingTimeInterval(-3600)
                ),
                QuickRecord(
                    text: "午后走了二十分钟，没有戴耳机。",
                    createdAt: now.addingTimeInterval(-86_400)
                ),
                QuickRecord(
                    text: "本周真正重要的不是做得更多，而是知道该停在哪里。",
                    createdAt: now.addingTimeInterval(-172_800)
                ),
            ],
            reviews: [
                WeeklyReview(
                    weekStart: WeeklyReview.startOfWeek(containing: now),
                    wins: "完成了核心流程，也留下了几条真实的记录。",
                    shift: "开始把注意力放回长期变化。",
                    focus: [
                        "完成第一轮测试",
                        "整理本周记录",
                        "留出真正休息的时间",
                    ],
                    completedAt: now.addingTimeInterval(-60)
                ),
            ]
        )
    }

    func load() async throws -> AppData {
        data
    }

    func save(_ data: AppData) async throws {}

    func exportData() async throws -> Data {
        try JSONEncoder().encode(data)
    }
}

