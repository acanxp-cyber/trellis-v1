import SwiftUI

@main
struct TrellisApp: App {
    @State private var model = AppModel.live()
    @State private var audioPlayer = LocalAudioPlayer()
    @State private var alarmVoicePreferences = AlarmVoicePreferences()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .environment(audioPlayer)
                .environment(alarmVoicePreferences)
                .task {
                    await model.bootstrap()
                }
        }
    }
}

