import Foundation
import Observation

enum AppStage: Equatable {
    case launch
    case login
    case main
}

enum AppTab: String, CaseIterable, Identifiable {
    case home
    case cards
    case enterprise
    case profile

    var id: Self { self }
}

enum AppRoute: Hashable {
    case capture
    case review
    case saveResult
    case cardDetail(UUID)
    case groupManagement
    case groupAssignment(UUID)
    case groupCards(CardGroupFilter)
}

enum CardGroupFilter: Hashable {
    case custom(UUID)
    case recent30Days
    case recentlyAdded
    case ungrouped
    case byJob
    case byCity
}

struct PlaceholderAction: Identifiable, Hashable {
    let id: String
    let title: String
    let message: String
    let source: String
    let symbol: String
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
    var stage: AppStage
    var selectedTab: AppTab = .home
    var path: [AppRoute] = []
    var captureState: CaptureFlowState = .idle
    var placeholderAction: PlaceholderAction?

    init(initialStage: AppStage = .launch) {
        stage = initialStage
    }

    func push(_ route: AppRoute) {
        path.append(route)
    }

    func popToRoot() {
        path.removeAll()
    }

    func resetCapture() {
        captureState = .idle
    }

    func showPlaceholder(
        id: String,
        title: String,
        message: String = "该功能用于展示完整产品入口，演示版本暂未开放。",
        source: String,
        symbol: String = "sparkles"
    ) {
        placeholderAction = PlaceholderAction(
            id: id,
            title: title,
            message: message,
            source: source,
            symbol: symbol
        )
    }

    func enterMainApp() {
        stage = .main
        selectedTab = .home
        path.removeAll()
    }

    func returnToCards() {
        selectedTab = .cards
        path.removeAll()
    }
}
