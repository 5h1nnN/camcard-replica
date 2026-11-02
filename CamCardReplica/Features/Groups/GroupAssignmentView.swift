import SwiftData
import SwiftUI

struct GroupAssignmentView: View {
    let cardID: UUID

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CardGroup.sortOrder) private var groups: [CardGroup]
    @Query private var cards: [BusinessCard]

    @State private var searchText = ""
    @State private var selectedGroupIDs: Set<UUID> = []
    @State private var didLoadSelection = false
    @State private var showsNewGroup = false
    @State private var newGroupName = ""
    @State private var operationError: String?

    private let suggestions = ["VIP", "客户", "供应商", "合作伙伴", "同行"]

    var body: some View {
        VStack(spacing: 0) {
            pageHeader
            ScrollView {
                LazyVStack(spacing: 0) {
                    searchField
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    createRow
                    Divider().padding(.leading, 56)
                    ungroupedRow
                    Divider().padding(.leading, 56)

                    ForEach(filteredGroups) { group in
                        groupRow(group)
                        Divider().padding(.leading, 56)
                    }

                    if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        suggestionSection
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(.white)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .screenIdentifier("screen.groupAssignment")
        .onAppear { loadSelectionIfNeeded() }
        .alert("新建分组", isPresented: $showsNewGroup) {
            TextField("请输入分组名称", text: $newGroupName)
                .accessibilityIdentifier("core.groupAssignment.newName")
            Button("取消", role: .cancel) { newGroupName = "" }
            Button("创建") { createAndSelectGroup() }
                .accessibilityIdentifier("core.groupAssignment.create")
        } message: {
            Text("新分组会自动选中。")
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
            .accessibilityIdentifier("core.groupAssignment.back")
            Spacer()
            Text("添加到分组")
                .font(.headline)
            Spacer()
            Button("完成") { saveSelection() }
                .frame(width: 44, height: 44)
                .accessibilityIdentifier("core.groupAssignment.done")
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
                .accessibilityIdentifier("core.groupAssignment.search")
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
        .accessibilityIdentifier("core.groupAssignment.new")
    }

    private var ungroupedRow: some View {
        Button {
            selectedGroupIDs.removeAll()
        } label: {
            assignmentRowLabel(title: "未分组", isSelected: selectedGroupIDs.isEmpty)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("core.groupAssignment.ungrouped")
    }

    private func groupRow(_ group: CardGroup) -> some View {
        Button {
            if selectedGroupIDs.contains(group.id) {
                selectedGroupIDs.remove(group.id)
            } else {
                selectedGroupIDs.insert(group.id)
            }
        } label: {
            assignmentRowLabel(title: group.name, isSelected: selectedGroupIDs.contains(group.id))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("core.groupAssignment.group.\(group.id.uuidString)")
    }

    private func assignmentRowLabel(title: String, isSelected: Bool) -> some View {
        HStack(spacing: 14) {
            Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                .font(.title3)
                .foregroundStyle(isSelected ? AppColors.primaryStrong : Color.secondary)
                .frame(width: 28)
            Text(title)
                .foregroundStyle(AppColors.textPrimary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 56)
        .contentShape(Rectangle())
    }

    private var suggestionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("你可能会用到的分组")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            FlowLayout(spacing: 10) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button {
                        selectSuggestedGroup(suggestion)
                    } label: {
                        Text(suggestion)
                            .font(.subheadline)
                            .foregroundStyle(AppColors.textPrimary)
                            .padding(.horizontal, 18)
                            .frame(height: 38)
                            .background(.white, in: Capsule())
                            .overlay { Capsule().stroke(Color.secondary.opacity(0.25)) }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("core.groupAssignment.suggestion.\(suggestion)")
                }
            }
        }
        .padding(16)
        .background(AppColors.pageBackground)
    }

    private var filteredGroups: [CardGroup] {
        groups.filter { $0.matches(searchText) }
    }

    private var card: BusinessCard? {
        cards.first { $0.id == cardID }
    }

    private func loadSelectionIfNeeded() {
        guard !didLoadSelection else { return }
        selectedGroupIDs = Set(card?.groupIDs ?? [])
        didLoadSelection = true
    }

    private func saveSelection() {
        guard let card else {
            operationError = "这张名片已不存在。"
            return
        }
        do {
            try CardGroupStore.setGroups(selectedGroupIDs, for: card, availableGroups: groups, in: modelContext)
            dismiss()
        } catch {
            operationError = error.localizedDescription
        }
    }

    private func createAndSelectGroup() {
        do {
            let group = try CardGroupStore.create(name: newGroupName, groups: groups, in: modelContext)
            selectedGroupIDs.insert(group.id)
            newGroupName = ""
        } catch {
            operationError = error.localizedDescription
        }
    }

    private func selectSuggestedGroup(_ name: String) {
        if let existing = groups.first(where: { $0.name == name }) {
            selectedGroupIDs.insert(existing.id)
            return
        }
        do {
            let group = try CardGroupStore.create(name: name, groups: groups, in: modelContext)
            selectedGroupIDs.insert(group.id)
        } catch {
            operationError = error.localizedDescription
        }
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                x = 0
                y += lineHeight + spacing
                lineHeight = 0
            }
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        return CGSize(width: width, height: y + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += lineHeight + spacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

#Preview("添加到分组") {
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
        GroupAssignmentView(cardID: card.id)
    }
    .modelContainer(container)
}
