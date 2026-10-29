//
//  ContentView.swift
//  CamCardReplica
//
//  Created by Makoto Wu on 2026/10/29.
//

import SwiftUI

struct ContentView: View {
    @State private var navigation: AppNavigationModel

    init() {
        let isUITesting = ProcessInfo.processInfo.arguments.contains("-UITesting")
        _navigation = State(initialValue: AppNavigationModel(initialStage: isUITesting ? .login : .launch))
    }

    var body: some View {
        @Bindable var navigation = navigation

        Group {
            switch navigation.stage {
            case .launch:
                LaunchView {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        navigation.stage = .login
                    }
                }
            case .login:
                LoginView()
            case .main:
                NavigationStack(path: $navigation.path) {
                    MainTabView()
                        .navigationDestination(for: AppRoute.self) { route in
                            destination(for: route)
                        }
                }
            }
        }
        .environment(navigation)
        .sheet(item: $navigation.placeholderAction) { action in
            PlaceholderSheet(action: action)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .capture:
            CaptureView()
        case .review:
            CardReviewView()
        case .saveResult:
            SaveResultView()
        case let .cardDetail(id):
            CardDetailView(cardID: id)
        }
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.light)
}
