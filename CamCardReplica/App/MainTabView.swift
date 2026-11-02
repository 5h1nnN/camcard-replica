import SwiftUI

struct MainTabView: View {
    @Environment(AppNavigationModel.self) private var navigation

    var body: some View {
        @Bindable var navigation = navigation

        Group {
            switch navigation.selectedTab {
            case .home:
                HomeView()
            case .cards:
                CardListView()
            case .enterprise:
                EnterpriseView()
            case .profile:
                ProfileView()
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            MainTabBar(selectedTab: $navigation.selectedTab) {
                navigation.push(.capture)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .screenIdentifier("main.shell")
    }
}

private struct MainTabBar: View {
    @Binding var selectedTab: AppTab
    let captureAction: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            tabButton(.home, title: "首页", symbol: "house.fill")
            tabButton(.cards, title: "名片夹", symbol: "folder.fill")

            Button(action: captureAction) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.cyan, AppColors.primaryStrong],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: AppSize.scanButton, height: AppSize.scanButton)
                        .shadow(color: AppColors.primary.opacity(0.32), radius: 10, y: 4)
                    Image(systemName: "camera.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
            }
            .accessibilityLabel("拍摄名片")
            .accessibilityIdentifier("core.tab.capture")

            tabButton(.enterprise, title: "企业", symbol: "building.2.fill")
            tabButton(.profile, title: "我", symbol: "person.fill")
        }
        .frame(height: AppSize.tabBarHeight)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) { Divider() }
    }

    private func tabButton(_ tab: AppTab, title: String, symbol: String) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.system(size: 21, weight: .medium))
                Text(title)
                    .font(.caption2)
            }
            .foregroundStyle(selectedTab == tab ? AppColors.primary : Color.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityValue(selectedTab == tab ? "已选中" : "未选中")
        .accessibilityIdentifier("core.tab.\(tab.rawValue)")
    }
}

#Preview {
    NavigationStack {
        MainTabView()
    }
    .environment(AppNavigationModel(initialStage: .main))
}
