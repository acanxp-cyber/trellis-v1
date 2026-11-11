@preconcurrency import AVFoundation
import Foundation
import Observation
@preconcurrency import Speech

@MainActor
@Observable
final class VoiceTaskCaptureModel {
    private(set) var transcript = ""
    private(set) var isRecording = false
    private(set) var isStarting = false
    var drafts: [VoiceTaskDraft] = []
    var errorMessage: String?

    private let parser = VoiceTaskParser()
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var recognizer: SFSpeechRecognizer?
    private var isStopping = false
    private var hasInstalledTap = false

    var canSave: Bool {
        !drafts.isEmpty
    }

    func start() async {
        guard !isRecording, !isStarting else {
            return
        }

        isStarting = true
        errorMessage = nil
        resetResult()
        defer { isStarting = false }

        guard await requestSpeechPermission(), await requestMicrophonePermission() else {
            errorMessage = "需要麦克风和语音识别权限，才能把口述内容拆成任务。"
            return
        }

        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
        guard
            let recognizer,
            recognizer.isAvailable,
            recognizer.supportsOnDeviceRecognition
        else {
            errorMessage = "当前设备暂时不支持中文离线语音识别。"
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(
                .record,
                mode: .measurement,
                options: .duckOthers
            )
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            request.requiresOnDeviceRecognition = true
            request.addsPunctuation = true

            let engine = AVAudioEngine()
            let inputNode = engine.inputNode
            let format = inputNode.outputFormat(forBus: 0)
            guard format.channelCount > 0 else {
                throw VoiceCaptureError.noAudioInput
            }

            inputNode.installTap(
                onBus: 0,
                bufferSize: 1_024,
                format: format
            ) { buffer, _ in
                request.append(buffer)
            }
            hasInstalledTap = true

            engine.prepare()
            try engine.start()

            self.audioEngine = engine
            self.recognitionRequest = request
            self.recognizer = recognizer
            self.isStopping = false
            self.isRecording = true

            recognitionTask = recognizer.recognitionTask(
                with: request
            ) { [weak self] result, error in
                Task { @MainActor in
                    guard let self else {
                        return
                    }

                    if let result {
                        self.transcript = result.bestTranscription.formattedString
                        if result.isFinal {
                            self.parseTranscriptIfNeeded()
                        }
                    }

                    if let error, !self.isStopping {
                        self.errorMessage = Self.message(for: error)
                        self.stopAudio()
                        self.isRecording = false
                    }
                }
            }
        } catch {
            stopAudio()
            errorMessage = "无法启动录音，请稍后重试。"
        }
    }

    func stop() {
        guard isRecording else {
            parseTranscriptIfNeeded()
            return
        }
        isStopping = true
        stopAudio()
        isRecording = false
        parseTranscriptIfNeeded(force: true)
    }

    func cancel() {
        isStopping = true
        stopAudio()
        isRecording = false
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        try? AVAudioSession.sharedInstance().setActive(
            false,
            options: .notifyOthersOnDeactivation
        )
    }

    func reset() {
        cancel()
        transcript = ""
        drafts = []
        errorMessage = nil
    }

    private func parseTranscriptIfNeeded(force: Bool = false) {
        if !force, !drafts.isEmpty {
            return
        }

        let parsed = parser.parse(transcript)
        drafts = parsed
        if parsed.isEmpty {
            errorMessage = transcript.isEmpty
                ? "没有听清，请再说一次。"
                : "没有识别到清楚的时间。请说“2点开会”或“下午4点去跑步”这样的时间加任务。"
        }
    }

    private func resetResult() {
        transcript = ""
        drafts = []
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
    }

    private func stopAudio() {
        audioEngine?.stop()
        if hasInstalledTap {
            audioEngine?.inputNode.removeTap(onBus: 0)
            hasInstalledTap = false
        }
        audioEngine = nil
        recognitionRequest?.endAudio()
    }

    private func requestSpeechPermission() async -> Bool {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            return true
        case .denied, .restricted:
            return false
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { status in
                    continuation.resume(returning: status == .authorized)
                }
            }
        @unknown default:
            return false
        }
    }

    private func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    private static func message(for error: Error) -> String {
        let nsError = error as NSError
        if nsError.domain == "kAFAssistantErrorDomain" {
            return "没有听清，请靠近手机再说一次。"
        }
        return "语音识别中断了，请重试。"
    }
}

private enum VoiceCaptureError: Error {
    case noAudioInput
}
