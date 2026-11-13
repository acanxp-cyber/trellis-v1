@preconcurrency import AVFoundation
import Foundation

enum SpokenAlarmSoundError: LocalizedError {
    case cannotCreateDirectory
    case cannotSynthesize
    case cannotWrite

    var errorDescription: String? {
        switch self {
        case .cannotCreateDirectory:
            return "无法准备闹钟语音目录。"
        case .cannotSynthesize:
            return "无法生成任务播报。"
        case .cannotWrite:
            return "无法保存闹钟语音。"
        }
    }
}

@MainActor
final class SpokenAlarmSoundStore {
    private let directory: URL
    private let fileManager = FileManager.default

    init(directory: URL) throws {
        self.directory = directory
        do {
            try fileManager.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
        } catch {
            throw SpokenAlarmSoundError.cannotCreateDirectory
        }
    }

    static func makeDefault() throws -> SpokenAlarmSoundStore {
        let library = try FileManager.default.url(
            for: .libraryDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return try SpokenAlarmSoundStore(
            directory: library.appendingPathComponent(
                "Sounds",
                isDirectory: true
            )
        )
    }

    func soundName(
        for taskID: UUID,
        title: String
    ) async throws -> String {
        let fileName = SpokenAlarmTextBuilder.fileName(for: taskID)
        let outputURL = directory.appendingPathComponent(fileName)
        try? fileManager.removeItem(at: outputURL)

        let utterance = AVSpeechUtterance(
            string: SpokenAlarmTextBuilder.text(for: title)
        )
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.rate = 0.47
        utterance.pitchMultiplier = 1
        utterance.preUtteranceDelay = 0
        utterance.postUtteranceDelay = 0.15

        let synthesizer = AVSpeechSynthesizer()
        try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<Void, Error>) in
            var audioFile: AVAudioFile?
            var didFinish = false

            synthesizer.write(utterance) { buffer in
                guard !didFinish else {
                    return
                }
                guard let pcmBuffer = buffer as? AVAudioPCMBuffer else {
                    didFinish = true
                    continuation.resume(
                        throwing: SpokenAlarmSoundError.cannotSynthesize
                    )
                    return
                }
                if pcmBuffer.frameLength == 0 {
                    didFinish = true
                    continuation.resume()
                    return
                }

                do {
                    if audioFile == nil {
                        audioFile = try AVAudioFile(
                            forWriting: outputURL,
                            settings: pcmBuffer.format.settings
                        )
                    }
                    try audioFile?.write(from: pcmBuffer)
                } catch {
                    didFinish = true
                    continuation.resume(
                        throwing: SpokenAlarmSoundError.cannotWrite
                    )
                }
            }
        }

        guard fileManager.fileExists(atPath: outputURL.path) else {
            throw SpokenAlarmSoundError.cannotSynthesize
        }
        return fileName
    }

    func removeSound(taskID: UUID) {
        let url = directory.appendingPathComponent(
            SpokenAlarmTextBuilder.fileName(for: taskID)
        )
        try? fileManager.removeItem(at: url)
    }
}
