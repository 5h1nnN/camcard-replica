import SwiftUI
import SwiftData

struct CardDetailView: View {
    let cardID: UUID
    @Environment(AppNavigationModel.self) private var navigation
    @Environment(CardImportSession.self) private var importSession
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Query private var cards: [BusinessCard]
    @State private var demoIsFavorite = false
    @State private var showsDeleteConfirmation = false
    @State private var operationError: String?

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                AppColors.primaryDark
                    .frame(height: detailHeroHeight)
                VStack(spacing: 0) {
                    detailHeader
                    identityCard
                        .padding(.horizontal, 12)
                        .padding(.top, 18)
                }
            }

            ScrollView {
                LazyVStack(spacing: 12) {
                    quickActions
                    metadataSection
                    contactSection
                }
                .padding(.bottom, 18)
            }

            bottomActions
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                .background(.white)
                .overlay(alignment: .top) { Divider() }
        }
        .background(AppColors.pageBackground)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .screenIdentifier("screen.detail")
        .confirmationDialog(
            "删除这张名片？",
            isPresented: $showsDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("删除名片", role: .destructive) {
                deleteCard()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("名片信息和本地原图都会被删除，此操作无法撤销。")
        }
        .alert("操作失败", isPresented: Binding(
            get: { operationError != nil },
            set: { if !$0 { operationError = nil } }
        )) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text(operationError ?? "请稍后重试。")
        }
    }

    private var detailHeader: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
                    .frame(width: 44, height: 44)
            }
            .accessibilityIdentifier("core.detail.back")

            Text("名片详情")
                .font(.title3.weight(.semibold))
            Spacer()
            Button(action: toggleFavorite) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .font(.title3)
                    .foregroundStyle(isFavorite ? .yellow : .white)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(isFavorite ? "取消收藏" : "收藏")
            .accessibilityIdentifier("core.detail.favorite")
            Button {
                if storedCard != nil {
                    showsDeleteConfirmation = true
                } else {
                    placeholder("moreMenu", "更多操作", "ellipsis")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.title3)
                    .frame(width: 44, height: 44)
            }
            .accessibilityIdentifier(storedCard == nil ? "placeholder.detail.moreMenu" : "core.detail.moreMenu")
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 4)
        .frame(height: 56)
    }

    private var identityCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            identityHeader

            VStack(alignment: .leading, spacing: 10) {
                Label(display(currentDraft.mobilePhone, fallback: "未填写电话"), systemImage: "phone.fill")
                Label(display(currentDraft.address, fallback: "未填写地址"), systemImage: "mappin.and.ellipse")
                    .lineLimit(2)
            }
            .font(.subheadline)
            .foregroundStyle(AppColors.textSecondary)
        }
        .appCard(padding: 16)
    }

    @ViewBuilder
    private var identityHeader: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 14) {
                    DemoAvatar(initials: initials, size: 68, color: .purple)
                    identityText
                }
                recognitionBadge
            }
        } else {
            HStack(alignment: .top, spacing: 14) {
                DemoAvatar(initials: initials, size: 68, color: .purple)
                identityText
                Spacer()
                recognitionBadge
            }
        }
    }

    private var identityText: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(display(currentDraft.name, fallback: "未填写姓名"))
                .font(.title2.weight(.semibold))
                .lineLimit(2)
            Text(display(currentDraft.jobTitle, fallback: "未填写职位"))
                .font(.body)
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(2)
        }
    }

    private var recognitionBadge: some View {
        Label("识别完成", systemImage: "checkmark.circle.fill")
            .font(.caption.weight(.medium))
            .foregroundStyle(AppColors.success)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(AppColors.success.opacity(0.1), in: Capsule())
    }

    private var quickActions: some View {
        HStack(spacing: 0) {
            quickButton("电话", "phone.fill", .blue, "call")
            quickButton("地址", "mappin", .orange, "address")
            FeatureIconButton(title: "备注", symbol: "note.text", color: .green) {
                beginEditing()
            }
            .accessibilityIdentifier("core.detail.note")
            FeatureIconButton(title: "编辑", symbol: "pencil", color: .teal) {
                beginEditing()
            }
            .accessibilityIdentifier("core.detail.edit")
        }
        .padding(.vertical, 14)
        .background(.white)
    }

    private func quickButton(_ title: String, _ symbol: String, _ color: Color, _ id: String) -> some View {
        FeatureIconButton(title: title, symbol: symbol, color: color) {
            placeholder(id, title, symbol)
        }
        .accessibilityIdentifier("placeholder.detail.\(id)")
    }

    private var metadataSection: some View {
        VStack(spacing: 0) {
            metadataButton("未分组", "person.2.fill", "group")
            Divider().padding(.leading, 48)
            Button(action: beginEditing) {
                HStack(spacing: 16) {
                    Image(systemName: "note.text")
                        .foregroundStyle(.secondary)
                        .frame(width: 28)
                    Text(currentDraft.notes.isEmpty ? "备注：未填写" : "备注：\(currentDraft.notes)")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(2)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(16)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("core.detail.noteMetadata")
        }
        .background(.white)
    }

    private func metadataButton(_ title: String, _ symbol: String, _ id: String) -> some View {
        Button {
            placeholder(id, title, symbol)
        } label: {
            HStack(spacing: 16) {
                Image(systemName: symbol)
                    .foregroundStyle(.secondary)
                    .frame(width: 28)
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("placeholder.detail.\(id)")
    }

    private var contactSection: some View {
        VStack(spacing: 0) {
            contactRow(display(currentDraft.mobilePhone, fallback: "未填写电话"), "phone.fill", trailingSymbol: "message.fill", id: "phone")
            Divider().padding(.leading, 52)
            contactRow(display(currentDraft.email, fallback: "未填写邮箱"), "envelope.fill", id: "email")
            Divider().padding(.leading, 52)
            contactRow(display(currentDraft.address, fallback: "未填写地址"), "mappin.and.ellipse", id: "addressField")
            Divider().padding(.leading, 52)
            Button {
                placeholder("moreFields", "更多字段", "chevron.down")
            } label: {
                Label("更多", systemImage: "chevron.down")
                    .labelStyle(.titleAndIcon)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(16)
            }
            .accessibilityIdentifier("placeholder.detail.moreFields")
        }
        .background(.white)
    }

    private func contactRow(_ title: String, _ symbol: String, trailingSymbol: String? = nil, id: String) -> some View {
        Button {
            placeholder(id, title, symbol)
        } label: {
            HStack(spacing: 16) {
                Image(systemName: symbol)
                    .foregroundStyle(.secondary)
                    .frame(width: 28)
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                if let trailingSymbol {
                    Image(systemName: trailingSymbol)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("placeholder.detail.\(id)")
    }

    private var bottomActions: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 8) {
                    contactsButton
                    exchangeButton
                    shareButton
                }
            } else {
                HStack(spacing: 8) {
                    contactsButton
                    exchangeButton
                    shareButton
                }
            }
        }
    }

    private var contactsButton: some View {
        Button {
            placeholder("contacts", "存入通讯录", "person.crop.rectangle")
        } label: {
            if dynamicTypeSize.isAccessibilitySize {
                Label("存入通讯录", systemImage: "person.crop.rectangle")
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            } else {
                VStack(spacing: 3) {
                    Image(systemName: "person.crop.rectangle")
                    Text("存入通讯录")
                        .font(.caption2)
                }
                .frame(width: 74, height: 50)
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(AppColors.primary)
        .accessibilityIdentifier("placeholder.detail.contacts")
    }

    private var exchangeButton: some View {
        Button {
            placeholder("exchange", "向对方递名片", "rectangle.on.rectangle.angled")
        } label: {
            Text("向对方递名片")
                .frame(maxWidth: .infinity)
                .frame(height: 46)
        }
        .buttonStyle(.bordered)
        .tint(AppColors.primary)
        .accessibilityIdentifier("placeholder.detail.exchange")
    }

    private var shareButton: some View {
        Button {
            placeholder("share", "分享名片", "bubble.left.and.bubble.right.fill")
        } label: {
            Label("分享名片", systemImage: "bubble.left.and.bubble.right.fill")
                .frame(maxWidth: .infinity)
                .frame(height: 46)
        }
        .buttonStyle(.borderedProminent)
        .tint(.green)
        .accessibilityIdentifier("placeholder.detail.share")
    }

    private var detailHeroHeight: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 350 : 214
    }

    private func placeholder(_ id: String, _ title: String, _ symbol: String) {
        navigation.showPlaceholder(
            id: "detail.\(id)",
            title: title,
            message: id == "contacts" ? "演示版本不会写入系统通讯录。" : "该操作入口已保留，演示版本暂未开放。",
            source: "名片详情",
            symbol: symbol
        )
    }

    private var initials: String {
        currentDraft.name.first.map(String.init) ?? "名"
    }

    private var storedCard: BusinessCard? {
        cards.first(where: { $0.id == cardID })
    }

    private var currentDraft: BusinessCardDraft {
        storedCard?.draft ?? .fixture
    }

    private var isFavorite: Bool {
        storedCard?.isFavorite ?? demoIsFavorite
    }

    private func display(_ value: String, fallback: String) -> String {
        value.isEmpty ? fallback : value
    }

    private func beginEditing() {
        guard let card = storedCard else {
            importSession.loadFixture()
            navigation.push(.review)
            return
        }

        do {
            let imageData = try CardImageStore.live.load(relativePath: card.originalImagePath)
            importSession.prepareForEditing(card, imageData: imageData)
            navigation.push(.review)
        } catch {
            operationError = "无法读取原图，名片字段仍然安全保留。请释放存储空间后重试。"
        }
    }

    private func toggleFavorite() {
        guard let card = storedCard else {
            demoIsFavorite.toggle()
            return
        }
        card.isFavorite.toggle()
        card.updatedAt = .now
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            operationError = "无法保存收藏状态，请稍后重试。"
        }
    }

    private func deleteCard() {
        guard let card = storedCard else { return }
        do {
            try BusinessCardPersistence.delete(card, in: modelContext)
            navigation.returnToCards()
        } catch {
            operationError = "删除未完成，请检查设备存储后重试。"
        }
    }
}

#Preview {
    NavigationStack {
        CardDetailView(cardID: FixtureCatalog.demoID)
    }
    .environment(AppNavigationModel(initialStage: .main))
    .environment(CardImportSession())
    .modelContainer(for: BusinessCard.self, inMemory: true)
}

#Preview("超大动态字体") {
    NavigationStack {
        CardDetailView(cardID: FixtureCatalog.demoID)
    }
    .environment(AppNavigationModel(initialStage: .main))
    .environment(CardImportSession())
    .environment(\.dynamicTypeSize, .accessibility2)
    .modelContainer(for: BusinessCard.self, inMemory: true)
}
