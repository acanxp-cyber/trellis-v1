import AVFoundation
import Speech
import XCTest
@testable import Trellis

final class SpeechAnalyzerSupportTests: XCTestCase {
    func testChineseLocaleResolutionUsesSupportedSimplifiedChinese() {
        let requested = Locale(identifier: "zh-Hans-CN")
        let supported = [
            Locale(identifier: "en-US"),
            Locale(identifier: "zh-CN"),
        ]

        let resolved = SpeechLocaleSupport.match(
            requested,
            in: supported
        )

        XCTAssertEqual(resolved?.identifier, "zh-CN")
    }

    func testAudioBufferConverterProducesAnalyzerFormat() throws {
        let inputFormat = try XCTUnwrap(
            AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: 48_000,
                channels: 1,
                interleaved: false
            )
        )
        let outputFormat = try XCTUnwrap(
            AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: 16_000,
                channels: 1,
                interleaved: false
            )
        )
        let input = try XCTUnwrap(
            AVAudioPCMBuffer(
                pcmFormat: inputFormat,
                frameCapacity: 4_800
            )
        )
        input.frameLength = 4_800

        let converted = try AudioBufferConverter().convert(
            input,
            to: outputFormat
        )

        XCTAssertEqual(converted.format.sampleRate, 16_000)
        XCTAssertGreaterThan(converted.frameLength, 0)
    }

    @available(iOS 26.0, *)
    func testChineseSpeechAnalyzerTranscribesBundledAudio() async throws {
        XCTAssertTrue(SpeechTranscriber.isAvailable)

        let locale = Locale(identifier: "zh-CN")
        let transcriber = SpeechTranscriber(
            locale: locale,
            transcriptionOptions: [],
            reportingOptions: [],
            attributeOptions: []
        )

        let installed = await SpeechTranscriber.installedLocales
        if SpeechLocaleSupport.match(locale, in: installed) == nil {
            if let request = try await AssetInventory.assetInstallationRequest(
                supporting: [transcriber]
            ) {
                try await request.downloadAndInstall()
            }
        }

        let bundle = Bundle(for: SpeechAnalyzerSupportTests.self)
        let audioURL = try XCTUnwrap(
            bundle.url(
                forResource: "voice-sample",
                withExtension: "wav"
            )
        )
        let audioFile = try AVAudioFile(forReading: audioURL)

        let analyzer = SpeechAnalyzer(modules: [transcriber])
        let (input, continuation) = AsyncStream<AnalyzerInput>
            .makeStream(bufferingPolicy: .unbounded)
        let resultTask = Task {
            var transcript = ""
            for try await result in transcriber.results where result.isFinal {
                transcript += String(result.text.characters)
            }
            return transcript
        }

        try await analyzer.start(inputSequence: input)
        let analyzerFormat = try XCTUnwrap(
            await SpeechAnalyzer.bestAvailableAudioFormat(
                compatibleWith: [transcriber]
            )
        )
        let converter = AudioBufferConverter()
        let chunkSize: AVAudioFrameCount = 4_096

        while audioFile.framePosition < audioFile.length {
            let remaining = audioFile.length - audioFile.framePosition
            let buffer = try XCTUnwrap(
                AVAudioPCMBuffer(
                    pcmFormat: audioFile.processingFormat,
                    frameCapacity: min(chunkSize, AVAudioFrameCount(remaining))
                )
            )
            try audioFile.read(into: buffer)
            let converted = try converter.convert(
                buffer,
                to: analyzerFormat
            )
            continuation.yield(AnalyzerInput(buffer: converted))
        }

        continuation.finish()
        try await analyzer.finalizeAndFinishThroughEndOfInput()
        let transcript = try await resultTask.value

        XCTAssertFalse(transcript.isEmpty)
        XCTAssertTrue(
            transcript.contains("客户") || transcript.contains("电话")
        )
    }
}
