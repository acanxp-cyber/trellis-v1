import Foundation

enum RecordStudioActionID: String, CaseIterable, Identifiable, Sendable {
    case camera
    case video
    case library
    case voice
    case drawing
    case pixelArt
    case stickers
    case englishReading

    var id: String { rawValue }
}

struct RecordStudioActionDescriptor: Identifiable, Equatable, Sendable {
    let id: RecordStudioActionID
    let title: String
    let detail: String
    let systemImage: String

    var isCreative: Bool {
        [.drawing, .pixelArt, .stickers, .englishReading].contains(id)
    }
}

enum RecordStudioActionCatalog {
    static let all: [RecordStudioActionDescriptor] = [
        .init(
            id: .camera,
            title: "拍照",
            detail: "用相机留下此刻",
            systemImage: "camera.fill"
        ),
        .init(
            id: .video,
            title: "录像",
            detail: "拍一段本地视频",
            systemImage: "video.fill"
        ),
        .init(
            id: .library,
            title: "照片与视频",
            detail: "从相册选择素材",
            systemImage: "photo.on.rectangle"
        ),
        .init(
            id: .voice,
            title: "语音记录",
            detail: "录下声音并反复回放",
            systemImage: "waveform"
        ),
        .init(
            id: .drawing,
            title: "手绘涂鸦",
            detail: "黑板、粉笔与书法笔",
            systemImage: "pencil.tip.crop.circle"
        ),
        .init(
            id: .englishReading,
            title: "英语朗读",
            detail: "100 篇随机短文与录音",
            systemImage: "text.book.closed.fill"
        ),
        .init(
            id: .pixelArt,
            title: "像素画布",
            detail: "大小网格与多尺寸笔刷",
            systemImage: "square.grid.3x3.fill"
        ),
        .init(
            id: .stickers,
            title: "手作贴纸",
            detail: "拖动、缩放和旋转",
            systemImage: "face.smiling"
        ),
    ]

    static var creative: [RecordStudioActionDescriptor] {
        all.filter(\.isCreative)
    }
}
