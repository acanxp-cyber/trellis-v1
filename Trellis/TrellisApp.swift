import SwiftUI

@main
struct TrellisApp: App {
    @State private var model = AppModel.live()
    @State private var audioPlayer = LocalAudioPlayer()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .environment(audioPlayer)
                .task {
                    await model.bootstrap()
                }
        }
    }
}

