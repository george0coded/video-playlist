import SwiftUI

@main
struct PlaylistApp: App {
    @StateObject private var store = PlaylistStore()
    @StateObject private var player = PlayerManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(player)
        }
    }
}
