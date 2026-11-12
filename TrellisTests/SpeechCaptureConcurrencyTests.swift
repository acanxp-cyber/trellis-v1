@preconcurrency import AVFoundation
import Dispatch
import XCTest
@testable import Trellis

final class SpeechCaptureConcurrencyTests: XCTestCase {
    @available(iOS 26.0, *)
    func testAudioTapHandlerCanRunOffMainActor() async throws {
        let (stream, continuation) = AsyncStream<AVAudioPCMBuffer>
            .makeStream(bufferingPolicy: .bufferingNewest(1))
        let handler = ModernSpeechCaptureSession.makeTapHandler(
            yieldingTo: continuation
        )

        await withCheckedContinuation { finished in
            DispatchQueue.global(qos: .userInitiated).async {
                let format = AVAudioFormat(
                    commonFormat: .pcmFormatFloat32,
                    sampleRate: 16_000,
                    channels: 1,
                    interleaved: false
                )!
                let buffer = AVAudioPCMBuffer(
                    pcmFormat: format,
                    frameCapacity: 160
                )!
                buffer.frameLength = 160
                handler(buffer, AVAudioTime())
                buffer.frameLength = 0
                finished.resume()
            }
        }
        continuation.finish()

        var receivedFrameLength: AVAudioFrameCount = 0
        for await buffer in stream {
            receivedFrameLength = buffer.frameLength
        }
        XCTAssertEqual(receivedFrameLength, 160)
    }
}
