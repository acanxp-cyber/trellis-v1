import AVFoundation

final class AudioBufferConverter {
    enum ConversionError: Error {
        case cannotCreateConverter
        case cannotCreateBuffer
        case conversionFailed
    }

    private var converter: AVAudioConverter?

    func convert(
        _ buffer: AVAudioPCMBuffer,
        to format: AVAudioFormat
    ) throws -> AVAudioPCMBuffer {
        if buffer.format == format {
            return buffer
        }

        if converter == nil || converter?.outputFormat != format {
            converter = AVAudioConverter(
                from: buffer.format,
                to: format
            )
            converter?.primeMethod = .none
        }

        guard let converter else {
            throw ConversionError.cannotCreateConverter
        }

        let ratio = format.sampleRate / buffer.format.sampleRate
        let capacity = AVAudioFrameCount(
            (Double(buffer.frameLength) * ratio).rounded(.up)
        )
        guard let output = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: capacity
        ) else {
            throw ConversionError.cannotCreateBuffer
        }

        var suppliedInput = false
        var conversionError: NSError?
        let status = converter.convert(
            to: output,
            error: &conversionError
        ) { _, inputStatus in
            if suppliedInput {
                inputStatus.pointee = .noDataNow
                return nil
            }
            suppliedInput = true
            inputStatus.pointee = .haveData
            return buffer
        }

        guard status != .error else {
            if let conversionError {
                throw conversionError
            }
            throw ConversionError.conversionFailed
        }
        return output
    }
}
