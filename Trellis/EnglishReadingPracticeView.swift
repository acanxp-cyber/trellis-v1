import SwiftUI

struct EnglishReadingPracticeView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var passages: [EnglishReadingPassage] = []
    @State private var deck: ReadingPassageDeck?
    @State private var showsChinese = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var savedMessage: String?
    @State private var mediaStore = try? RecordMediaStore.makeDefault()
    @State private var recorder = VoiceMemoRecorder()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if let passage = currentPassage {
                        passageCard(passage)
                    } else {
                        ProgressView("正在读取朗读内容")
                            .frame(maxWidth: .infinity)
                            .padding(.top, 80)
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.callout)
                            .foregroundStyle(Color.trellisDanger)
                            .trellisCard()
                    }

                    if let savedMessage {
                        Label(savedMessage, systemImage: "checkmark.circle.fill")
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(Color.trellisJade)
                    }
                }
                .padding(22)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                readingRecorderBar
            }
            .background(Color.trellisInk.ignoresSafeArea())
            .navigationTitle("英语朗读")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .task {
                loadPassages()
            }
            .onDisappear {
                recorder.cancel()
            }
        }
    }

    private var currentPassage: EnglishReadingPassage? {
        guard let id = deck?.currentID else {
            return nil
        }
        return passages.first { $0.id == id }
    }

    private func passageCard(
        _ passage: EnglishReadingPassage
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(passage.category.uppercased())
                        .font(.caption2.weight(.semibold))
                        .tracking(1.2)
                        .foregroundStyle(Color.trellisBrass)

                    Text(passage.title)
                        .font(.system(.title2, design: .serif))
                        .foregroundStyle(Color.trellisBone)
                }

                Spacer()

                Label(
                    "约 \(passage.estimatedSeconds) 秒",
                    systemImage: "timer"
                )
                .font(.caption)
                .foregroundStyle(Color.trellisAsh)
            }

            Text(passage.english)
                .font(.system(.title3, design: .serif))
                .lineSpacing(6)
                .foregroundStyle(Color.trellisBone)
                .fixedSize(horizontal: false, vertical: true)

            if showsChinese {
                Divider()
                    .overlay(Color.white.opacity(0.08))

                Text(passage.chinese)
                    .font(.callout)
                    .lineSpacing(5)
                    .foregroundStyle(Color.trellisAsh)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 7) {
                Text("重点词汇")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.trellisBrass)

                ForEach(passage.vocabulary, id: \.word) { item in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(item.word) (\(item.ipa))")
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(Color.trellisBone)

                        Text(item.meaning)
                            .font(.caption)
                            .foregroundStyle(Color.trellisAsh)
                    }
                }
            }

            HStack(spacing: 10) {
                Button {
                    showsChinese.toggle()
                } label: {
                    Label(
                        showsChinese ? "收起中文" : "查看中文",
                        systemImage: "character.book.closed"
                    )
                }
                .buttonStyle(.bordered)

                Button {
                    deck?.next()
                    showsChinese = false
                    savedMessage = nil
                } label: {
                    Label("随机一篇", systemImage: "shuffle")
                }
                .buttonStyle(.bordered)

                Spacer()
            }

        }
        .trellisCard()
    }

    private var readingRecorderBar: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(recorder.isRecording ? "正在朗读" : "录下我的朗读")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(Color.trellisBone)

                    Text(
                        recorder.isRecording
                            ? durationText(recorder.elapsedSeconds)
                            : "录音时英文原文保持可见"
                    )
                    .font(.caption)
                    .foregroundStyle(Color.trellisAsh)
                }

                Spacer()

                Button {
                    Task {
                        if recorder.isRecording {
                            if let media = recorder.stop() {
                                await saveAttempt(media)
                            }
                        } else {
                            _ = await recorder.start()
                        }
                    }
                } label: {
                    Label(
                        recorder.isRecording
                            ? "停止并保存"
                            : "开始朗读",
                        systemImage: recorder.isRecording
                            ? "stop.fill"
                            : "mic.fill"
                    )
                    .font(.callout.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(
                    recorder.isRecording
                        ? Color.trellisDanger
                        : Color.trellisBrass
                )
                .disabled(isSaving || mediaStore == nil)
            }

            if let message = recorder.errorMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(Color.trellisDanger)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .background(Color.trellisInk.opacity(0.94))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)
        }
    }

    private func durationText(_ seconds: Int) -> String {
        String(
            format: "%02d:%02d",
            seconds / 60,
            seconds % 60
        )
    }

    private func loadPassages() {
        guard passages.isEmpty else {
            return
        }
        do {
            passages = try EnglishReadingCatalog.load()
            deck = ReadingPassageDeck(
                ids: passages.map(\.id)
            )
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription
                ?? "英语朗读内容读取失败。"
        }
    }

    private func saveAttempt(_ media: CapturedRecordMedia) async {
        guard let passage = currentPassage, let mediaStore else {
            errorMessage = "没有可保存的朗读内容。"
            return
        }
        isSaving = true
        defer {
            isSaving = false
        }

        do {
            let recordID = UUID()
            let attachment = try await mediaStore.save(
                media.data,
                recordID: recordID,
                kind: .audio,
                fileExtension: "m4a",
                durationSeconds: media.durationSeconds
            )
            let didSave = await model.addRecord(
                text: "英语朗读 · \(passage.title)",
                recordID: recordID,
                attachments: [attachment],
                readingPassageID: passage.id
            )
            guard didSave else {
                try? await mediaStore.delete(attachment)
                errorMessage = "朗读记录没有保存成功。"
                return
            }
            savedMessage = "已保存，可回到记录页反复播放。"
            errorMessage = nil
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription
                ?? "朗读录音保存失败。"
        }
    }
}
