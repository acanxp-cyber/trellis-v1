import Photos
import SwiftUI
import UIKit

enum RecordMediaExportError: LocalizedError {
    case photoAccessDenied
    case unsupportedType
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .photoAccessDenied:
            return "没有相册写入权限，请在系统设置中允许 Somethings 添加照片。"
        case .unsupportedType:
            return "这类记录暂不支持保存到系统相册。"
        case .saveFailed:
            return "导出失败，请稍后重试。"
        }
    }
}

@MainActor
enum RecordMediaExporter {
    static func saveToPhotos(
        attachment: RecordAttachment,
        store: RecordMediaStore
    ) async throws {
        let authorization = await PHPhotoLibrary.requestAuthorization(
            for: .addOnly
        )
        guard authorization == .authorized || authorization == .limited else {
            throw RecordMediaExportError.photoAccessDenied
        }

        let sourceURL = try await store.url(for: attachment)
        let resourceType: PHAssetResourceType
        let exportURL: URL
        var temporaryURL: URL?

        switch attachment.kind {
        case .photo, .drawing, .pixelArt, .stickerArtwork:
            resourceType = .photo
            let fileExtension = sourceURL.pathExtension.isEmpty
                ? "jpg"
                : sourceURL.pathExtension
            let target = FileManager.default.temporaryDirectory
                .appendingPathComponent(
                    "\(UUID().uuidString).\(fileExtension)"
                )
            let data = try await store.data(for: attachment)
            try data.write(to: target, options: .atomic)
            exportURL = target
            temporaryURL = target
        case .video:
            resourceType = .video
            exportURL = sourceURL
        case .audio:
            throw RecordMediaExportError.unsupportedType
        }

        defer {
            if let temporaryURL {
                try? FileManager.default.removeItem(at: temporaryURL)
            }
        }

        try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges {
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(
                    with: resourceType,
                    fileURL: exportURL,
                    options: nil
                )
            } completionHandler: { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(
                        throwing: error ?? RecordMediaExportError.saveFailed
                    )
                }
            }
        }
    }
}

struct RecordMediaViewer: View {
    let attachments: [RecordAttachment]
    let initialAttachmentID: RecordAttachment.ID
    let store: RecordMediaStore

    @Environment(\.dismiss) private var dismiss
    @State private var selection: RecordAttachment.ID
    @State private var isExporting = false
    @State private var exportMessage: String?
    @State private var exportError: String?

    init(
        attachments: [RecordAttachment],
        initialAttachmentID: RecordAttachment.ID,
        store: RecordMediaStore
    ) {
        self.attachments = attachments
        self.initialAttachmentID = initialAttachmentID
        self.store = store
        _selection = State(initialValue: initialAttachmentID)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $selection) {
                ForEach(attachments) { attachment in
                    ZoomableRecordImage(
                        attachment: attachment,
                        store: store
                    )
                    .tag(attachment.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            VStack {
                controls
                Spacer()
                if attachments.count > 1 {
                    Text(positionText)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(.black.opacity(0.5))
                        .clipShape(Capsule())
                        .padding(.bottom, 24)
                }
            }

            if let exportMessage {
                Text(exportMessage)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Color.trellisBone)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.trellisJade.opacity(0.92))
                    .clipShape(Capsule())
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .alert(
            "无法导出",
            isPresented: Binding(
                get: { exportError != nil },
                set: { if !$0 { exportError = nil } }
            )
        ) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text(exportError ?? "")
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.body.weight(.semibold))
                    .frame(width: 40, height: 40)
                    .background(.black.opacity(0.5))
                    .clipShape(Circle())
            }
            .accessibilityLabel("关闭大图")

            Spacer()

            Button {
                exportCurrentImage()
            } label: {
                if isExporting {
                    ProgressView()
                        .tint(.white)
                        .frame(width: 40, height: 40)
                } else {
                    Image(systemName: "square.and.arrow.down")
                        .font(.body.weight(.semibold))
                        .frame(width: 40, height: 40)
                }
            }
            .disabled(isExporting)
            .accessibilityLabel("保存到相册")
            .background(.black.opacity(0.5))
            .clipShape(Circle())
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var positionText: String {
        let index = attachments.firstIndex { $0.id == selection }
            .map { $0 + 1 }
            ?? 1
        return "\(index) / \(attachments.count)"
    }

    private func exportCurrentImage() {
        guard let attachment = attachments.first(where: {
            $0.id == selection
        }) else {
            return
        }
        isExporting = true
        Task {
            do {
                try await RecordMediaExporter.saveToPhotos(
                    attachment: attachment,
                    store: store
                )
                withAnimation {
                    exportMessage = "已保存到系统相册"
                }
                try? await Task.sleep(for: .seconds(1.8))
                withAnimation {
                    exportMessage = nil
                }
            } catch {
                exportError = (error as? LocalizedError)?.errorDescription
                    ?? RecordMediaExportError.saveFailed.errorDescription
            }
            isExporting = false
        }
    }
}

private struct ZoomableRecordImage: View {
    let attachment: RecordAttachment
    let store: RecordMediaStore

    @State private var image: UIImage?
    @State private var scale: CGFloat = 1
    @State private var settledScale: CGFloat = 1
    @State private var offset = CGSize.zero
    @State private var settledOffset = CGSize.zero
    @State private var loadError: String?

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black

                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .offset(offset)
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity
                        )
                        .gesture(magnificationGesture)
                        .simultaneousGesture(
                            panGesture(containerSize: proxy.size)
                        )
                        .onTapGesture(count: 2) {
                            withAnimation(.snappy) {
                                if scale > 1 {
                                    resetZoom()
                                } else {
                                    scale = 2.5
                                    settledScale = 2.5
                                }
                            }
                        }
                } else if let loadError {
                    VStack(spacing: 10) {
                        Image(systemName: "photo.badge.exclamationmark")
                            .font(.system(size: 34))
                        Text(loadError)
                            .font(.callout)
                    }
                    .foregroundStyle(Color.trellisAsh)
                } else {
                    ProgressView()
                        .tint(.white)
                }
            }
            .task(id: attachment.id) {
                await loadImage()
            }
        }
    }

    private var magnificationGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                scale = min(max(settledScale * value.magnification, 1), 5)
            }
            .onEnded { _ in
                settledScale = scale
                if scale <= 1.01 {
                    resetZoom()
                }
            }
    }

    private func panGesture(
        containerSize: CGSize
    ) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                guard scale > 1.01 else {
                    return
                }
                let maxX = max(
                    (containerSize.width * (scale - 1)) / 2,
                    0
                )
                let maxY = max(
                    (containerSize.height * (scale - 1)) / 2,
                    0
                )
                offset = CGSize(
                    width: min(
                        max(
                            settledOffset.width + value.translation.width,
                            -maxX
                        ),
                        maxX
                    ),
                    height: min(
                        max(
                            settledOffset.height + value.translation.height,
                            -maxY
                        ),
                        maxY
                    )
                )
            }
            .onEnded { _ in
                guard scale > 1.01 else {
                    return
                }
                settledOffset = offset
            }
    }

    @MainActor
    private func loadImage() async {
        do {
            let data = try await store.data(for: attachment)
            guard let decoded = UIImage(data: data) else {
                throw RecordMediaExportError.saveFailed
            }
            image = decoded
            loadError = nil
        } catch {
            loadError = "图片读取失败"
        }
    }

    private func resetZoom() {
        scale = 1
        settledScale = 1
        offset = .zero
        settledOffset = .zero
    }
}
