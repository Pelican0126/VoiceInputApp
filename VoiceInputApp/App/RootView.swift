import SwiftUI

struct RootView: View {
    @EnvironmentObject var router: SessionRouter

    var body: some View {
        switch router.route {
        case .onboarding:
            OnboardingView()
        case .home:
            HomeView()
        case .recording(let sessionID):
            RecordingView(sessionID: sessionID)
        }
    }
}
