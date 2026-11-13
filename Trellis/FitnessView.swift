import SwiftUI

struct FitnessView: View {
    @Environment(AppModel.self) private var model
    @Environment(AlarmVoicePreferences.self) private var alarmVoicePreferences
    @State private var scheduler = LocalReminderScheduler()
    @State private var selectedFocus: FitnessFocus = .upper
    @State private var scheduledAt = FitnessIntentParser.suggestedStart()
    @State private var searchText = ""
    @State private var isSaving = false
    @State private var savedMessage: String?
    @State private var saveFailed = false

    private var recommendation: FitnessRoutineRecommendation {
        FitnessIntentParser.recommendation(for: selectedFocus)
    }

    private var visibleExercises: [FitnessExercise] {
        let exercises = FitnessCatalog.exercises(for: selectedFocus)
        guard !searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty else {
            return exercises
        }
        return exercises.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
                || $0.targets.localizedCaseInsensitiveContains(searchText)
                || $0.method.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    intro
                    focusPicker
                    routineCard
                    exerciseLibrary
                }
                .padding(22)
                .padding(.bottom, 16)
            }
            .background(Color.trellisInk.ignoresSafeArea())
            .navigationTitle("训练")
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .automatic),
                prompt: "搜索动作或训练部位"
            )
            .alert(
                "训练安排",
                isPresented: Binding(
                    get: { savedMessage != nil },
                    set: { if !$0 { savedMessage = nil } }
                )
            ) {
                Button("好") {
                    savedMessage = nil
                }
            } message: {
                Text(savedMessage ?? "")
            }
            .alert("没有保存", isPresented: $saveFailed) {
                Button("知道了", role: .cancel) {}
            } message: {
                Text("训练安排写入失败，请稍后重试。")
            }
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("今天练什么？")
                .font(.system(.largeTitle, design: .serif))
                .foregroundStyle(Color.trellisBone)

            Text("80 个动作与运动项目，热身和收尾只保留一小组。说“练上肢”或“练核心”，语音也会直接推荐。")
                .font(.callout)
                .foregroundStyle(Color.trellisAsh)
        }
    }

    private var focusPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(FitnessFocus.allCases) { focus in
                    Button {
                        selectedFocus = focus
                    } label: {
                        Label(focus.title, systemImage: focus.systemImage)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(
                                selectedFocus == focus
                                    ? Color.trellisInk
                                    : Color.trellisBone
                            )
                            .padding(.horizontal, 13)
                            .padding(.vertical, 9)
                            .background(
                                selectedFocus == focus
                                    ? Color.trellisBrass
                                    : Color.trellisPlate
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var routineCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            FitnessRoutinePlanView(recommendation: recommendation)

            DatePicker(
                "安排到",
                selection: $scheduledAt,
                displayedComponents: [.date, .hourAndMinute]
            )
            .tint(.trellisBrass)

            Button {
                scheduleRoutine()
            } label: {
                HStack {
                    if isSaving {
                        ProgressView()
                            .tint(Color.trellisInk)
                    }
                    Text(isSaving ? "正在加入" : "加入今天并提醒")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.trellisBrass)
            .disabled(isSaving)
        }
        .trellisCard()
    }

    private var exerciseLibrary: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(selectedFocus.title)动作库")
                    .font(.system(.headline, design: .serif))
                    .foregroundStyle(Color.trellisBone)

                Spacer()

                Text("\(visibleExercises.count) 个动作")
                    .font(.caption)
                    .foregroundStyle(Color.trellisAsh)
            }

            ForEach(visibleExercises) { exercise in
                FitnessExerciseCard(exercise: exercise)
            }
        }
    }

    private func scheduleRoutine() {
        guard !isSaving else {
            return
        }
        isSaving = true
        Task {
            let draft = recommendation.taskDraft(
                scheduledAt: scheduledAt
            )
            let didSave = await model.addScheduledTasks([draft])
            isSaving = false
            if didSave {
                let savedTask = model.data.tasks.first {
                    $0.id == draft.id
                }
                var result: ReminderScheduleResult?
                if let savedTask {
                    result = await scheduler.schedule(
                        [savedTask],
                        voiceSettings: alarmVoicePreferences.settings
                    )
                }
                let time = scheduledAt.formatted(
                    .dateTime.month().day().hour().minute()
                )
                if let result, result.scheduledCount > 0 {
                    let channel = result.channel == .alarmKit
                        ? "系统闹钟"
                        : "普通通知"
                    let fallback = result.spokenFallbackCount > 0
                        ? " 本机没有对应的中文播报声音，已改用系统铃声。"
                        : ""
                    savedMessage = "\(recommendation.title) 已加入 \(time)，并设置了\(channel)。\(fallback)"
                } else {
                    savedMessage = "\(recommendation.title) 已加入 \(time)，但没有取得提醒权限。请到系统设置中允许提醒。"
                }
            } else {
                saveFailed = true
            }
        }
    }
}
