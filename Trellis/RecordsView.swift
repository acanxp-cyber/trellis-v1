import PhotosUI
import SwiftUI

struct RecordsView: View {
    @Environment(AppModel.self) private var model
    @Environment(LocalAudioPlayer.self) private var audioPlayer
    @FocusState private var isDraftFocused: Bool
    @State private var draft = ""
    @State private var attachments: [RecordAttachment] = []
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var draftRecordID = UUID()
    @State private var mediaStore = try? RecordMediaStore.makeDefault()
    @State private var isSaving = false
    @State private var cameraMode: RecordCameraMode = .photo
    @State private var showsCamera = false
    @State private var showsVoiceRecorder = false
    @State private var showsPencil = false
    @State private var showsPixel = false
    @State private var showsSticker = false
    @State private var showsEnglishReading = false
    @State private var mediaError: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    composer
                    history
                }
                .padding(22)
            }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom, spacing: 8) {
                recordInputBar
            }
            .background(Color.trellisInk.ignoresSafeArea())
            .navigationTitle("记录")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Button("完成") {
                        isDraftFocused = false
                    }

                    Spacer()

                    Button(isSaving ? "保存中" : "存为记录") {
                        isDraftFocused = false
                        saveRecord()
                    }
                    .disabled(saveDisabled)
                }
            }
            .onChange(of: selectedPhotos) { _, items in
                Task {
                    await importPhotoItems(items)
                }
            }
            .fullScreenCover(isPresented: $showsCamera) {
                RecordCameraPicker(
                    mode: cameraMode,
                    onCapture: { media in
                        showsCamera = false
                        Task {
                            await saveCaptured(
                                media,
                                kind: media.kind,
                                fileExtension: media.fileExtension
                            )
                        }
                    },
                    onCancel: {
                        showsCamera = false
                    }
                )
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showsVoiceRecorder) {
                VoiceMemoSheet { media in
                    Task {
                        await saveCaptured(
                            media,
                            kind: .audio,
                            fileExtension: "m4a"
                        )
                    }
                }
            }
            .sheet(isPresented: $showsPencil) {
                PencilDrawingEditor { data in
                    Task {
                        await saveData(
                            data,
                            kind: .drawing,
                            fileExtension: "png"
                        )
                    }
                }
            }
            .sheet(isPresented: $showsPixel) {
                PixelSketchEditor { data in
                    Task {
                        await saveData(
                            data,
                            kind: .pixelArt,
                            fileExtension: "png"
                        )
                    }
                }
            }
            .sheet(isPresented: $showsSticker) {
                StickerCanvasEditor { data in
                    Task {
                        await saveData(
                            data,
                            kind: .stickerArtwork,
                            fileExtension: "png"
                        )
                    }
                }
            }
            .sheet(isPresented: $showsEnglishReading) {
                EnglishReadingPracticeView()
            }
            .alert(
                "媒体保存失败",
                isPresented: Binding(
                    get: { mediaError != nil },
                    set: { if !$0 { mediaError = nil } }
                )
            ) {
                Button("知道了", role: .cancel) {}
            } message: {
                Text(mediaError ?? "")
            }
            .onDisappear {
                cleanupUnsavedMedia()
                audioPlayer.stop()
            }
        }
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("这一刻留下什么？")
                .font(.system(.title3, design: .serif))
                .foregroundStyle(Color.trellisBone)

            if let mediaStore {
                RecordAttachmentStrip(
                    attachments: attachments,
                    store: mediaStore,
                    onDelete: removeAttachment
                )
            }

            Button {
                saveRecord()
            } label: {
                Text(isSaving ? "保存中" : "存为记录")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.trellisBrass)
            .disabled(
                saveDisabled
            )

            actionGrid
        }
        .trellisCard()
    }

    private var recordInputBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)

            HStack(alignment: .bottom, spacing: 10) {
                TextField(
                    "写下此刻，键盘上方可直接存为记录。",
                    text: $draft,
                    axis: .vertical
                )
                .focused($isDraftFocused)
                .lineLimit(1...4)
                .textFieldStyle(.plain)
                .padding(.vertical, 9)
                .accessibilityLabel("记录内容")

                if isDraftFocused {
                    Button("完成") {
                        isDraftFocused = false
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.trellisBrass)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
        .background(.ultraThinMaterial)
        .background(Color.trellisInk.opacity(0.92))
    }

    private var saveDisabled: Bool {
        (
            draft.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty
                && attachments.isEmpty
        )
            || isSaving
    }

    private var actionGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("添加或创作")
                .font(.caption.weight(.semibold))
                .tracking(1)
                .foregroundStyle(Color.trellisAsh)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10),
                ],
                spacing: 10
            ) {
                ForEach(RecordStudioActionCatalog.all) { action in
                    if action.id == .library {
                        PhotosPicker(
                            selection: $selectedPhotos,
                            maxSelectionCount: 10,
                            matching: .any(of: [.images, .videos])
                        ) {
                            RecordActionTile(action: action)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier(
                            "record-action-\(action.id.rawValue)"
                        )
                    } else {
                        Button {
                            perform(action.id)
                        } label: {
                            RecordActionTile(action: action)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier(
                            "record-action-\(action.id.rawValue)"
                        )
                    }
                }
            }
        }
    }

    private var history: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("最近")
                    .font(.system(.headline, design: .serif))
                    .foregroundStyle(Color.trellisBone)
                Spacer()
                Text("\(model.data.records.count) 条")
                    .font(.caption)
                    .foregroundStyle(Color.trellisAsh)
            }

            if model.data.records.isEmpty {
                Text("第一条记录会出现在这里。")
                    .font(.callout)
                    .foregroundStyle(Color.trellisAsh)
                    .trellisCard()
            } else {
                ForEach(
                    model.data.records.sorted {
                        $0.createdAt > $1.createdAt
                    }
                ) { record in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(record.createdAt.formatted(
                            .dateTime.month().day().hour().minute()
                        ))
                        .font(.caption)
                        .tracking(0.8)
                        .foregroundStyle(Color.trellisBrass)

                        if !record.text.isEmpty {
                            Text(record.text)
                                .font(.system(.body, design: .serif))
                                .foregroundStyle(Color.trellisBone)
                        }

                        if !record.attachments.isEmpty {
                            RecordAttachmentStrip(
                                attachments: record.attachments,
                                store: mediaStore
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .trellisCard()
                }
            }
        }
    }

    private func perform(_ action: RecordStudioActionID) {
        switch action {
        case .camera:
            cameraMode = .photo
            showsCamera = true
        case .video:
            cameraMode = .video
            showsCamera = true
        case .library:
            break
        case .voice:
            showsVoiceRecorder = true
        case .drawing:
            showsPencil = true
        case .pixelArt:
            showsPixel = true
        case .stickers:
            showsSticker = true
        case .englishReading:
            showsEnglishReading = true
        }
    }

    private func importPhotoItems(
        _ items: [PhotosPickerItem]
    ) async {
        guard !items.isEmpty else {
            return
        }
        for item in items {
            if item.supportedContentTypes.contains(where: {
                $0.conforms(to: .movie)
            }) {
                if let movie = try? await item.loadTransferable(
                    type: MovieFileTransfer.self
                ) {
                    await saveData(
                        movie.data,
                        kind: .video,
                        fileExtension: "mov"
                    )
                }
            } else if let data = try? await item.loadTransferable(
                type: Data.self
            ) {
                await saveData(
                    data,
                    kind: .photo,
                    fileExtension: "jpg"
                )
            }
        }
        selectedPhotos = []
    }

    private func saveCaptured(
        _ media: CapturedRecordMedia,
        kind: RecordAttachmentKind,
        fileExtension: String
    ) async {
        guard let mediaStore else {
            mediaError = "无法打开本地媒体目录。"
            return
        }
        do {
            let attachment = try await mediaStore.save(
                media.data,
                recordID: draftRecordID,
                kind: kind,
                fileExtension: fileExtension,
                durationSeconds: media.durationSeconds
            )
            attachments.append(attachment)
        } catch {
            mediaError = (error as? LocalizedError)?.errorDescription
                ?? "媒体保存失败。"
        }
    }

    private func saveData(
        _ data: Data,
        kind: RecordAttachmentKind,
        fileExtension: String
    ) async {
        await saveCaptured(
            CapturedRecordMedia(
                data: data,
                kind: kind,
                fileExtension: fileExtension,
                durationSeconds: nil
            ),
            kind: kind,
            fileExtension: fileExtension
        )
    }

    private func saveRecord() {
        guard !isSaving else {
            return
        }
        isSaving = true
        Task {
            let didSave = await model.addRecord(
                text: draft,
                recordID: draftRecordID,
                attachments: attachments
            )
            isSaving = false
            if didSave {
                draft = ""
                attachments = []
                selectedPhotos = []
                draftRecordID = UUID()
                isDraftFocused = false
            }
        }
    }

    private func removeAttachment(_ attachment: RecordAttachment) {
        attachments.removeAll { $0.id == attachment.id }
        guard let mediaStore else {
            return
        }
        Task {
            try? await mediaStore.delete(attachment)
        }
    }

    private func cleanupUnsavedMedia() {
        guard !attachments.isEmpty, let mediaStore else {
            return
        }
        let unsaved = attachments
        Task {
            for attachment in unsaved {
                try? await mediaStore.delete(attachment)
            }
        }
    }
}

private struct RecordActionTile: View {
    let action: RecordStudioActionDescriptor

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: action.systemImage)
                .font(.system(size: 19, weight: .medium))
                .foregroundStyle(
                    action.isCreative
                        ? Color.trellisJade
                        : Color.trellisBrass
                )
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(action.title)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Color.trellisBone)
                    .lineLimit(1)

                Text(action.detail)
                    .font(.caption2)
                    .foregroundStyle(Color.trellisAsh)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .topLeading)
        .padding(11)
        .background(Color.black.opacity(0.18))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(
                    action.isCreative
                        ? Color.trellisJade.opacity(0.2)
                        : Color.white.opacity(0.06)
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: 7))
    }
}
