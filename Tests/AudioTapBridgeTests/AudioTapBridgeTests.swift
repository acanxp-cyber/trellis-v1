@preconcurrency import AVFoundation
import Dispatch
import XCTest
@testable import AudioTapBridge

final class AudioTapBridgeTests: XCTestCase {
    func testTapHandlerRunsOffMainActor() {
        let (_, continuation) = AsyncStream<AVAudioPCMBuffer>
            .makeStream(bufferingPolicy: .bufferingNewest(1))
        let handler = AudioTapBridge.makeTapHandler(
            yieldingTo: continuation
        )
        let completed = expectation(description: "Audio tap handler")

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
            completed.fulfill()
        }

        wait(for: [completed], timeout: 2)
        continuation.finish()
    }
}
