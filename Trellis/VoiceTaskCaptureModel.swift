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
    private let bufferConverter = AudioBufferConverter()

    private var audioEngine: AVAudioEngine?
    private var hasInstalledTap = false
    private var isStopping = false

    @available(iOS 26.0, *)
    private var speechAnalyzer: SpeechAnalyzer?
    @available(iOS 26.0, *)
    private var speechTranscriber: SpeechTranscriber?
    @available(iOS 26.0, *)
    private var analyzerInputBuilder: AsyncStream<AnalyzerInput>.Continuation?
    @available(iOS 26.0, *)
    private var analyzerFormat: AVAudioFormat?
    @available(iOS 26.0, *)
    private var analyzerResultTask: Task<Void, Never>?
    @available(iOS 26.0, *)
    private var audioInputBuilder: AsyncStream<AVAudioPCMBuffer>.Continuation?
    @available(iOS 26.0, *)
    private var audioPipelineTask: Task<Void, Never>?
    @available(iOS 26.0, *)
    private var finalizedText = ""
    @available(iOS 26.0, *)
    private var volatileText = ""

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
        defer { isStarting = false }

        guard await requestSpeechPermission(), await requestMicrophonePermission() else {
            errorMessage = "需要麦克风和语音识别权限。请到系统设置中允许后重试。"
            return
        }

        do {
            if #available(iOS 26.0, *) {
                try await startModernCapture()
            } else {
                try startLegacyCapture()
            }
            isRecording = true
        } catch {
            resetActiveCapture()
            isRecording = false
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

        if #available(iOS 26.0, *) {
            await finishModernCapture()
        } else {
            stopLegacyCapture()
        }

        isStarting = false
        isStopping = false
        parseTranscriptIfNeeded(force: true)
    }

    func cancel() {
        resetActiveCapture()
        isRecording = false
        isStarting = false
        isStopping = false
    }

    func reset() {
        cancel()
        transcript = ""
        drafts = []
        errorMessage = nil
        statusMessage = nil
    }

    @available(iOS 26.0, *)
    private func startModernCapture() async throws {
        guard SpeechTranscriber.isAvailable else {
            throw VoiceCaptureError.modelUnavailable
        }

        let requestedLocale = Locale(identifier: "zh-CN")
        let supportedLocales = await SpeechTranscriber.supportedLocales
        guard let locale = SpeechLocaleSupport.match(
            requestedLocale,
            in: supportedLocales
        ) else {
            throw VoiceCaptureError.localeUnavailable
        }

        let transcriber = SpeechTranscriber(
            locale: locale,
            transcriptionOptions: [],
            reportingOptions: [.volatileResults],
            attributeOptions: []
        )

        let installedLocales = await SpeechTranscriber.installedLocales
        if SpeechLocaleSupport.match(locale, in: installedLocales) == nil {
            statusMessage = "首次使用，正在下载中文离线语音模型…"
            if let request = try await AssetInventory.assetInstallationRequest(
                supporting: [transcriber]
            ) {
                try await request.downloadAndInstall()
            }
        }

        guard let format = await SpeechAnalyzer.bestAvailableAudioFormat(
            compatibleWith: [transcriber]
        ) else {
            throw VoiceCaptureError.audioFormatUnavailable
        }

        statusMessage = "正在启动麦克风…"
        let analyzer = SpeechAnalyzer(modules: [transcriber])
        let (inputSequence, inputBuilder) = AsyncStream<AnalyzerInput>
            .makeStream(bufferingPolicy: .unbounded)

        speechTranscriber = transcriber
        speechAnalyzer = analyzer
        analyzerInputBuilder = inputBuilder
        analyzerFormat = format
        finalizedText = ""
        volatileText = ""

        analyzerResultTask = Task { [weak self] in
            do {
                for try await result in transcriber.results {
                    guard let self else {
                        return
                    }
                    self.consume(result)
                }
            } catch {
                guard let self, !self.isStopping else {
                    return
                }
                self.errorMessage = Self.message(for: error)
                self.stopAudioCapture()
            }
        }

        try await analyzer.start(inputSequence: inputSequence)

        let (audioStream, audioBuilder) = AsyncStream<AVAudioPCMBuffer>
            .makeStream(bufferingPolicy: .unbounded)
        audioInputBuilder = audioBuilder
        audioPipelineTask = Task { [weak self] in
            for await buffer in audioStream {
                guard let self else {
                    return
                }
                self.consumeAudio(buffer)
            }
        }

        try startAudioCapture { buffer in
            audioBuilder.yield(buffer)
        }
        statusMessage = nil
    }

    @available(iOS 26.0, *)
    private func consume(_ result: SpeechTranscriber.Result) {
        let text = String(result.text.characters)
        if result.isFinal {
            finalizedText += text
            volatileText = ""
        } else {
            volatileText = text
        }
        transcript = finalizedText + volatileText
    }

    @available(iOS 26.0, *)
    private func consumeAudio(_ buffer: AVAudioPCMBuffer) {
        guard
            let analyzerInputBuilder,
            let analyzerFormat
        else {
            return
        }

        do {
            let converted = try bufferConverter.convert(
                buffer,
                to: analyzerFormat
            )
            analyzerInputBuilder.yield(
                AnalyzerInput(buffer: converted)
            )
        } catch {
            guard !isStopping else {
                return
            }
            errorMessage = "语音转写中断了，请重试。"
            stopAudioCapture()
            isRecording = false
        }
    }

    @available(iOS 26.0, *)
    private func finishModernCapture() async {
        stopAudioCapture()
        audioInputBuilder?.finish()
        audioInputBuilder = nil
        audioPipelineTask?.cancel()
        audioPipelineTask = nil
        analyzerInputBuilder?.finish()
        analyzerInputBuilder = nil

        do {
            try await speechAnalyzer?.finalizeAndFinishThroughEndOfInput()
        } catch {
            errorMessage = "语音转写结束失败，请重试。"
        }

        try? await Task.sleep(for: .milliseconds(250))
        analyzerResultTask?.cancel()
        analyzerResultTask = nil
        speechAnalyzer = nil
        speechTranscriber = nil
        analyzerFormat = nil
        finalizedText = ""
        volatileText = ""
        deactivateAudioSession()
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

        try startAudioCapture { [weak self] buffer in
            request.append(buffer)
        }

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
        onBuffer: @escaping (AVAudioPCMBuffer) -> Void
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
            format: format
        ) { buffer, _ in
            onBuffer(buffer)
        }
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
        if #available(iOS 26.0, *) {
            stopAudioCapture()
            audioInputBuilder?.finish()
            audioInputBuilder = nil
            audioPipelineTask?.cancel()
            audioPipelineTask = nil
            analyzerInputBuilder?.finish()
            analyzerInputBuilder = nil
            analyzerResultTask?.cancel()
            analyzerResultTask = nil
            speechAnalyzer = nil
            speechTranscriber = nil
            analyzerFormat = nil
            finalizedText = ""
            volatileText = ""
        } else {
            stopLegacyCapture()
        }
        deactivateAudioSession()
    }

    private func resetResult() {
        transcript = ""
        drafts = []
        if #available(iOS 26.0, *) {
            finalizedText = ""
            volatileText = ""
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
        if let error = error as? VoiceCaptureError {
            return error.userMessage
        }

        let nsError = error as NSError
        if nsError.domain == "kAFAssistantErrorDomain" {
            return "没有听清，请靠近手机再说一次。"
        }
        return "语音识别中断了，请重试。"
    }
}

private enum VoiceCaptureError: Error {
    case modelUnavailable
    case localeUnavailable
    case noAudioInput
    case audioFormatUnavailable
    case audioEngineFailed

    var userMessage: String {
        switch self {
        case .modelUnavailable:
            return "中文离线语音模型准备失败。请检查网络，稍后再试。"
        case .localeUnavailable:
            return "当前系统版本不支持中文离线转写。请更新到最新 iOS 后重试。"
        case .noAudioInput:
            return "没有检测到可用麦克风，请稍后重试。"
        case .audioFormatUnavailable:
            return "设备暂时无法提供语音处理所需的音频格式。"
        case .audioEngineFailed:
            return "麦克风启动失败，请关闭其他录音应用后重试。"
        }
    }
}
