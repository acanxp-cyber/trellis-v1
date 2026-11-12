import AVFoundation
import AVKit
import SwiftUI
import UIKit

struct RecordAttachmentStrip: View {
    let attachments: [RecordAttachment]
    let store: RecordMediaStore?

    var body: some View {
        if !attachments.isEmpty, let store {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(attachments) { attachment in
                        RecordAttachmentView(
                            attachment: attachment,
                            store: store
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
    let attachment: RecordAttachment
    let store: RecordMediaStore

    @State private var player: AVAudioPlayer?
    @State private var isPlaying = false

    var body: some View {
        Button {
            Task {
                if player == nil {
                    guard
                        let data = try? await store.data(for: attachment),
                        let created = try? AVAudioPlayer(data: data)
                    else {
                        return
                    }
                    created.prepareToPlay()
                    player = created
                }
                if isPlaying {
                    player?.pause()
                } else {
                    player?.play()
                }
                isPlaying.toggle()
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
