import SwiftUI

@main
struct TrellisApp: App {
    @State private var model = AppModel.live()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .task {
                    await model.bootstrap()
                }
        }
    }
}

