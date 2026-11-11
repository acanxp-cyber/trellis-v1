import SwiftUI

struct TodayView: View {
    @Environment(AppModel.self) private var model
    @State private var isAddingTask = false
    @State private var isCapturingVoice = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    header
                    voiceCaptureButton

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
            .sheet(isPresented: $isCapturingVoice) {
                VoiceTaskCaptureView()
                    .presentationDetents([.large])
            }
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

    private var voiceCaptureButton: some View {
        Button {
            isCapturingVoice = true
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.trellisBrass)
                        .frame(width: 58, height: 58)

                    Image(systemName: "mic.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(Color.trellisInk)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("语音安排")
                        .font(.system(.headline, design: .serif))
                        .foregroundStyle(Color.trellisBone)

                    Text("一次说完，自动拆成任务、时间和提醒")
                        .font(.caption)
                        .foregroundStyle(Color.trellisAsh)
                }

                Spacer(minLength: 6)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.trellisAsh)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .trellisCard()
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("voice-task-capture")
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

