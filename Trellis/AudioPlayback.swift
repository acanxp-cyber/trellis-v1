import AVFoundation
import Foundation
import Observation

struct ReplayableAudioState: Equatable, Sendable {
    private(set) var attachmentID: UUID?
    private(set) var position: TimeInterval = 0
    private(set) var duration: TimeInterval = 0
    private(set) var isPlaying = false

    mutating func toggle(
        attachmentID: UUID,
        duration: TimeInterval
    ) {
        if self.attachmentID != attachmentID {
            self.attachmentID = attachmentID
            self.duration = max(duration, 0)
            position = 0
            isPlaying = true
            return
        }

        self.duration = max(duration, 0)
        if isPlaying {
            isPlaying = false
            return
        }
        if position >= self.duration - 0.05 {
            position = 0
        }
        isPlaying = true
    }

    mutating func tick(_ delta: TimeInterval) {
        guard isPlaying else {
            return
        }
        position = min(duration, position + max(delta, 0))
        if position >= duration {
            markFinished()
        }
    }

    mutating func markFinished() {
        position = duration
        isPlaying = false
    }

    mutating func synchronize(
        position: TimeInterval,
        duration: TimeInterval
    ) {
        self.position = min(max(position, 0), max(duration, 0))
        self.duration = max(duration, 0)
    }

    mutating func stop() {
        attachmentID = nil
        position = 0
        duration = 0
        isPlaying = false
    }
}

@MainActor
@Observable
final class LocalAudioPlayer {
    private(set) var state = ReplayableAudioState()
    private(set) var errorMessage: String?

    private var player: AVAudioPlayer?
    private var timerTask: Task<Void, Never>?

    func toggle(
        attachment: RecordAttachment,
        store: RecordMediaStore
    ) async {
        do {
            if state.attachmentID != attachment.id || player == nil {
                let data = try await store.data(for: attachment)
                let nextPlayer = try AVAudioPlayer(data: data)
                nextPlayer.prepareToPlay()
                player?.stop()
                player = nextPlayer
                state = ReplayableAudioState()
            }

            guard let player else {
                return
            }
            state.toggle(
                attachmentID: attachment.id,
                duration: player.duration
            )

            if state.isPlaying {
                if state.position < 0.05 {
                    player.currentTime = 0
                }
                try activateAudioSession()
                guard player.play() else {
                    state.markFinished()
                    throw AudioPlaybackError.cannotStart
                }
                startProgressTimer()
            } else {
                player.pause()
                timerTask?.cancel()
                timerTask = nil
            }
            errorMessage = nil
        } catch {
            timerTask?.cancel()
            timerTask = nil
            state.stop()
            errorMessage = (error as? LocalizedError)?.errorDescription
                ?? "音频播放失败，请重试。"
        }
    }

    func stop() {
        timerTask?.cancel()
        timerTask = nil
        player?.stop()
        player = nil
        state.stop()
        try? AVAudioSession.sharedInstance().setActive(
            false,
            options: .notifyOthersOnDeactivation
        )
    }

    private func startProgressTimer() {
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(250))
                guard let self, self.state.isPlaying else {
                    return
                }
                self.refreshProgress()
            }
        }
    }

    private func refreshProgress() {
        guard let player, state.isPlaying else {
            return
        }
        state.tick(0.25)
        if !player.isPlaying,
           player.currentTime >= max(player.duration - 0.1, 0)
        {
            state.markFinished()
            timerTask?.cancel()
            timerTask = nil
            try? AVAudioSession.sharedInstance().setActive(
                false,
                options: .notifyOthersOnDeactivation
            )
        } else {
            state.synchronize(
                position: player.currentTime,
                duration: player.duration
            )
        }
    }

    private func activateAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(
            .playback,
            mode: .spokenAudio,
            options: [.duckOthers]
        )
        try session.setActive(true)
    }
}

private enum AudioPlaybackError: LocalizedError {
    case cannotStart

    var errorDescription: String? {
        "这段录音暂时无法播放。"
    }
}
