import SwiftUI

struct VoiceTaskCaptureView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var capture = VoiceTaskCaptureModel()
    @State private var scheduler = LocalReminderScheduler()
    @State private var isSaving = false
    @State private var savedMessage: String?

    var body: some View {
        @Bindable var capture = capture

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    intro
                    recordingControl

                    if let recommendation = capture.fitnessRecommendation {
                        fitnessRecommendationCard(recommendation)
                    }

                    transcriptCard

                    if let errorMessage = capture.errorMessage {
                        errorCard(errorMessage)
                    }

                    if !capture.drafts.isEmpty {
                        parsedTasks(drafts: $capture.drafts)
                    }
                }
                .padding(22)
                .padding(.bottom, capture.canSave ? 88 : 24)
            }
            .background(Color.trellisInk.ignoresSafeArea())
            .navigationTitle("语音安排")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        capture.cancel()
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if capture.canSave {
                    saveBar
                }
            }
            .interactiveDismissDisabled(capture.isRecording || isSaving)
            .alert(
                "任务已保存",
                isPresented: Binding(
                    get: { savedMessage != nil },
                    set: { isPresented in
                        if !isPresented {
                            savedMessage = nil
                        }
                    }
                )
            ) {
                Button("好") {
                    savedMessage = nil
                    dismiss()
                }
            } message: {
                Text(savedMessage ?? "")
            }
            .onDisappear {
                capture.cancel()
            }
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("一次说完，自动排成时间线。")
                .font(.system(.title2, design: .serif))
                .foregroundStyle(Color.trellisBone)

            Text("例如：“12点给客户打电话，下午2点开会”；也可以直接说“练上肢”或“练核心”。")
                .font(.callout)
                .foregroundStyle(Color.trellisAsh)
        }
    }

    private func fitnessRecommendationCard(
        _ recommendation: FitnessRoutineRecommendation
    ) -> some View {
        FitnessRoutinePlanView(recommendation: recommendation)
            .trellisCard()
            .accessibilityIdentifier("fitness-recommendation")
    }

    private var recordingControl: some View {
        VStack(spacing: 14) {
            Button {
                Task {
                    if capture.isRecording {
                        await capture.stop()
                    } else {
                        await capture.start()
                    }
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            capture.isRecording
                                ? Color.trellisDanger
                                : Color.trellisBrass
                        )
                        .frame(width: 112, height: 112)
                        .shadow(
                            color: (capture.isRecording
                                ? Color.trellisDanger
                                : Color.trellisBrass
                            ).opacity(0.28),
                            radius: 24
                        )

                    Image(
                        systemName: capture.isRecording
                            ? "stop.fill"
                            : "mic.fill"
                    )
                    .font(.system(size: 38, weight: .medium))
                    .foregroundStyle(Color.trellisInk)
                }
            }
            .buttonStyle(.plain)
            .disabled(capture.isStarting)
            .accessibilityLabel(
                capture.isRecording ? "停止并拆分任务" : "开始语音输入"
            )

            Text(recordingLabel)
                .font(.headline)
                .foregroundStyle(Color.trellisBone)

            Text("语音只在本机识别，不保存录音，也不上传。")
                .font(.caption)
                .foregroundStyle(Color.trellisAsh)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .trellisCard()
    }

    private var recordingLabel: String {
        if let statusMessage = capture.statusMessage {
            return statusMessage
        }
        if capture.isStarting {
            return "正在准备麦克风…"
        }
        if capture.isRecording {
            return "正在听，点一下结束"
        }
        return "点一下，开始说"
    }

    private var transcriptCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("实时转写")
                .font(.caption)
                .tracking(1.2)
                .foregroundStyle(Color.trellisBrass)

            Text(
                capture.transcript.isEmpty
                    ? "你说的内容会显示在这里。"
                    : capture.transcript
            )
            .font(.system(.body, design: .serif))
            .foregroundStyle(
                capture.transcript.isEmpty
                    ? Color.trellisAsh
                    : Color.trellisBone
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .animation(.easeOut(duration: 0.16), value: capture.transcript)
        }
        .trellisCard()
    }

    private func parsedTasks(
        drafts: Binding<[VoiceTaskDraft]>
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("已拆成 \(drafts.wrappedValue.count) 个任务")
                    .font(.headline)
                    .foregroundStyle(Color.trellisBone)

                Spacer()

                Button("重说") {
                    capture.reset()
                }
                .font(.callout)
                .foregroundStyle(Color.trellisBrass)
            }

            ForEach(drafts) { $draft in
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 10) {
                        Text(
                            draft.scheduledAt.formatted(
                                .dateTime.hour().minute()
                            )
                        )
                        .font(.system(.headline, design: .monospaced))
                        .foregroundStyle(Color.trellisBrass)
                        .frame(width: 58, alignment: .leading)

                        TextField("任务内容", text: $draft.title)
                            .font(.body)
                            .foregroundStyle(Color.trellisBone)
                    }

                    HStack {
                        DatePicker(
                            "时间",
                            selection: $draft.scheduledAt,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .labelsHidden()
                        .tint(.trellisBrass)

                        Spacer()

                        Label(
                            reminderLabel(for: draft),
                            systemImage: "bell"
                        )
                        .font(.caption)
                        .foregroundStyle(Color.trellisAsh)
                    }
                }
                .trellisCard()
            }
        }
    }

    private func reminderLabel(for draft: VoiceTaskDraft) -> String {
        draft.reminderLeadMinutes == 0
            ? "准时提醒"
            : "提前 \(draft.reminderLeadMinutes) 分钟"
    }

    private func errorCard(_ message: String) -> some View {
        Text(message)
            .font(.callout)
            .foregroundStyle(Color.trellisBone)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Color.trellisDanger.opacity(0.22))
            .overlay {
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.trellisDanger.opacity(0.45))
            }
    }

    private var saveBar: some View {
        VStack(spacing: 0) {
            Button {
                saveTasks()
            } label: {
                HStack {
                    if isSaving {
                        ProgressView()
                            .tint(Color.trellisInk)
                    }
                    Text(
                        isSaving
                            ? "正在保存"
                            : saveButtonTitle
                    )
                    .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .tint(.trellisBrass)
            .disabled(isSaving || !capture.canSave)
            .padding(16)
            .background(.ultraThinMaterial)
        }
    }

    private var saveButtonTitle: String {
        if capture.fitnessRecommendation != nil {
            return "确认训练安排并提醒"
        }
        return "保存 \(capture.drafts.count) 个任务并提醒"
    }

    private func saveTasks() {
        guard !isSaving else {
            return
        }

        isSaving = true
        Task {
            let drafts = capture.drafts
            let didSave = await model.addScheduledTasks(drafts)
            guard didSave else {
                capture.errorMessage = "任务没有保存，请稍后重试。"
                isSaving = false
                return
            }

            let taskIDs = Set(drafts.map(\.id))
            let savedTasks = model.data.tasks.filter {
                taskIDs.contains($0.id)
            }
            let hasReminders = savedTasks.contains {
                $0.reminderAt != nil
            }

            if hasReminders {
                let result = await scheduler.schedule(savedTasks)
                if result.scheduledCount > 0 {
                    let channel = result.channel == .alarmKit
                        ? "系统闹钟"
                        : "普通通知"
                    let suffix = result.failedCount > 0
                        ? "；另有 \(result.failedCount) 个提醒设置失败"
                        : ""
                    savedMessage = "\(savedTasks.count) 个任务已加入今天，\(result.scheduledCount) 个\(channel)已设置\(suffix)。"
                    if result.channel == .notification {
                        savedMessage? += "普通通知可能受静音或专注模式影响。"
                    }
                } else if result.eligibleCount == 0 {
                    savedMessage = "任务已保存；提醒时间已经过去，因此没有创建闹钟。"
                } else {
                    savedMessage = "任务已保存，但闹钟和通知权限未开启。请到“设置 > SOMETHING”中允许提醒。"
                }
            } else {
                savedMessage = "\(savedTasks.count) 个任务已加入今天。"
            }

            isSaving = false
        }
    }
}
