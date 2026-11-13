@preconcurrency import AVFoundation
import Foundation
import Observation

enum AlarmVoiceProfile: String, CaseIterable, Identifiable, Codable, Sendable {
    case gentleTaiwanese
    case clearMandarin
    case systemChinese

    var id: String { rawValue }

    static let defaultValue: AlarmVoiceProfile = .gentleTaiwanese

    var title: String {
        switch self {
        case .gentleTaiwanese:
            return "温柔台湾女声"
        case .clearMandarin:
            return "清晰普通话女声"
        case .systemChinese:
            return "跟随系统中文语音"
        }
    }

    var detail: String {
        switch self {
        case .gentleTaiwanese:
            return "默认目标音色；优先使用 iPhone 自带的台湾普通话女声"
        case .clearMandarin:
            return "咬字更清楚，适合信息较多的日程提醒"
        case .systemChinese:
            return "优先跟随当前系统中文区域，适合已单独配置系统声音的用户"
        }
    }

    var localeIdentifier: String {
        switch self {
        case .gentleTaiwanese:
            return "zh-TW"
        case .clearMandarin:
            return "zh-CN"
        case .systemChinese:
            return Locale.current.identifier
        }
    }

    var rate: Float {
        switch self {
        case .gentleTaiwanese:
            return 0.44
        case .clearMandarin:
            return 0.47
        case .systemChinese:
            return 0.46
        }
    }

    var pitchMultiplier: Float {
        switch self {
        case .gentleTaiwanese:
            return 0.96
        case .clearMandarin:
            return 1
        case .systemChinese:
            return 0.98
        }
    }
}

struct AlarmVoiceSettings: Equatable, Sendable {
    var isSpokenAlarmEnabled: Bool
    var profile: AlarmVoiceProfile

    static let `default` = AlarmVoiceSettings(
        isSpokenAlarmEnabled: true,
        profile: .defaultValue
    )
}

@MainActor
@Observable
final class AlarmVoicePreferences {
    private enum Key {
        static let enabled = "alarmVoice.enabled"
        static let profile = "alarmVoice.profile"
        static let guideSeen = "alarmVoice.guideSeen"
    }

    private let defaults: UserDefaults

    var isSpokenAlarmEnabled: Bool {
        didSet {
            defaults.set(isSpokenAlarmEnabled, forKey: Key.enabled)
        }
    }

    var profile: AlarmVoiceProfile {
        didSet {
            defaults.set(profile.rawValue, forKey: Key.profile)
        }
    }

    private(set) var hasSeenGuide: Bool {
        didSet {
            defaults.set(hasSeenGuide, forKey: Key.guideSeen)
        }
    }

    var settings: AlarmVoiceSettings {
        AlarmVoiceSettings(
            isSpokenAlarmEnabled: isSpokenAlarmEnabled,
            profile: profile
        )
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        isSpokenAlarmEnabled = defaults.object(
            forKey: Key.enabled
        ) as? Bool ?? true
        profile = defaults.string(forKey: Key.profile)
            .flatMap(AlarmVoiceProfile.init(rawValue:))
            ?? .defaultValue
        hasSeenGuide = defaults.bool(forKey: Key.guideSeen)
    }

    func markGuideSeen() {
        hasSeenGuide = true
    }

    func resetToDefaults() {
        isSpokenAlarmEnabled = true
        profile = .defaultValue
    }
}

struct SpokenAlarmSound: Equatable, Sendable {
    let fileName: String
    let usedVoiceFallback: Bool
}

enum SpokenAlarmSoundError: LocalizedError {
    case cannotCreateDirectory
    case cannotSynthesize
    case cannotWrite
    case voiceUnavailable

    var errorDescription: String? {
        switch self {
        case .cannotCreateDirectory:
            return "无法准备闹钟语音目录。"
        case .cannotSynthesize:
            return "无法生成任务播报。"
        case .cannotWrite:
            return "无法保存闹钟语音。"
        case .voiceUnavailable:
            return "这台设备暂时没有可用的中文播报声音。"
        }
    }
}

@MainActor
final class SpokenAlarmSoundStore {
    private let directory: URL
    private let fileManager = FileManager.default
    private var activeSynthesizer: AVSpeechSynthesizer?

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
        title: String,
        scheduledAt: Date,
        fireDate: Date,
        profile: AlarmVoiceProfile
    ) async throws -> SpokenAlarmSound {
        let fileName = SpokenAlarmTextBuilder.fileName(
            for: taskID,
            profile: profile
        )
        let outputURL = directory.appendingPathComponent(fileName)
        try? fileManager.removeItem(at: outputURL)

        let resolution = try resolveVoice(for: profile)
        let utterance = AVSpeechUtterance(
            string: SpokenAlarmTextBuilder.text(
                for: title,
                scheduledAt: scheduledAt,
                fireDate: fireDate
            )
        )
        utterance.voice = resolution.voice
        utterance.rate = profile.rate
        utterance.pitchMultiplier = profile.pitchMultiplier
        utterance.preUtteranceDelay = 0
        utterance.postUtteranceDelay = 0.15

        let synthesizer = AVSpeechSynthesizer()
        activeSynthesizer = synthesizer
        defer {
            activeSynthesizer = nil
        }
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
        return SpokenAlarmSound(
            fileName: fileName,
            usedVoiceFallback: resolution.usedFallback
        )
    }

    func removeSounds(taskID: UUID) {
        for profile in AlarmVoiceProfile.allCases {
            let url = directory.appendingPathComponent(
                SpokenAlarmTextBuilder.fileName(
                    for: taskID,
                    profile: profile
                )
            )
            try? fileManager.removeItem(at: url)
        }
    }

    func url(named fileName: String) -> URL {
        directory.appendingPathComponent(fileName)
    }

    private func resolveVoice(
        for profile: AlarmVoiceProfile
    ) throws -> (
        voice: AVSpeechSynthesisVoice,
        usedFallback: Bool
    ) {
        if let exact = AVSpeechSynthesisVoice(
            language: profile.localeIdentifier
        ) {
            return (exact, false)
        }

        let fallbackLanguage: String
        switch profile {
        case .gentleTaiwanese:
            fallbackLanguage = "zh-CN"
        case .clearMandarin, .systemChinese:
            fallbackLanguage = "zh-TW"
        }
        if let fallback = AVSpeechSynthesisVoice(
            language: fallbackLanguage
        ) {
            return (fallback, true)
        }
        if let chinese = AVSpeechSynthesisVoice.speechVoices().first(
            where: { $0.language.hasPrefix("zh") }
        ) {
            return (chinese, true)
        }
        throw SpokenAlarmSoundError.voiceUnavailable
    }
}
