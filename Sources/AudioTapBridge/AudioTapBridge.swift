@preconcurrency import AVFoundation
import Darwin

public enum AudioTapBridge {
    public static func makeTapHandler(
        yieldingTo continuation: AsyncStream<AVAudioPCMBuffer>.Continuation
    ) -> AVAudioNodeTapBlock {
        { buffer, _ in
            guard let copy = copyAudioBuffer(buffer) else {
                return
            }
            continuation.yield(copy)
        }
    }

    private static func copyAudioBuffer(
        _ source: AVAudioPCMBuffer
    ) -> AVAudioPCMBuffer? {
        guard let copy = AVAudioPCMBuffer(
            pcmFormat: source.format,
            frameCapacity: source.frameLength
        ) else {
            return nil
        }
        copy.frameLength = source.frameLength

        let sourceBuffers = UnsafeMutableAudioBufferListPointer(
            source.mutableAudioBufferList
        )
        let destinationBuffers = UnsafeMutableAudioBufferListPointer(
            copy.mutableAudioBufferList
        )
        for (sourceBuffer, destinationBuffer) in zip(
            sourceBuffers,
            destinationBuffers
        ) {
            var destinationBuffer = destinationBuffer
            guard
                let sourceData = sourceBuffer.mData,
                let destinationData = destinationBuffer.mData
            else {
                continue
            }
            destinationBuffer.mDataByteSize = sourceBuffer.mDataByteSize
            memcpy(
                destinationData,
                sourceData,
                Int(sourceBuffer.mDataByteSize)
            )
        }
        return copy
    }
}
