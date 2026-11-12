import PhotosUI
import SwiftUI

struct RecordsView: View {
    @Environment(AppModel.self) private var model
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
            .background(Color.trellisInk.ignoresSafeArea())
            .navigationTitle("记录")
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
            }
        }
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("这一刻留下什么？")
                .font(.system(.title3, design: .serif))
                .foregroundStyle(Color.trellisBone)

            TextField(
                "写一句就够，也可以只放照片、视频或涂鸦。",
                text: $draft,
                axis: .vertical
            )
            .lineLimit(3...7)
            .textFieldStyle(.plain)
            .padding(14)
            .background(Color.black.opacity(0.18))
            .overlay {
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.white.opacity(0.1))
            }
            .accessibilityLabel("记录内容")

            if let mediaStore {
                RecordAttachmentStrip(
                    attachments: attachments,
                    store: mediaStore,
                    onDelete: removeAttachment
                )
            }

            mediaToolbar

            Button {
                saveRecord()
            } label: {
                Text(isSaving ? "保存中" : "存为记录")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.trellisBrass)
            .disabled(
                (
                    draft.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty
                        && attachments.isEmpty
                )
                    || isSaving
            )
        }
        .trellisCard()
    }

    private var mediaToolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                mediaButton("拍照", systemImage: "camera.fill") {
                    cameraMode = .photo
                    showsCamera = true
                }
                mediaButton("录像", systemImage: "video.fill") {
                    cameraMode = .video
                    showsCamera = true
                }

                PhotosPicker(
                    selection: $selectedPhotos,
                    maxSelectionCount: 10,
                    matching: .any(of: [.images, .videos])
                ) {
                    Label(
                        "照片/视频",
                        systemImage: "photo.on.rectangle"
                    )
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(Color.black.opacity(0.18))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                mediaButton("语音", systemImage: "waveform") {
                    showsVoiceRecorder = true
                }
                mediaButton(
                    "手绘",
                    systemImage: "pencil.tip.crop.circle"
                ) {
                    showsPencil = true
                }
                mediaButton(
                    "像素",
                    systemImage: "square.grid.3x3.fill"
                ) {
                    showsPixel = true
                }
                mediaButton("贴纸", systemImage: "face.smiling") {
                    showsSticker = true
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

    private func mediaButton(
        _ title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(Color.black.opacity(0.18))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
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
