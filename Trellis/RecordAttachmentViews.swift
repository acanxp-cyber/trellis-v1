import AVFoundation
import AVKit
import SwiftUI
import UIKit

struct RecordAttachmentStrip: View {
    let attachments: [RecordAttachment]
    let store: RecordMediaStore?
    var onDelete: ((RecordAttachment) -> Void)? = nil

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
                            }
                        )
                    }
                }
            }
        }
    }
}

struct RecordAttachmentView: View {
    let attachment: RecordAttachment
    let store: RecordMediaStore
    var onDelete: (() -> Void)? = nil

    @State private var image: UIImage?
    @State private var videoURL: URL?
    @State private var showsVideo = false

    var body: some View {
        Group {
            switch attachment.kind {
            case .photo, .drawing, .pixelArt, .stickerArtwork:
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 112, height: 112)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    placeholder(systemImage: "photo")
                }
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
                            ToolbarItem(placement: .confirmationAction) {
                                Button("完成") {
                                    showsVideo = false
                                }
                            }
                        }
                }
            }
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
