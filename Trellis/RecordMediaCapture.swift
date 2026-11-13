import AVFoundation
import CoreImage
import CoreImage.CIFilterBuiltins
import Observation
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct CapturedRecordMedia {
    let data: Data
    let kind: RecordAttachmentKind
    let fileExtension: String
    let durationSeconds: Double?
}

enum RecordCameraMode {
    case photo
    case video
}

enum PhotoFilterPreset: String, CaseIterable, Identifiable, Sendable {
    case warmLife
    case clearDaily
    case softFilm
    case silverBlack
    case oldMemory
    case cinematicTealOrange
    case goldenDusk
    case coolBlue

    var id: String { rawValue }

    var title: String {
        switch self {
        case .warmLife:
            return "暖阳生活"
        case .clearDaily:
            return "清透日常"
        case .softFilm:
            return "柔光胶片"
        case .silverBlack:
            return "银盐黑白"
        case .oldMemory:
            return "旧时记忆"
        case .cinematicTealOrange:
            return "电影青橙"
        case .goldenDusk:
            return "金色暮光"
        case .coolBlue:
            return "清冷蓝调"
        }
    }
}

struct PhotoEditRequest: Identifiable {
    let id = UUID()
    let data: Data
}

@MainActor
enum PhotoFilterRenderer {
    private static let context = CIContext()

    static func render(
        data: Data,
        preset: PhotoFilterPreset
    ) -> Data? {
        guard
            let image = UIImage(data: data),
            let normalized = normalizedImage(image),
            let input = CIImage(image: normalized)
        else {
            return nil
        }

        let output = applying(preset, to: input)
        guard let cgImage = context.createCGImage(
            output,
            from: output.extent
        ) else {
            return nil
        }
        return UIImage(cgImage: cgImage).jpegData(
            compressionQuality: 0.9
        )
    }

    private static func applying(
        _ preset: PhotoFilterPreset,
        to input: CIImage
    ) -> CIImage {
        switch preset {
        case .warmLife:
            return color(
                temperature(
                    controls(input, saturation: 1.08, contrast: 1.04),
                    target: 7_200
                ),
                brightness: 0.02
            )
        case .clearDaily:
            return color(
                controls(input, saturation: 1.03, contrast: 1.08),
                brightness: 0.04
            )
        case .softFilm:
            return softGlow(
                color(
                    controls(input, saturation: 0.92, contrast: 0.96),
                    brightness: 0.035
                )
            )
        case .silverBlack:
            let noir = CIFilter.photoEffectNoir()
            noir.inputImage = input
            return controls(
                noir.outputImage ?? input,
                saturation: 1,
                contrast: 1.1
            )
        case .oldMemory:
            let transfer = CIFilter.photoEffectTransfer()
            transfer.inputImage = input
            let vignette = CIFilter.vignette()
            vignette.inputImage = transfer.outputImage ?? input
            vignette.intensity = 0.75
            vignette.radius = 1.8
            return vignette.outputImage ?? input
        case .cinematicTealOrange:
            return vignette(
                color(
                    controls(input, saturation: 1.12, contrast: 1.12),
                    brightness: -0.01
                )
            )
        case .goldenDusk:
            return vignette(
                color(
                    temperature(
                        controls(input, saturation: 1.04, contrast: 1.05),
                        target: 7_800
                    ),
                    brightness: 0.025
                )
            )
        case .coolBlue:
            return color(
                temperature(
                    controls(input, saturation: 0.9, contrast: 1.08),
                    target: 5_600
                ),
                brightness: -0.01
            )
        }
    }

    private static func controls(
        _ image: CIImage,
        saturation: Float,
        contrast: Float
    ) -> CIImage {
        let filter = CIFilter.colorControls()
        filter.inputImage = image
        filter.saturation = saturation
        filter.contrast = contrast
        return filter.outputImage ?? image
    }

    private static func color(
        _ image: CIImage,
        brightness: Float
    ) -> CIImage {
        let filter = CIFilter.colorControls()
        filter.inputImage = image
        filter.brightness = brightness
        return filter.outputImage ?? image
    }

    private static func temperature(
        _ image: CIImage,
        target: CGFloat
    ) -> CIImage {
        let filter = CIFilter.temperatureAndTint()
        filter.inputImage = image
        filter.neutral = CIVector(x: 6_500, y: 0)
        filter.targetNeutral = CIVector(x: target, y: 0)
        return filter.outputImage ?? image
    }

    private static func softGlow(_ image: CIImage) -> CIImage {
        let bloom = CIFilter.bloom()
        bloom.inputImage = image
        bloom.intensity = 0.22
        bloom.radius = 7
        return bloom.outputImage ?? image
    }

    private static func vignette(_ image: CIImage) -> CIImage {
        let filter = CIFilter.vignette()
        filter.inputImage = image
        filter.intensity = 0.55
        filter.radius = 2
        return filter.outputImage ?? image
    }

    private static func normalizedImage(_ image: UIImage) -> UIImage? {
        guard image.imageOrientation != .up else {
            return image
        }
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        format.opaque = true
        return UIGraphicsImageRenderer(
            size: image.size,
            format: format
        ).image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }
}

struct PhotoFilterEditorView: View {
    let sourceData: Data
    let onSave: (Data) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selected: PhotoFilterPreset = .warmLife
    @State private var previewData: Data?
    @State private var isRendering = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Group {
                    if let previewData, let image = UIImage(data: previewData) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                    } else {
                        ProgressView("正在处理照片")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 9) {
                        ForEach(PhotoFilterPreset.allCases) { preset in
                            Button {
                                selected = preset
                            } label: {
                                Text(preset.title)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(
                                        selected == preset
                                            ? Color.trellisInk
                                            : Color.trellisBone
                                    )
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        selected == preset
                                            ? Color.trellisBrass
                                            : Color.trellisPlate
                                    )
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }

                Text("滤镜只在本机处理；保存后会写入本地记录。")
                    .font(.caption)
                    .foregroundStyle(Color.trellisAsh)
                    .padding(.bottom, 8)
            }
            .background(Color.trellisInk.ignoresSafeArea())
            .navigationTitle("照片滤镜")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        guard let output = PhotoFilterRenderer.render(
                            data: sourceData,
                            preset: selected
                        ) else {
                            return
                        }
                        onSave(output)
                        dismiss()
                    }
                    .disabled(previewData == nil || isRendering)
                }
            }
            .task(id: selected) {
                isRendering = true
                previewData = PhotoFilterRenderer.render(
                    data: sourceData,
                    preset: selected
                )
                isRendering = false
            }
        }
    }
}

struct RecordCameraPicker: UIViewControllerRepresentable {
    let mode: RecordCameraMode
    let onCapture: (CapturedRecordMedia) -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture, onCancel: onCancel)
    }

    func makeUIViewController(
        context: Context
    ) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.mediaTypes = [
            mode == .photo ? UTType.image.identifier : UTType.movie.identifier,
        ]
        return picker
    }

    func updateUIViewController(
        _ uiViewController: UIImagePickerController,
        context: Context
    ) {}

    final class Coordinator: NSObject,
        UIImagePickerControllerDelegate,
        UINavigationControllerDelegate
    {
        private let onCapture: (CapturedRecordMedia) -> Void
        private let onCancel: () -> Void

        init(
            onCapture: @escaping (CapturedRecordMedia) -> Void,
            onCancel: @escaping () -> Void
        ) {
            self.onCapture = onCapture
            self.onCancel = onCancel
        }

        func imagePickerControllerDidCancel(
            _ picker: UIImagePickerController
        ) {
            onCancel()
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [
                UIImagePickerController.InfoKey: Any
            ]
        ) {
            if let image = info[.originalImage] as? UIImage,
               let data = image.jpegData(compressionQuality: 0.9)
            {
                onCapture(
                    CapturedRecordMedia(
                        data: data,
                        kind: .photo,
                        fileExtension: "jpg",
                        durationSeconds: nil
                    )
                )
                return
            }

            if let url = info[.mediaURL] as? URL,
               let data = try? Data(contentsOf: url)
            {
                onCapture(
                    CapturedRecordMedia(
                        data: data,
                        kind: .video,
                        fileExtension: url.pathExtension.isEmpty
                            ? "mov"
                            : url.pathExtension,
                        durationSeconds: nil
                    )
                )
                return
            }
            onCancel()
        }
    }
}

struct MovieFileTransfer: Transferable {
    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .movie) {
            MovieFileTransfer(data: $0)
        }
    }
}

@MainActor
@Observable
final class VoiceMemoRecorder {
    private(set) var isRecording = false
    private(set) var elapsedSeconds = 0
    var errorMessage: String?

    private var recorder: AVAudioRecorder?
    private var fileURL: URL?
    private var timerTask: Task<Void, Never>?

    func start() async -> Bool {
        let granted = await VoiceCapturePermissions.value { finish in
            AVAudioApplication.requestRecordPermission { granted in
                finish(granted)
            }
        }
        guard granted else {
            errorMessage = "需要麦克风权限才能录音。"
            return false
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(
                .playAndRecord,
                mode: .spokenAudio,
                options: [.defaultToSpeaker]
            )
            try session.setActive(true)

            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(UUID().uuidString).m4a")
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            ]
            let recorder = try AVAudioRecorder(
                url: url,
                settings: settings
            )
            recorder.record()
            self.recorder = recorder
            fileURL = url
            elapsedSeconds = 0
            isRecording = true
            errorMessage = nil

            timerTask?.cancel()
            timerTask = Task { [weak self] in
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(1))
                    guard let self, self.isRecording else {
                        return
                    }
                    self.elapsedSeconds += 1
                }
            }
            return true
        } catch {
            errorMessage = "录音启动失败，请稍后重试。"
            return false
        }
    }

    func stop() -> CapturedRecordMedia? {
        recorder?.stop()
        recorder = nil
        timerTask?.cancel()
        timerTask = nil
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(
            false,
            options: .notifyOthersOnDeactivation
        )

        guard let fileURL else {
            return nil
        }
        defer {
            try? FileManager.default.removeItem(at: fileURL)
            self.fileURL = nil
        }
        guard let data = try? Data(contentsOf: fileURL) else {
            errorMessage = "没有读取到录音内容。"
            return nil
        }
        return CapturedRecordMedia(
            data: data,
            kind: .audio,
            fileExtension: "m4a",
            durationSeconds: Double(elapsedSeconds)
        )
    }

    func cancel() {
        recorder?.stop()
        recorder = nil
        timerTask?.cancel()
        timerTask = nil
        isRecording = false
        if let fileURL {
            try? FileManager.default.removeItem(at: fileURL)
        }
        fileURL = nil
        try? AVAudioSession.sharedInstance().setActive(
            false,
            options: .notifyOthersOnDeactivation
        )
    }
}

struct VoiceMemoSheet: View {
    let onSave: (CapturedRecordMedia) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var recorder = VoiceMemoRecorder()

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(
                    systemName: recorder.isRecording
                        ? "waveform.circle.fill"
                        : "mic.circle"
                )
                .font(.system(size: 96, weight: .light))
                .foregroundStyle(
                    recorder.isRecording
                        ? Color.trellisDanger
                        : Color.trellisBrass
                )
                .symbolEffect(
                    .pulse,
                    options: .repeating,
                    isActive: recorder.isRecording
                )

                Text(
                    recorder.isRecording
                        ? durationText
                        : "录一段语音记录"
                )
                .font(.system(.title2, design: .serif))
                .foregroundStyle(Color.trellisBone)

                Text("只保存在本机，不会上传。")
                    .font(.caption)
                    .foregroundStyle(Color.trellisAsh)

                if let error = recorder.errorMessage {
                    Text(error)
                        .font(.callout)
                        .foregroundStyle(Color.trellisDanger)
                }

                Spacer()

                Button {
                    Task {
                        if recorder.isRecording {
                            if let media = recorder.stop() {
                                onSave(media)
                                dismiss()
                            }
                        } else {
                            _ = await recorder.start()
                        }
                    }
                } label: {
                    Text(
                        recorder.isRecording
                            ? "停止并添加"
                            : "开始录音"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(
                    recorder.isRecording
                        ? Color.trellisDanger
                        : Color.trellisBrass
                )
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 24)
            .background(Color.trellisInk.ignoresSafeArea())
            .navigationTitle("语音记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        recorder.cancel()
                        dismiss()
                    }
                }
            }
        }
        .onDisappear {
            recorder.cancel()
        }
    }

    private var durationText: String {
        String(
            format: "%02d:%02d",
            recorder.elapsedSeconds / 60,
            recorder.elapsedSeconds % 60
        )
    }
}
