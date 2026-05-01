import Foundation
import SwiftUI
import SharedKit

@MainActor
final class SessionRouter: ObservableObject {
    enum Route: Equatable {
        case onboarding
        case home
        case recording(sessionID: String)
    }

    @Published var route: Route

    init() {
        let isFirstRun = UserDefaults.standard.bool(forKey: "didCompleteOnboarding") == false
        self.route = isFirstRun ? .onboarding : .home
    }

    func handle(url: URL) {
        guard url.scheme == SharedKit.urlScheme else { return }
        switch url.host {
        case "record":
            let session = url.queryItem("session") ?? UUID().uuidString
            route = .recording(sessionID: session)
        default:
            break
        }
    }

    func finishOnboarding() {
        UserDefaults.standard.set(true, forKey: "didCompleteOnboarding")
        route = .home
    }
}

private extension URL {
    func queryItem(_ name: String) -> String? {
        URLComponents(url: self, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first { $0.name == name }?
            .value
    }
}
