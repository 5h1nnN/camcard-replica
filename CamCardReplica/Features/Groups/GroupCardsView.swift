import SwiftData
import SwiftUI

enum GroupCardFilter {
    static func cards(_ cards: [BusinessCard], matching filter: CardGroupFilter, now: Date = .now) -> [BusinessCard] {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? .distantPast
        switch filter {
        case let .custom(groupID):
            return cards.filter { $0.groupIDs.contains(groupID) }
        case .recent30Days:
            return cards.filter { $0.updatedAt >= thirtyDaysAgo }
        case .recentlyAdded:
            return cards.filter { $0.createdAt >= thirtyDaysAgo }
        case .ungrouped:
            return cards.filter(\.groupIDs.isEmpty)
        case .byJob:
            return cards.filter { !$0.jobTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        case .byCity:
            return cards.filter { !$0.address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        }
    }
}

struct GroupCardsView: View {
    let filter: CardGroupFilter

    @Environment(AppNavigationModel.self) private var navigation
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \BusinessCard.updatedAt, order: .reverse) private var cards: [BusinessCard]
    @Query private var groups: [CardGroup]
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            pageHeader
            searchField
                .padding(16)

            if displayedCards.isEmpty {
                ContentUnavailableView(
                    searchText.isEmpty ? "暂无名片" : "没有匹配的名片",
                    systemImage: searchText.isEmpty ? "person.2.slash" : "magnifyingglass",
                    description: Text(searchText.isEmpty ? "可从名片详情或保存结果页添加到这个分组。" : "请尝试其他姓名、公司或职位。")
                )
                .frame(maxHeight: .infinity)
                .accessibilityIdentifier("core.groupCards.empty")
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(displayedCards) { card in
                            cardRow(card)
                            Divider().padding(.leading, 112)
                        }
                    }
                }
            }
        }
        .background(.white)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .screenIdentifier("screen.groupCards")
    }

    private var pageHeader: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
                    .frame(width: 44, height: 44)
            }
            .accessibilityIdentifier("core.groupCards.back")
            Spacer()
            Text(title)
                .font(.headline)
                .lineLimit(1)
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 4)
        .overlay(alignment: .bottom) { Divider() }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("姓名/公司/职位", text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .accessibilityIdentifier("core.groupCards.search")
        }
        .padding(.horizontal, 14)
        .frame(height: 40)
        .background(AppColors.pageBackground, in: RoundedRectangle(cornerRadius: 9))
    }

    private func cardRow(_ card: BusinessCard) -> some View {
        Button {
            navigation.push(.cardDetail(card.id))
        } label: {
            HStack(spacing: 14) {
                StoredCardImage(relativePath: card.originalImagePath)
                    .frame(width: 82, height: 60)
                VStack(alignment: .leading, spacing: 5) {
                    Text(card.name.isEmpty ? "未填写姓名" : card.name)
                        .font(.headline)
                        .foregroundStyle(AppColors.textPrimary)
                    Text([card.company, card.jobTitle].filter { !$0.isEmpty }.joined(separator: " · "))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 82)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("core.groupCards.card.\(card.id.uuidString)")
    }

    private var displayedCards: [BusinessCard] {
        GroupCardFilter.cards(cards, matching: filter)
            .filter { $0.matches(searchText) }
    }

    private var title: String {
        switch filter {
        case let .custom(groupID):
            groups.first(where: { $0.id == groupID })?.name ?? "分组"
        case .recent30Days: "近30天看过的名片"
        case .recentlyAdded: "最近新增"
        case .ungrouped: "未分组"
        case .byJob: "按职位分组"
        case .byCity: "按城市分组"
        }
    }
}

#Preview {
    NavigationStack {
        GroupCardsView(filter: .recentlyAdded)
    }
    .environment(AppNavigationModel(initialStage: .main))
    .modelContainer(for: [BusinessCard.self, CardGroup.self], inMemory: true)
}
