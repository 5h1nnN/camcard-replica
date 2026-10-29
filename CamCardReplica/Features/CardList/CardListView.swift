import SwiftUI

struct CardListView: View {
    @Environment(AppNavigationModel.self) private var navigation
    @State private var showsAssistantInvite = true

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                SearchHeader(source: "cards") {
                    navigation.push(.capture)
                }

                quickActions

                if showsAssistantInvite {
                    assistantInvite
                }

                myCardsSection
            }
            .padding(.horizontal, AppSize.pageInset)
            .padding(.top, 10)
            .padding(.bottom, 20)
        }
        .background(AppColors.pageBackground)
        .screenIdentifier("screen.cards")
    }

    private var quickActions: some View {
        HStack(spacing: 10) {
            quickAction("新的人脉", "person.2.badge.plus", .blue, "newContacts", badge: "1")
            quickAction("分组管理", "folder.badge.plus", .orange, "groups")
            quickAction("人脉地图", "map.fill", .green, "map")
            quickAction("人脉分析", "chart.bar.fill", .cyan, "analytics")
        }
    }

    private func quickAction(_ title: String, _ symbol: String, _ color: Color, _ id: String, badge: String? = nil) -> some View {
        Button {
            placeholder(id, title, symbol: symbol)
        } label: {
            VStack(spacing: 10) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: symbol)
                        .font(.title2)
                        .foregroundStyle(color)
                        .frame(width: 42, height: 36)
                    if let badge {
                        Text(badge)
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.red, in: Capsule())
                            .offset(x: 18, y: -8)
                    }
                }
                Text(title)
                    .font(.caption)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 96)
            .background(.white, in: RoundedRectangle(cornerRadius: AppRadius.medium))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("placeholder.cards.\(id)")
    }

    private var assistantInvite: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                DemoAvatar(initials: "助", size: 58, color: Color.indigo)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("名片助手")
                            .font(.headline)
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundStyle(AppColors.primary)
                    }
                    Text("您的客服助手")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                    Text("Cardly 演示团队")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                Spacer()
                Button("同意") {
                    placeholder("assistant.accept", "接受客服助手邀请", symbol: "person.badge.plus")
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.primary)
                .accessibilityIdentifier("placeholder.cards.assistant.accept")
                Button {
                    withAnimation { showsAssistantInvite = false }
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("关闭邀请")
                .accessibilityIdentifier("core.cards.assistant.close")
            }
            .padding(16)

            Divider()

            HStack {
                Text("来源：Cardly")
                Spacer()
                Text("2026/10/29 09:30")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(14)
        }
        .background(.white, in: RoundedRectangle(cornerRadius: AppRadius.medium))
    }

    private var myCardsSection: some View {
        VStack(spacing: 14) {
            HStack {
                Text("我的名片")
                    .font(.title2.weight(.semibold))
                Spacer()
                Button {
                    placeholder("manage", "管理名片", symbol: "square.3.layers.3d")
                } label: {
                    Label("管理", systemImage: "square.3.layers.3d")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.textPrimary)
                }
                .accessibilityIdentifier("placeholder.cards.manage")
            }

            Button {
                placeholder("updates", "好友名片更新记录", symbol: "clock.arrow.circlepath")
            } label: {
                HStack {
                    Image(systemName: "info.circle")
                    Text("好友名片更新记录")
                    Spacer()
                    Text("立即查看")
                    Image(systemName: "chevron.right")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(14)
                .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("placeholder.cards.updates")

            Button {
                navigation.push(.cardDetail(FixtureCatalog.demoID))
            } label: {
                HStack(spacing: 14) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppColors.primary.opacity(0.12))
                        .frame(width: 102, height: 76)
                        .overlay {
                            Image(systemName: "person.text.rectangle.fill")
                                .font(.system(size: 33))
                                .foregroundStyle(AppColors.primary)
                        }
                    VStack(alignment: .leading, spacing: 5) {
                        Text("30 秒快速认识 Cardly")
                            .font(.headline)
                            .foregroundStyle(AppColors.textPrimary)
                        Text("体验智能的名片识别、核对和管理")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.textSecondary)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("core.cards.demoDetail")

            VStack(spacing: 7) {
                Image(systemName: "tray")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("真实保存的名片将显示在这里")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("图片导入、OCR 与持久化将在后续阶段接入")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
        }
        .padding(18)
        .background(.white, in: RoundedRectangle(cornerRadius: AppRadius.medium))
    }

    private func placeholder(_ id: String, _ title: String, symbol: String) {
        navigation.showPlaceholder(id: "cards.\(id)", title: title, source: "名片夹", symbol: symbol)
    }
}

#Preview {
    CardListView()
        .environment(AppNavigationModel(initialStage: .main))
}
