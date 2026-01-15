import SwiftUI

import StorageKit

@main
struct IOSApp: App {
    var body: some Scene {
        WindowGroup {
            RootView(container: AppContainer())
        }
        .modelContainer(for: [Player.self, GameRecord.self],
                        isAutosaveEnabled: true,
                        isUndoEnabled: false)
    }
}
