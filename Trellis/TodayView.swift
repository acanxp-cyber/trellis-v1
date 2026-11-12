import SwiftUI

struct TodayView: View {
    @Environment(AppModel.self) private var model
    @State private var isAddingTask = false
    @State private var showsClearConfirmation = false
    @State private var clearReceipt: ClearPlanReceipt?
    @State private var scheduler = LocalReminderScheduler()

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    header

                    HStack(spacing: 12) {
                        StatTile(
                            value: "\(model.openTasks.count)",
                            label: "待完成"
                        )
                        StatTile(
                            value: "\(model.completedTaskCount)",
                            label: "已完成"
                        )
                        StatTile(
                            value: "\(model.data.records.count)",
                            label: "记录"
                        )
                    }

                    sectionTitle("今天")

                    if model.openTasks.isEmpty {
                        EmptyState(
                            title: "今天还没有安排",
                            detail: "添加一件真正重要的小事。"
                        )
                    } else {
                        ForEach(model.openTasks) { task in
                            TaskRow(task: task) {
                                Task {
                                    await model.toggleTask(id: task.id)
                                }
                            }
                        }
                    }

                    if model.completedTaskCount > 0 {
                        completedSection
                    }
                }
                .padding(22)
            }
            .background(Color.trellisInk.ignoresSafeArea())
            .navigationTitle("今天")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .destructive) {
                        showsClearConfirmation = true
                    } label: {
                        Label("清零今天", systemImage: "trash")
                    }
                    .accessibilityIdentifier("clear-today")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isAddingTask = true
                    } label: {
                        Label("新建任务", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAddingTask) {
                NewTaskSheet { title in
                    await model.addTask(title: title)
                }
                .presentationDetents([.medium])
            }
            .confirmationDialog(
                "清零今天的计划？",
                isPresented: $showsClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("清零未完成计划", role: .destructive) {
                    Task {
                        await clearToday()
                    }
                }
            } message: {
                Text("只清除今天尚未完成的计划并取消闹钟。已完成任务、记录和回顾都会保留。")
            }
            .safeAreaInset(edge: .bottom) {
                if let clearReceipt {
                    HStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("今天的计划已清零")
                                .font(.callout.weight(.semibold))
                            Text("历史记录和已完成任务仍然保留")
                                .font(.caption)
                                .foregroundStyle(Color.trellisAsh)
                        }

                        Spacer()

                        Button("撤销") {
                            Task {
                                await undoClear(clearReceipt)
                            }
                        }
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(Color.trellisBrass)
                    }
                    .foregroundStyle(Color.trellisBone)
                    .padding(14)
                    .background(.ultraThinMaterial)
                    .overlay(alignment: .top) {
                        Rectangle()
                            .fill(Color.trellisBrass.opacity(0.35))
                            .frame(height: 1)
                    }
                }
            }
        }
    }

    private func clearToday() async {
        guard let receipt = await model.clearUnfinishedTasksToday() else {
            return
        }
        scheduler.cancel(taskIDs: receipt.tasks.map(\.id))
        withAnimation {
            clearReceipt = receipt
        }

        let receiptID = receipt.id
        try? await Task.sleep(for: .seconds(10))
        guard clearReceipt?.id == receiptID else {
            return
        }
        withAnimation {
            clearReceipt = nil
        }
    }

    private func undoClear(_ receipt: ClearPlanReceipt) async {
        guard await model.restoreClearedPlan(receipt) else {
            return
        }
        _ = await scheduler.schedule(receipt.tasks)
        withAnimation {
            clearReceipt = nil
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Date.now.formatted(
                .dateTime
                    .year()
                    .month(.wide)
                    .day()
                    .weekday(.wide)
            ))
            .font(.caption)
            .tracking(1.2)
            .foregroundStyle(Color.trellisAsh)

            Text("只做今天真正重要的事。")
                .font(.system(.largeTitle, design: .serif))
                .foregroundStyle(Color.trellisBone)
        }
        .padding(.vertical, 8)
    }

    private var completedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("已完成")

            ForEach(model.data.tasks.filter(\.isCompleted)) { task in
                TaskRow(task: task) {
                    Task {
                        await model.toggleTask(id: task.id)
                    }
                }
            }
        }
        .opacity(0.72)
        .padding(.top, 12)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(.headline, design: .serif))
            .tracking(1.4)
            .foregroundStyle(Color.trellisBone)
            .padding(.top, 12)
    }
}

private struct TaskRow: View {
    let task: GrowthTask
    let toggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Button(action: toggle) {
                Image(systemName: task.isCompleted ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(
                        task.isCompleted ? Color.trellisJade : Color.trellisAsh
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(task.isCompleted ? "取消完成" : "标记完成")
            .accessibilityValue(task.title)

            VStack(alignment: .leading, spacing: 5) {
                Text(task.title)
                    .font(.body)
                    .foregroundStyle(Color.trellisBone)
                    .strikethrough(task.isCompleted)

                Text(task.area)
                    .font(.caption)
                    .foregroundStyle(Color.trellisAsh)

                if let scheduledAt = task.scheduledAt {
                    HStack(spacing: 8) {
                        Label(
                            scheduledAt.formatted(
                                .dateTime.hour().minute()
                            ),
                            systemImage: "clock"
                        )

                        if let reminderAt = task.reminderAt {
                            Label(
                                "提醒 " + reminderAt.formatted(
                                    .dateTime.hour().minute()
                                ),
                                systemImage: "bell"
                            )
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(Color.trellisBrass)
                }
            }

            Spacer(minLength: 8)
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

private struct StatTile: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(Color.trellisBone)

            Text(label)
                .font(.caption)
                .foregroundStyle(Color.trellisAsh)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .trellisCard()
    }
}

private struct EmptyState: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.trellisBone)
            Text(detail)
                .font(.callout)
                .foregroundStyle(Color.trellisAsh)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .trellisCard()
    }
}

private struct NewTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var isSaving = false
    let onSave: (String) async -> Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("今天要推进什么？") {
                    TextField("一句话写清楚", text: $title, axis: .vertical)
                        .lineLimit(2...4)
                        .accessibilityLabel("任务内容")
                }
            }
            .navigationTitle("新建任务")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        Task {
                            isSaving = true
                            let didSave = await onSave(title)
                            isSaving = false
                            if didSave {
                                dismiss()
                            }
                        }
                    }
                    .disabled(
                        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            || isSaving
                    )
                }
            }
        }
    }
}

