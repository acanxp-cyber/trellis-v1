import AVFoundation
import AVKit
import SwiftUI
import UIKit

struct RecordAttachmentStrip: View {
    let attachments: [RecordAttachment]
    let store: RecordMediaStore?
    var onDelete: ((RecordAttachment) -> Void)? = nil
    @State private var viewerAttachment: RecordAttachment?

    var body: some View {
        if !attachments.isEmpty, let store {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(attachments) { attachment in
                        RecordAttachmentView(
                            attachment: attachment,
                            store: store,
                            onDelete: onDelete.map { delete in
                                { delete(attachment) }
                            },
                            onOpen: visualAttachments.contains(attachment)
                                ? { viewerAttachment = attachment }
                                : nil
                        )
                    }
                }
            }
            .fullScreenCover(item: $viewerAttachment) { selected in
                RecordMediaViewer(
                    attachments: visualAttachments,
                    initialAttachmentID: selected.id,
                    store: store
                )
            }
        }
    }

    private var visualAttachments: [RecordAttachment] {
        attachments.filter {
            [.photo, .drawing, .pixelArt, .stickerArtwork]
                .contains($0.kind)
        }
    }
}

struct RecordAttachmentView: View {
    let attachment: RecordAttachment
    let store: RecordMediaStore
    var onDelete: (() -> Void)? = nil
    var onOpen: (() -> Void)? = nil

    @State private var image: UIImage?
    @State private var videoURL: URL?
    @State private var showsVideo = false
    @State private var isExportingVideo = false
    @State private var videoExportMessage: String?
    @State private var videoExportError: String?

    var body: some View {
        Group {
            switch attachment.kind {
            case .photo, .drawing, .pixelArt, .stickerArtwork:
                Button {
                    onOpen?()
                } label: {
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 112, height: 112)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    } else {
                        placeholder(systemImage: "photo")
                    }
                }
                .buttonStyle(.plain)
                .disabled(onOpen == nil)
                .accessibilityLabel("查看大图")
            case .video:
                Button {
                    Task {
                        videoURL = try? await store.url(for: attachment)
                        showsVideo = videoURL != nil
                    }
                } label: {
                    placeholder(systemImage: "play.rectangle.fill")
                }
                .buttonStyle(.plain)
            case .audio:
                AudioAttachmentPlayer(
                    attachment: attachment,
                    store: store
                )
            }
        }
        .overlay(alignment: .topTrailing) {
            if let onDelete {
                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.trellisBone)
                        .frame(width: 26, height: 26)
                        .background(Color.black.opacity(0.72))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(5)
                .accessibilityLabel("移除附件")
            }
        }
        .task(id: attachment.id) {
            guard [.photo, .drawing, .pixelArt, .stickerArtwork]
                .contains(attachment.kind),
                let data = try? await store.data(for: attachment)
            else {
                return
            }
            image = UIImage(data: data)
        }
        .fullScreenCover(isPresented: $showsVideo) {
            if let videoURL {
                NavigationStack {
                    VideoPlayer(player: AVPlayer(url: videoURL))
                        .ignoresSafeArea()
                        .navigationTitle("视频记录")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button {
                                    exportVideo()
                                } label: {
                                    if isExportingVideo {
                                        ProgressView()
                                    } else {
                                        Image(
                                            systemName:
                                                "square.and.arrow.down"
                                        )
                                    }
                                }
                                .disabled(isExportingVideo)
                                .accessibilityLabel("保存视频到相册")
                            }

                            ToolbarItem(placement: .confirmationAction) {
                                Button("完成") {
                                    showsVideo = false
                                }
                            }
                        }
                        .overlay(alignment: .bottom) {
                            if let videoExportMessage {
                                Text(videoExportMessage)
                                    .font(.callout.weight(.semibold))
                                    .foregroundStyle(Color.trellisBone)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        Color.trellisJade.opacity(0.92)
                                    )
                                    .clipShape(Capsule())
                                    .padding(.bottom, 24)
                            }
                        }
                }
            }
        }
        .alert(
            "无法导出",
            isPresented: Binding(
                get: { videoExportError != nil },
                set: { if !$0 { videoExportError = nil } }
            )
        ) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text(videoExportError ?? "")
        }
    }

    private func placeholder(systemImage: String) -> some View {
        Image(systemName: systemImage)
            .font(.system(size: 30, weight: .light))
            .foregroundStyle(Color.trellisBrass)
            .frame(width: 112, height: 112)
            .background(Color.black.opacity(0.18))
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func exportVideo() {
        isExportingVideo = true
        Task {
            do {
                try await RecordMediaExporter.saveToPhotos(
                    attachment: attachment,
                    store: store
                )
                withAnimation {
                    videoExportMessage = "已保存到系统相册"
                }
                try? await Task.sleep(for: .seconds(1.8))
                withAnimation {
                    videoExportMessage = nil
                }
            } catch {
                videoExportError = (error as? LocalizedError)?.errorDescription
                    ?? RecordMediaExportError.saveFailed.errorDescription
            }
            isExportingVideo = false
        }
    }
}

private struct AudioAttachmentPlayer: View {
    @Environment(LocalAudioPlayer.self) private var audioPlayer

    let attachment: RecordAttachment
    let store: RecordMediaStore

    var body: some View {
        Button {
            Task {
                await audioPlayer.toggle(
                    attachment: attachment,
                    store: store
                )
            }
        } label: {
            VStack(spacing: 8) {
                Image(
                    systemName: isPlaying
                        ? "pause.circle.fill"
                        : "play.circle.fill"
                )
                .font(.system(size: 34))

                Text(durationText)
                    .font(.caption.monospacedDigit())
            }
            .foregroundStyle(Color.trellisBrass)
            .frame(width: 112, height: 112)
            .background(Color.black.opacity(0.18))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }

    private var isPlaying: Bool {
        audioPlayer.state.attachmentID == attachment.id
            && audioPlayer.state.isPlaying
    }

    private var durationText: String {
        guard let duration = attachment.durationSeconds else {
            return "语音"
        }
        return String(
            format: "%02d:%02d",
            Int(duration) / 60,
            Int(duration) % 60
        )
    }
}
