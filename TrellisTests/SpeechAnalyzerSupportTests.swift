import AVFoundation
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
}
