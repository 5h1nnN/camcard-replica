import SwiftUI
import SwiftData

struct CardListView: View {
    @Environment(AppNavigationModel.self) private var navigation
    @Query(sort: \BusinessCard.updatedAt, order: .reverse) private var cards: [BusinessCard]
    @State private var showsAssistantInvite = true
    @State private var searchText = ""

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                searchHeader

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

    private var searchHeader: some View {
        HStack(spacing: 12) {
            Button {
                placeholder("messages", "消息中心", symbol: "message.fill")
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "message")
                        .font(.title2)
                        .foregroundStyle(AppColors.textPrimary)
                    Circle()
                        .fill(.red)
                        .frame(width: 9, height: 9)
                }
            }
            .accessibilityIdentifier("placeholder.cards.messages")

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("姓名/公司/职位/电话/邮箱", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("core.cards.search")
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                    }
                    .accessibilityLabel("清空搜索")
                    .accessibilityIdentifier("core.cards.clearSearch")
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 44)
            .background(.white, in: Capsule())

            Button {
                navigation.push(.capture)
            } label: {
                Image(systemName: "plus.circle")
                    .font(.system(size: 31))
                    .foregroundStyle(AppColors.textPrimary)
            }
            .accessibilityIdentifier("core.cards.add")
        }
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

            if cards.isEmpty {
                emptyCardsView
            } else if filteredCards.isEmpty {
                VStack(spacing: 7) {
                    Image(systemName: "magnifyingglass")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("没有匹配“\(searchText)”的名片")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .accessibilityIdentifier("core.cards.noSearchResults")
            } else {
                ForEach(filteredCards) { card in
                    savedCardRow(card)
                }
            }

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
        }
        .padding(18)
        .background(.white, in: RoundedRectangle(cornerRadius: AppRadius.medium))
    }

    private var filteredCards: [BusinessCard] {
        cards.filter { $0.matches(searchText) }
    }

    private var emptyCardsView: some View {
        VStack(spacing: 7) {
            Image(systemName: "tray")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("还没有保存的名片")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("点击右上角添加，从相册导入并识别")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .accessibilityIdentifier("core.cards.empty")
    }

    private func savedCardRow(_ card: BusinessCard) -> some View {
        Button {
            navigation.push(.cardDetail(card.id))
        } label: {
            HStack(spacing: 14) {
                StoredCardImage(relativePath: card.originalImagePath)
                    .frame(width: 102, height: 76)
                VStack(alignment: .leading, spacing: 5) {
                    Text(card.name.isEmpty ? "未填写姓名" : card.name)
                        .font(.headline)
                        .foregroundStyle(AppColors.textPrimary)
                    Text([card.company, card.jobTitle].filter { !$0.isEmpty }.joined(separator: " · "))
                        .font(.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(1)
                    Text(card.mobilePhone.isEmpty ? card.email : card.mobilePhone)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 5)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("core.cards.savedCard.\(card.id.uuidString)")
    }

    private func placeholder(_ id: String, _ title: String, symbol: String) {
        navigation.showPlaceholder(id: "cards.\(id)", title: title, source: "名片夹", symbol: symbol)
    }
}

#Preview {
    CardListView()
        .environment(AppNavigationModel(initialStage: .main))
        .modelContainer(for: BusinessCard.self, inMemory: true)
}
