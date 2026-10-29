import SwiftUI

struct PlaceholderSheet: View {
    let action: PlaceholderAction
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 22) {
            Spacer(minLength: 6)

            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.12))
                    .frame(width: 82, height: 82)
                Image(systemName: action.symbol)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(AppColors.primary)
            }

            VStack(spacing: 8) {
                Text(action.title)
                    .font(.title3.weight(.semibold))
                Text("演示版本暂未开放")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppColors.primary)
                Text(action.message)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Button("关闭") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.primary)
            .controlSize(.large)
            .accessibilityIdentifier("placeholder.close")

            Text("来源：\(action.source)")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            Spacer(minLength: 8)
        }
        .frame(maxWidth: .infinity)
        .background(AppColors.pageBackground)
        .screenIdentifier("placeholder.sheet")
    }
}

struct EnterpriseView: View {
    var body: some View {
        PlaceholderTabPage(
            title: "企业",
            subtitle: "让团队名片与客户资产协同管理",
            symbol: "building.2.crop.circle.fill",
            accent: AppColors.primaryDark,
            cards: [
                ("企业认证", "验证组织信息并点亮企业标识", "checkmark.shield.fill"),
                ("团队名片库", "统一管理员工数字名片", "person.3.fill"),
                ("数据洞察", "查看名片交换与客户趋势", "chart.bar.xaxis")
            ],
            source: "enterprise"
        )
        .screenIdentifier("screen.enterprise")
    }
}

struct ProfileView: View {
    var body: some View {
        PlaceholderTabPage(
            title: "我",
            subtitle: "本地演示账号",
            symbol: "person.crop.circle.fill",
            accent: Color.indigo,
            cards: [
                ("我的数字名片", "管理展示资料与名片样式", "person.text.rectangle.fill"),
                ("识别与导入设置", "语言、相册与隐私偏好", "slider.horizontal.3"),
                ("帮助与反馈", "查看教程和常见问题", "questionmark.bubble.fill")
            ],
            source: "profile"
        )
        .screenIdentifier("screen.profile")
    }
}

private struct PlaceholderTabPage: View {
    let title: String
    let subtitle: String
    let symbol: String
    let accent: Color
    let cards: [(String, String, String)]
    let source: String
    @Environment(AppNavigationModel.self) private var navigation

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                HStack(spacing: 16) {
                    Image(systemName: symbol)
                        .font(.system(size: 42))
                        .foregroundStyle(.white)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(title)
                            .font(.largeTitle.bold())
                        Text(subtitle)
                            .font(.subheadline)
                            .opacity(0.8)
                    }
                    .foregroundStyle(.white)
                    Spacer()
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(colors: [accent, accent.opacity(0.72)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
                )

                ForEach(Array(cards.enumerated()), id: \.offset) { index, card in
                    Button {
                        navigation.showPlaceholder(
                            id: "\(source).card.\(index)",
                            title: card.0,
                            source: source,
                            symbol: card.2
                        )
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: card.2)
                                .font(.title2)
                                .foregroundStyle(accent)
                                .frame(width: 48, height: 48)
                                .background(accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(card.0)
                                    .font(.headline)
                                    .foregroundStyle(AppColors.textPrimary)
                                Text(card.1)
                                    .font(.subheadline)
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                        .appCard(padding: 16)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("placeholder.\(source).card.\(index)")
                }
            }
            .padding(AppSize.pageInset)
        }
        .background(AppColors.pageBackground)
    }
}
