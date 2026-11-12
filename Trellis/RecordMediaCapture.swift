import AVFoundation
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
