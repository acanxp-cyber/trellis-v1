@preconcurrency import AVFoundation
import Observation
import SwiftUI
import UniformTypeIdentifiers

struct MoreView: View {
    @Environment(AppModel.self) private var model
    @State private var exportDocument: DataExportDocument?
    @State private var isExporting = false
    @State private var exportFailed = false

    var body: some View {
        NavigationStack {
            List {
                Section("时间线") {
                    NavigationLink {
                        ReviewView()
                    } label: {
                        Label("周回顾", systemImage: "checklist")
                    }

                    NavigationLink {
                        YearView()
                    } label: {
                        Label("年轮", systemImage: "circle.dashed")
                    }
                }

                Section("提醒") {
                    NavigationLink {
                        AlarmVoiceSettingsView()
                    } label: {
                        Label("提醒声音", systemImage: "waveform.and.person.filled")
                    }
                }

                Section("数据主权") {
                    LabeledContent("存储位置", value: "仅本机")
                    LabeledContent("健康数据", value: "不持久化、不同步")
                    LabeledContent("iCloud 备份", value: "已排除")

                    Button("导出任务与文字数据") {
                        Task {
                            guard let data = await model.exportData() else {
                                exportFailed = true
                                return
                            }
                            exportDocument = DataExportDocument(data: data)
                            isExporting = true
                        }
                    }
                }

                Section("架构红线") {
                    Text("HealthKit 中的个人健康信息只用于本机即时展示，不写入业务数据库，不上传 CloudKit 或 iCloud。")
                    Text("训练记录、身体信号及其派生洞察同样按个人健康信息处理。")
                    Text("后续如增加跨设备同步，只能同步经过逐字段分类的非健康数据。")
                }
                .font(.callout)

                Section("当前版本") {
                    LabeledContent("原生界面", value: "SwiftUI")
                    LabeledContent("本地数据", value: "版本化 JSON")
                    LabeledContent("MVP", value: "任务、语音、训练、回顾")
                }

                Section("第三方素材") {
                    Link(
                        "动作示意：Free Exercise DB（Public Domain）",
                        destination: URL(
                            string: "https://github.com/yuhonas/free-exercise-db"
                        )!
                    )
                    Text("仅打包许可证允许商用的动作图片；Gym Visual 所有的动图未进入 App。")
                        .font(.caption)
                        .foregroundStyle(Color.trellisAsh)
                }
            }
            .navigationTitle("更多")
            .scrollContentBackground(.hidden)
            .background(Color.trellisInk.ignoresSafeArea())
            .fileExporter(
                isPresented: $isExporting,
                document: exportDocument,
                contentType: .json,
                defaultFilename: "trellis-backup"
            ) { _ in
                exportDocument = nil
            }
            .alert("导出失败", isPresented: $exportFailed) {
                Button("知道了", role: .cancel) {}
            } message: {
                Text("没有生成可分享的数据文件。请稍后重试。")
            }
        }
    }
}

struct AlarmVoiceSettingsView: View {
    @Environment(AppModel.self) private var model
    @Environment(AlarmVoicePreferences.self) private var preferences
    @State private var scheduler = LocalReminderScheduler()
    @State private var preview = AlarmVoicePreviewController()
    @State private var showsGuide = false
    @State private var statusMessage: String?
    @State private var isPreviewing = false

    var body: some View {
        @Bindable var preferences = preferences

        Form {
            Section("播报方式") {
                Toggle("播报提醒内容", isOn: $preferences.isSpokenAlarmEnabled)

                Picker("声音", selection: $preferences.profile) {
                    ForEach(AlarmVoiceProfile.allCases) { profile in
                        Text(profile.title)
                            .tag(profile)
                    }
                }
                .pickerStyle(.inline)
                .disabled(!preferences.isSpokenAlarmEnabled)

                Text(preferences.profile.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("试听") {
                Button {
                    previewVoice()
                } label: {
                    HStack {
                        Label(
                            "试听“12点半到了，吃饭囉”",
                            systemImage: "play.circle.fill"
                        )
                        Spacer()
                        if isPreviewing {
                            ProgressView()
                        }
                    }
                }
                .disabled(isPreviewing)

                if let message = preview.errorMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(Color.trellisDanger)
                }
            }

            Section("提醒可靠性") {
                Text("提醒声音会先在 iPhone 本机生成短音频，再交给 AlarmKit 或系统通知播放。声音生成失败时自动改用系统铃声，不会让提醒静默失败。")
                Text("iOS 26 可用时优先使用系统闹钟；旧系统使用普通通知，仍可能受静音或专注模式影响。")
            }
            .font(.callout)

            Section {
                Button("恢复默认声音") {
                    preferences.resetToDefaults()
                    rescheduleOpenReminders()
                }
            }

            if let statusMessage {
                Section {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("提醒声音")
        .onAppear {
            if !preferences.hasSeenGuide {
                showsGuide = true
            }
        }
        .onChange(of: preferences.profile) {
            rescheduleOpenReminders()
        }
        .onChange(of: preferences.isSpokenAlarmEnabled) {
            rescheduleOpenReminders()
        }
        .sheet(isPresented: $showsGuide) {
            AlarmVoiceGuideView {
                preferences.markGuideSeen()
                showsGuide = false
            }
            .presentationDetents([.medium])
            .interactiveDismissDisabled()
        }
    }

    private func previewVoice() {
        guard !isPreviewing else {
            return
        }
        isPreviewing = true
        Task {
            await preview.play(profile: preferences.profile)
            isPreviewing = false
        }
    }

    private func rescheduleOpenReminders() {
        Task {
            let tasks = model.openTasks.filter { $0.reminderAt != nil }
            guard !tasks.isEmpty else {
                statusMessage = "声音偏好已保存，下次创建提醒时生效。"
                return
            }
            let result = await scheduler.schedule(
                tasks,
                voiceSettings: preferences.settings
            )
            let fallback = result.spokenFallbackCount > 0
                ? "，\(result.spokenFallbackCount) 个已回退为系统铃声"
                : ""
            statusMessage = "已更新 \(result.scheduledCount)/\(result.eligibleCount) 个提醒的声音\(fallback)。"
        }
    }
}

private struct AlarmVoiceGuideView: View {
    let close: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Image(systemName: "waveform.and.person.filled")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(Color.trellisBrass)

                Text("先听，再决定")
                    .font(.system(.title2, design: .serif))

                Text("默认使用 iPhone 本机的台湾普通话女声。不会使用网页试听里的微软声音，也不会把健康、训练或语音内容发送到云端。")
                    .foregroundStyle(.secondary)

                Text("你可以在这里试听、关闭播报、切换声音或恢复默认。修改后会重新生成未来提醒的本机音频。")
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding(24)
            .navigationTitle("提醒声音")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("开始设置", action: close)
                }
            }
        }
    }
}

@MainActor
@Observable
private final class AlarmVoicePreviewController {
    private(set) var errorMessage: String?
    private let store = try? SpokenAlarmSoundStore.makeDefault()
    private var player: AVAudioPlayer?

    func play(profile: AlarmVoiceProfile) async {
        guard let store else {
            errorMessage = "无法准备本机播报声音。"
            return
        }
        do {
            var components = Calendar.trellis.dateComponents(
                [.year, .month, .day],
                from: .now
            )
            components.hour = 12
            components.minute = 30
            let fireDate = try XCTUnwrapLike(
                Calendar.trellis.date(from: components)
            )
            let sound = try await store.soundName(
                for: UUID(),
                title: "吃饭",
                scheduledAt: fireDate,
                fireDate: fireDate,
                profile: profile
            )
            let nextPlayer = try AVAudioPlayer(
                contentsOf: store.url(named: sound.fileName)
            )
            player?.stop()
            player = nextPlayer
            nextPlayer.prepareToPlay()
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .spokenAudio,
                options: [.duckOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
            _ = nextPlayer.play()
            errorMessage = nil
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription
                ?? "试听失败，请稍后重试。"
        }
    }

    private func XCTUnwrapLike<T>(_ value: T?) throws -> T {
        guard let value else {
            throw SpokenAlarmSoundError.cannotSynthesize
        }
        return value
    }
}

