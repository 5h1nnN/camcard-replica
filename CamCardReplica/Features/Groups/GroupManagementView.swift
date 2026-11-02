import SwiftData
import SwiftUI

struct GroupManagementView: View {
    @Environment(AppNavigationModel.self) private var navigation
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CardGroup.sortOrder) private var groups: [CardGroup]
    @Query private var cards: [BusinessCard]

    @State private var searchText = ""
    @State private var isEditing = false
    @State private var showsNewGroup = false
    @State private var newGroupName = ""
    @State private var groupToRename: CardGroup?
    @State private var renameText = ""
    @State private var groupToDelete: CardGroup?
    @State private var operationError: String?

    var body: some View {
        VStack(spacing: 0) {
            pageHeader
            ScrollView {
                LazyVStack(spacing: 0) {
                    searchField
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    createRow
                    sectionHeader("我的分组", showsSort: true)

                    if filteredGroups.isEmpty {
                        emptyCustomGroups
                    } else {
                        ForEach(filteredGroups) { group in
                            customGroupRow(group)
                            Divider().padding(.leading, 56)
                        }
                    }

                    if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        sectionHeader("智能分组")
                        smartGroupRow("近30天看过的名片", symbol: "clock.arrow.circlepath", filter: .recent30Days)
                        smartGroupRow("最近新增", symbol: "sparkles", filter: .recentlyAdded)
                        smartGroupRow("未分组", symbol: "person.crop.circle.badge.questionmark", filter: .ungrouped)
                        smartGroupRow("按职位分组", symbol: "person.text.rectangle", filter: .byJob)
                        smartGroupRow("按城市分组", symbol: "building.2", filter: .byCity)
                    }
                }
                .padding(.bottom, 28)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(.white)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .screenIdentifier("screen.groups")
        .alert("新建分组", isPresented: $showsNewGroup) {
            TextField("请输入分组名称", text: $newGroupName)
                .accessibilityIdentifier("core.groups.newName")
            Button("取消", role: .cancel) { newGroupName = "" }
            Button("创建") { createGroup() }
                .accessibilityIdentifier("core.groups.create")
        } message: {
            Text("创建后可将一张名片加入多个分组。")
        }
        .alert("重命名分组", isPresented: Binding(
            get: { groupToRename != nil },
            set: { if !$0 { groupToRename = nil } }
        )) {
            TextField("请输入分组名称", text: $renameText)
            Button("取消", role: .cancel) { groupToRename = nil }
            Button("保存") { renameGroup() }
        }
        .confirmationDialog(
            "删除“\(groupToDelete?.name ?? "")”？",
            isPresented: Binding(
                get: { groupToDelete != nil },
                set: { if !$0 { groupToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("删除分组", role: .destructive) { deleteGroup() }
            Button("取消", role: .cancel) { groupToDelete = nil }
        } message: {
            Text("名片不会被删除，只会从这个分组移除。")
        }
        .alert("无法完成操作", isPresented: Binding(
            get: { operationError != nil },
            set: { if !$0 { operationError = nil } }
        )) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text(operationError ?? "请稍后重试。")
        }
    }

    private var pageHeader: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
                    .frame(width: 44, height: 44)
            }
            .accessibilityIdentifier("core.groups.back")

            Spacer()
            Text("分组")
                .font(.headline)
            Spacer()

            Button(isEditing ? "完成" : "编辑") {
                withAnimation(.easeInOut(duration: 0.2)) { isEditing.toggle() }
            }
            .frame(width: 44, height: 44)
            .accessibilityIdentifier("core.groups.edit")
        }
        .foregroundStyle(AppColors.textPrimary)
        .padding(.horizontal, 4)
        .overlay(alignment: .bottom) { Divider() }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("请输入分组名称", text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .accessibilityIdentifier("core.groups.search")
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .accessibilityLabel("清空搜索")
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 40)
        .background(AppColors.pageBackground, in: RoundedRectangle(cornerRadius: 9))
    }

    private var createRow: some View {
        Button {
            newGroupName = ""
            showsNewGroup = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "plus")
                    .font(.body.weight(.semibold))
                    .frame(width: 28)
                Text("新建分组")
                Spacer()
            }
            .foregroundStyle(AppColors.primaryStrong)
            .padding(.horizontal, 16)
            .frame(minHeight: 54)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("core.groups.new")
    }

    private func sectionHeader(_ title: String, showsSort: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            if showsSort && groups.count > 1 {
                Button {
                    sortGroups()
                } label: {
                    Label("排序", systemImage: "arrow.up.arrow.down")
                        .font(.subheadline)
                }
                .accessibilityIdentifier("core.groups.sort")
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 42)
        .background(AppColors.pageBackground)
    }

    private var emptyCustomGroups: some View {
        Text(searchText.isEmpty ? "暂无自定义分组" : "没有匹配的分组")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 58)
            .frame(height: 54)
            .accessibilityIdentifier("core.groups.empty")
    }

    private func customGroupRow(_ group: CardGroup) -> some View {
        HStack(spacing: 14) {
            Button {
                navigation.push(.groupCards(.custom(group.id)))
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "folder.fill")
                        .foregroundStyle(.orange)
                        .frame(width: 28)
                    Text("\(group.name)(\(cardCount(in: group)))")
                        .foregroundStyle(AppColors.textPrimary)
                    Spacer()
                    if !isEditing {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isEditing {
                Button {
                    groupToRename = group
                    renameText = group.name
                } label: {
                    Image(systemName: "pencil")
                        .frame(width: 34, height: 44)
                }
                .accessibilityLabel("重命名\(group.name)")
                Button(role: .destructive) {
                    groupToDelete = group
                } label: {
                    Image(systemName: "trash")
                        .frame(width: 34, height: 44)
                }
                .accessibilityLabel("删除\(group.name)")
            }
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 56)
        .accessibilityIdentifier("core.groups.custom.\(group.id.uuidString)")
    }

    private func smartGroupRow(_ title: String, symbol: String, filter: CardGroupFilter) -> some View {
        Button {
            navigation.push(.groupCards(filter))
        } label: {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .foregroundStyle(AppColors.primary)
                    .frame(width: 28)
                Text("\(title)(\(smartCards(for: filter).count))")
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) { Divider().padding(.leading, 56) }
        .accessibilityIdentifier("core.groups.smart.\(filter.accessibilityKey)")
    }

    private var filteredGroups: [CardGroup] {
        groups.filter { $0.matches(searchText) }
    }

    private func cardCount(in group: CardGroup) -> Int {
        cards.count { $0.groupIDs.contains(group.id) }
    }

    private func smartCards(for filter: CardGroupFilter) -> [BusinessCard] {
        GroupCardFilter.cards(cards, matching: filter)
    }

    private func createGroup() {
        do {
            _ = try CardGroupStore.create(name: newGroupName, groups: groups, in: modelContext)
            newGroupName = ""
        } catch {
            operationError = error.localizedDescription
        }
    }

    private func renameGroup() {
        guard let group = groupToRename else { return }
        do {
            try CardGroupStore.rename(group, to: renameText, groups: groups, in: modelContext)
            groupToRename = nil
        } catch {
            operationError = error.localizedDescription
        }
    }

    private func deleteGroup() {
        guard let group = groupToDelete else { return }
        do {
            try CardGroupStore.delete(group, cards: cards, in: modelContext)
            groupToDelete = nil
        } catch {
            operationError = error.localizedDescription
        }
    }

    private func sortGroups() {
        let sorted = groups.sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
        for (index, group) in sorted.enumerated() {
            group.sortOrder = index
            group.updatedAt = .now
        }
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            operationError = "无法保存排序，请稍后重试。"
        }
    }
}

private extension CardGroupFilter {
    var accessibilityKey: String {
        switch self {
        case .custom: "custom"
        case .recent30Days: "recent30Days"
        case .recentlyAdded: "recentlyAdded"
        case .ungrouped: "ungrouped"
        case .byJob: "byJob"
        case .byCity: "byCity"
        }
    }
}

#Preview("分组管理") {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: BusinessCard.self,
        CardGroup.self,
        configurations: configuration
    )
    let group = CardGroup(name: "测试")
    container.mainContext.insert(group)
    let card = BusinessCard(draft: .fixture, groupIDs: [group.id])
    container.mainContext.insert(card)

    return NavigationStack {
        GroupManagementView()
    }
    .environment(AppNavigationModel(initialStage: .main))
    .modelContainer(container)
}
