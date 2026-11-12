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
    private(set) var statusMessage: String?
    var drafts: [VoiceTaskDraft] = []
    var errorMessage: String?

    private let parser = VoiceTaskParser()
    private var modernSession: AnyObject?
    private var audioEngine: AVAudioEngine?
    private var hasInstalledTap = false
    private var isStopping = false

    private var legacyRequest: SFSpeechAudioBufferRecognitionRequest?
    private var legacyTask: SFSpeechRecognitionTask?
    private var legacyRecognizer: SFSpeechRecognizer?

    var canSave: Bool {
        !drafts.isEmpty
    }

    func start() async {
        guard !isRecording, !isStarting else {
            return
        }

        isStarting = true
        errorMessage = nil
        statusMessage = nil
        resetResult()
        resetActiveCapture()
        defer { isStarting = false }

        guard await VoiceCapturePermissions.requestSpeechRecognition(),
              await VoiceCapturePermissions.requestMicrophone()
        else {
            errorMessage = "需要麦克风和语音识别权限。请到系统设置中允许后重试。"
            return
        }

        do {
            if #available(iOS 26.0, *) {
                statusMessage = "正在准备中文离线语音模型…"
                let session = ModernSpeechCaptureSession(
                    onTranscript: { [weak self] text in
                        self?.transcript = text
                    },
                    onError: { [weak self] message in
                        self?.errorMessage = message
                        self?.isRecording = false
                    }
                )
                modernSession = session
                try await session.start()
                statusMessage = nil
            } else {
                try startLegacyCapture()
            }
            isRecording = true
        } catch {
            resetActiveCapture()
            isRecording = false
            statusMessage = nil
            errorMessage = Self.message(for: error)
        }
    }

    func stop() async {
        guard isRecording, !isStopping else {
            return
        }

        isStopping = true
        isStarting = true
        isRecording = false

        if #available(iOS 26.0, *),
           let session = modernSession as? ModernSpeechCaptureSession {
            transcript = await session.finish()
            modernSession = nil
        } else {
            stopLegacyCapture()
        }

        isStarting = false
        isStopping = false
        statusMessage = nil
        parseTranscriptIfNeeded(force: true)
    }

    func cancel() {
        resetActiveCapture()
        isRecording = false
        isStarting = false
        isStopping = false
        statusMessage = nil
    }

    func reset() {
        cancel()
        transcript = ""
        drafts = []
        errorMessage = nil
    }

    private func startLegacyCapture() throws {
        let recognizer = SFSpeechRecognizer(
            locale: Locale(identifier: "zh-CN")
        )
        guard
            let recognizer,
            recognizer.isAvailable,
            recognizer.supportsOnDeviceRecognition
        else {
            throw VoiceCaptureError.modelUnavailable
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = true
        request.addsPunctuation = true

        try startAudioCapture(
            handler: Self.makeLegacyTapHandler(for: request)
        )

        legacyRecognizer = recognizer
        legacyRequest = request
        legacyTask = recognizer.recognitionTask(
            with: request
        ) { [weak self] result, error in
            Task { @MainActor in
                guard let self else {
                    return
                }
                if let result {
                    self.transcript = result.bestTranscription.formattedString
                    if result.isFinal {
                        self.parseTranscriptIfNeeded(force: true)
                    }
                }
                if let error, !self.isStopping {
                    self.errorMessage = Self.message(for: error)
                    self.stopAudioCapture()
                    self.isRecording = false
                }
            }
        }
    }

    private func stopLegacyCapture() {
        stopAudioCapture()
        legacyRequest?.endAudio()
        legacyTask?.cancel()
        legacyTask = nil
        legacyRequest = nil
        legacyRecognizer = nil
        deactivateAudioSession()
    }

    private func startAudioCapture(
        handler: AVAudioNodeTapBlock
    ) throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(
            .playAndRecord,
            mode: .spokenAudio,
            options: [.duckOthers]
        )
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let format = inputNode.inputFormat(forBus: 0)
        guard
            format.sampleRate > 0,
            format.channelCount > 0
        else {
            throw VoiceCaptureError.noAudioInput
        }

        inputNode.installTap(
            onBus: 0,
            bufferSize: 4_096,
            format: format,
            block: handler
        )
        hasInstalledTap = true
        audioEngine = engine
        engine.prepare()

        do {
            try engine.start()
        } catch {
            stopAudioCapture()
            throw VoiceCaptureError.audioEngineFailed
        }
    }

    private func stopAudioCapture() {
        audioEngine?.stop()
        if hasInstalledTap, let audioEngine {
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        hasInstalledTap = false
        audioEngine = nil
    }

    private func deactivateAudioSession() {
        try? AVAudioSession.sharedInstance().setActive(
            false,
            options: .notifyOthersOnDeactivation
        )
    }

    private func resetActiveCapture() {
        if #available(iOS 26.0, *),
           let session = modernSession as? ModernSpeechCaptureSession {
            session.cancel()
        }
        modernSession = nil
        stopLegacyCapture()
    }

    private func resetResult() {
        transcript = ""
        drafts = []
    }

    private nonisolated static func makeLegacyTapHandler(
        for request: SFSpeechAudioBufferRecognitionRequest
    ) -> AVAudioNodeTapBlock {
        { buffer, _ in
            request.append(buffer)
        }
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

    private static func message(for error: Error) -> String {
        if let error = error as? VoiceCaptureError {
            return error.userMessage
        }
        if #available(iOS 26.0, *),
           let error = error as? ModernSpeechError {
            return error.userMessage
        }

        let nsError = error as NSError
        if nsError.domain == "kAFAssistantErrorDomain" {
            return "没有听清，请靠近手机再说一次。"
        }
        return "语音识别中断了，请重试。"
    }
}

enum VoiceCapturePermissions {
    static func requestSpeechRecognition() async -> Bool {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            return true
        case .denied, .restricted:
            return false
        case .notDetermined:
            return await value { finish in
                SFSpeechRecognizer.requestAuthorization { status in
                    finish(status == .authorized)
                }
            }
        @unknown default:
            return false
        }
    }

    static func requestMicrophone() async -> Bool {
        await value { finish in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                finish(granted)
            }
        }
    }

    static func value(
        from request: @escaping @Sendable (
            @escaping @Sendable (Bool) -> Void
        ) -> Void
    ) async -> Bool {
        await withCheckedContinuation { continuation in
            request { result in
                continuation.resume(returning: result)
            }
        }
    }
}

private enum VoiceCaptureError: Error {
    case modelUnavailable
    case noAudioInput
    case audioEngineFailed

    var userMessage: String {
        switch self {
        case .modelUnavailable:
            return "当前系统的旧版语音组件不支持中文离线转写。请更新到 iOS 26 后重试。"
        case .noAudioInput:
            return "没有检测到可用麦克风，请稍后重试。"
        case .audioEngineFailed:
            return "麦克风启动失败，请关闭其他录音应用后重试。"
        }
    }
}
