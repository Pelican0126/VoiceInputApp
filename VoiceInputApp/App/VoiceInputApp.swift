import SwiftUI
import SwiftData
import SharedKit

@main
struct VoiceInputApp: App {
    @StateObject private var sessionRouter = SessionRouter()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(sessionRouter)
                .onOpenURL { url in
                    sessionRouter.handle(url: url)
                }
        }
        .modelContainer(for: [HistoryEntry.self])
    }
}
