import Foundation
import Observation

enum AppTab: String, CaseIterable, Identifiable {
    case home
    case cards
    case enterprise
    case profile

    var id: Self { self }
}

enum AppRoute: Hashable {
    case login
    case capture
    case review
    case saveResult
    case cardDetail(UUID)
    case placeholder(id: String)
}

enum CaptureFlowState: Equatable {
    case idle
    case selectingImage
    case previewing
    case recognizing
    case reviewing
    case saving
    case completed
    case failed(message: String)
}

@MainActor
@Observable
final class AppNavigationModel {
    var selectedTab: AppTab = .home
    var path: [AppRoute] = []
    var captureState: CaptureFlowState = .idle

    func push(_ route: AppRoute) {
        path.append(route)
    }

    func popToRoot() {
        path.removeAll()
    }

    func resetCapture() {
        captureState = .idle
    }
}
