@preconcurrency import AVFoundation
import Foundation
@preconcurrency import Speech

@available(iOS 26.0, *)
@MainActor
final class ModernSpeechCaptureSession {
    private let onTranscript: @MainActor (String) -> Void
    private let onError: @MainActor (String) -> Void
    private let converter = AudioBufferConverter()

    private let audioEngine = AVAudioEngine()
    private var hasInstalledTap = false
    private var analyzer: SpeechAnalyzer?
    private var transcriber: SpeechTranscriber?
    private var analyzerInput: AsyncStream<AnalyzerInput>.Continuation?
    private var analyzerFormat: AVAudioFormat?
    private var resultTask: Task<Void, Never>?
    private var audioPipelineTask: Task<Void, Never>?
    private var finalizedText = ""
    private var volatileText = ""
    private var isStopping = false

    init(
        onTranscript: @escaping @MainActor (String) -> Void,
        onError: @escaping @MainActor (String) -> Void
    ) {
        self.onTranscript = onTranscript
        self.onError = onError
    }

    func start() async throws {
        guard SpeechTranscriber.isAvailable else {
            throw ModernSpeechError.modelUnavailable
        }

        let requestedLocale = Locale(identifier: "zh-CN")
        let supported = await SpeechTranscriber.supportedLocales
        guard let locale = SpeechLocaleSupport.match(
            requestedLocale,
            in: supported
        ) else {
            throw ModernSpeechError.localeUnavailable
        }

        let transcriber = SpeechTranscriber(
            locale: locale,
            transcriptionOptions: [],
            reportingOptions: [.volatileResults],
            attributeOptions: []
        )

        let installed = await SpeechTranscriber.installedLocales
        if SpeechLocaleSupport.match(locale, in: installed) == nil {
            if let request = try await AssetInventory.assetInstallationRequest(
                supporting: [transcriber]
            ) {
                do {
                    try await request.downloadAndInstall()
                } catch {
                    throw ModernSpeechError.assetDownloadFailed
                }
            }
        }

        guard let format = await SpeechAnalyzer.bestAvailableAudioFormat(
            compatibleWith: [transcriber]
        ) else {
            throw ModernSpeechError.audioFormatUnavailable
        }

        let analyzer = SpeechAnalyzer(modules: [transcriber])
        let (inputSequence, inputContinuation) = AsyncStream<AnalyzerInput>
            .makeStream(bufferingPolicy: .unbounded)

        self.transcriber = transcriber
        self.analyzer = analyzer
        self.analyzerInput = inputContinuation
        self.analyzerFormat = format
        self.finalizedText = ""
        self.volatileText = ""

        resultTask = Task { [weak self] in
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
                self.onError("语音识别中断了，请重试。")
                self.stopAudio()
            }
        }

        try await analyzer.start(inputSequence: inputSequence)
        try startAudio()
    }

    func finish() async -> String {
        guard !isStopping else {
            return currentTranscript
        }

        isStopping = true
        stopAudio()
        analyzerInput?.finish()
        analyzerInput = nil

        do {
            try await analyzer?.finalizeAndFinishThroughEndOfInput()
        } catch {
            onError("语音转写结束失败，请重试。")
        }
        try? await Task.sleep(for: .milliseconds(250))
        resultTask?.cancel()
        resultTask = nil
        analyzer = nil
        transcriber = nil
        analyzerFormat = nil
        deactivateAudioSession()
        return currentTranscript
    }

    func cancel() {
        isStopping = true
        stopAudio()
        analyzerInput?.finish()
        analyzerInput = nil
        resultTask?.cancel()
        resultTask = nil
        audioPipelineTask?.cancel()
        audioPipelineTask = nil
        analyzer = nil
        transcriber = nil
        analyzerFormat = nil
        deactivateAudioSession()
    }

    private var currentTranscript: String {
        finalizedText + volatileText
    }

    private func consume(_ result: SpeechTranscriber.Result) {
        let text = String(result.text.characters)
        if result.isFinal {
            finalizedText += text
            volatileText = ""
        } else {
            volatileText = text
        }
        onTranscript(currentTranscript)
    }

    private func startAudio() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(
            .playAndRecord,
            mode: .spokenAudio,
            options: [.duckOthers]
        )
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let inputNode = audioEngine.inputNode
        let format = inputNode.inputFormat(forBus: 0)
        guard
            format.sampleRate > 0,
            format.channelCount > 0
        else {
            throw ModernSpeechError.noAudioInput
        }

        let (audioStream, audioContinuation) = AsyncStream<AVAudioPCMBuffer>
            .makeStream(bufferingPolicy: .unbounded)
        audioPipelineTask = Task { [weak self] in
            for await buffer in audioStream {
                guard let self else {
                    return
                }
                self.consumeAudio(buffer)
            }
        }

        inputNode.installTap(
            onBus: 0,
            bufferSize: 4_096,
            format: format
        ) { buffer, _ in
            audioContinuation.yield(buffer)
        }
        hasInstalledTap = true
        audioEngine.prepare()

        do {
            try audioEngine.start()
        } catch {
            stopAudio()
            throw ModernSpeechError.audioEngineFailed
        }
    }

    private func consumeAudio(_ buffer: AVAudioPCMBuffer) {
        guard
            let analyzerInput,
            let analyzerFormat
        else {
            return
        }

        do {
            let converted = try converter.convert(
                buffer,
                to: analyzerFormat
            )
            analyzerInput.yield(AnalyzerInput(buffer: converted))
        } catch {
            guard !isStopping else {
                return
            }
            onError("语音转写中断了，请重试。")
            stopAudio()
        }
    }

    private func stopAudio() {
        audioEngine.stop()
        if hasInstalledTap {
            audioEngine.inputNode.removeTap(onBus: 0)
            hasInstalledTap = false
        }
        audioPipelineTask?.cancel()
        audioPipelineTask = nil
    }

    private func deactivateAudioSession() {
        try? AVAudioSession.sharedInstance().setActive(
            false,
            options: .notifyOthersOnDeactivation
        )
    }
}

enum ModernSpeechError: Error {
    case modelUnavailable
    case localeUnavailable
    case assetDownloadFailed
    case noAudioInput
    case audioFormatUnavailable
    case audioEngineFailed

    var userMessage: String {
        switch self {
        case .modelUnavailable:
            return "此设备不支持 iOS 26 的离线中文语音模型。"
        case .localeUnavailable:
            return "当前系统没有可用的中文离线语音模型。"
        case .assetDownloadFailed:
            return "中文离线语音模型下载失败。请连接网络后重试。"
        case .noAudioInput:
            return "没有检测到可用麦克风，请稍后重试。"
        case .audioFormatUnavailable:
            return "设备暂时无法提供语音处理所需的音频格式。"
        case .audioEngineFailed:
            return "麦克风启动失败，请关闭其他录音应用后重试。"
        }
    }
}
