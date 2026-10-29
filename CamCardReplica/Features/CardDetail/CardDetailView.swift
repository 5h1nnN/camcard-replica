import SwiftUI

struct CardDetailView: View {
    let cardID: UUID
    @Environment(AppNavigationModel.self) private var navigation
    @Environment(CardImportSession.self) private var importSession
    @Environment(\.dismiss) private var dismiss
    @State private var isFavorite = false

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                AppColors.primaryDark
                    .frame(height: 214)
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
            Button {
                isFavorite.toggle()
            } label: {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .font(.title3)
                    .foregroundStyle(isFavorite ? .yellow : .white)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(isFavorite ? "取消收藏" : "收藏")
            .accessibilityIdentifier("core.detail.favorite")
            Button {
                placeholder("moreMenu", "更多操作", "ellipsis")
            } label: {
                Image(systemName: "ellipsis")
                    .font(.title3)
                    .frame(width: 44, height: 44)
            }
            .accessibilityIdentifier("placeholder.detail.moreMenu")
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 4)
        .frame(height: 56)
    }

    private var identityCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                DemoAvatar(initials: initials, size: 68, color: .purple)
                VStack(alignment: .leading, spacing: 6) {
                    Text(display(importSession.draft.name, fallback: "未填写姓名"))
                        .font(.title2.weight(.semibold))
                    Text(display(importSession.draft.jobTitle, fallback: "未填写职位"))
                        .font(.body)
                        .foregroundStyle(AppColors.textSecondary)
                }
                Spacer()
                Label("识别完成", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppColors.success)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(AppColors.success.opacity(0.1), in: Capsule())
            }

            VStack(alignment: .leading, spacing: 10) {
                Label(display(importSession.draft.mobilePhone, fallback: "未填写电话"), systemImage: "phone.fill")
                Label(display(importSession.draft.address, fallback: "未填写地址"), systemImage: "mappin.and.ellipse")
                    .lineLimit(2)
            }
            .font(.subheadline)
            .foregroundStyle(AppColors.textSecondary)
        }
        .appCard(padding: 16)
    }

    private var quickActions: some View {
        HStack(spacing: 0) {
            quickButton("电话", "phone.fill", .blue, "call")
            quickButton("地址", "mappin", .orange, "address")
            quickButton("备注", "note.text", .green, "note")
            FeatureIconButton(title: "编辑", symbol: "pencil", color: .teal) {
                navigation.push(.review)
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
            metadataButton("备注：2026-10-29 其他方式保存", "note.text", "noteMetadata")
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
            contactRow(display(importSession.draft.mobilePhone, fallback: "未填写电话"), "phone.fill", trailingSymbol: "message.fill", id: "phone")
            Divider().padding(.leading, 52)
            contactRow(display(importSession.draft.email, fallback: "未填写邮箱"), "envelope.fill", id: "email")
            Divider().padding(.leading, 52)
            contactRow(display(importSession.draft.address, fallback: "未填写地址"), "mappin.and.ellipse", id: "addressField")
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
        HStack(spacing: 8) {
            Button {
                placeholder("contacts", "存入通讯录", "person.crop.rectangle")
            } label: {
                VStack(spacing: 3) {
                    Image(systemName: "person.crop.rectangle")
                    Text("存入通讯录")
                        .font(.caption2)
                }
                .frame(width: 74, height: 50)
            }
            .buttonStyle(.plain)
            .foregroundStyle(AppColors.primary)
            .accessibilityIdentifier("placeholder.detail.contacts")

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
        importSession.draft.name.first.map(String.init) ?? "名"
    }

    private func display(_ value: String, fallback: String) -> String {
        value.isEmpty ? fallback : value
    }
}

#Preview {
    NavigationStack {
        CardDetailView(cardID: FixtureCatalog.demoID)
    }
    .environment(AppNavigationModel(initialStage: .main))
    .environment(CardImportSession())
}
