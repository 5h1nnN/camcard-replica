import SwiftUI

struct HomeView: View {
    @Environment(AppNavigationModel.self) private var navigation
    @State private var showsInvitation = true

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                SearchHeader(source: "home") {
                    navigation.push(.capture)
                }

                if showsInvitation {
                    invitationBanner
                }

                digitalCard
                weChatButton
                featureHighlights
                serviceGrid
                latestMessages
                promotionStrip
            }
            .padding(.horizontal, AppSize.pageInset)
            .padding(.top, 10)
            .padding(.bottom, 18)
        }
        .background(AppColors.pageBackground)
        .screenIdentifier("screen.home")
    }

    private var invitationBanner: some View {
        HStack(spacing: 12) {
            DemoAvatar(initials: "友", size: 44, color: AppColors.primary)
            Text("名片助手邀请你交换名片")
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity, alignment: .leading)
            Button("接受") {
                placeholder("invitation.accept", "交换名片邀请", symbol: "person.2.fill")
            }
            .buttonStyle(.bordered)
            .tint(AppColors.primary)
            .accessibilityIdentifier("placeholder.home.invitation.accept")
            Button {
                withAnimation { showsInvitation = false }
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel("关闭邀请")
            .accessibilityIdentifier("core.home.invitation.close")
        }
        .padding(12)
        .background(AppColors.primary.opacity(0.1), in: RoundedRectangle(cornerRadius: AppRadius.medium))
    }

    private var digitalCard: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AppColors.primaryDark, Color(red: 0.08, green: 0.42, blue: 0.62)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 222)
                    .overlay(alignment: .bottomTrailing) {
                        ZStack {
                            Circle().fill(.white.opacity(0.07)).frame(width: 210, height: 210)
                            Image(systemName: "mountain.2.fill")
                                .font(.system(size: 120))
                                .foregroundStyle(.white.opacity(0.09))
                        }
                        .offset(x: 34, y: 42)
                    }

                VStack(alignment: .leading, spacing: 9) {
                    Text("暂未填写公司")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.76))
                    Text("您的姓名")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.top, 12)
                    Text("暂未填写职位")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.82))
                    Text("191 1717 6020")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.82))
                    Text("—\n—")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(24)
            }

            HStack(spacing: 0) {
                FeatureIconButton(title: "编辑名片", symbol: "pencil") {
                    placeholder("digital.edit", "编辑数字名片", symbol: "pencil")
                }
                FeatureIconButton(title: "更换样式", symbol: "paintpalette") {
                    placeholder("digital.style", "更换名片样式", symbol: "paintpalette.fill")
                }
                FeatureIconButton(title: "更多分享", symbol: "square.and.arrow.up") {
                    placeholder("digital.share", "分享数字名片", symbol: "square.and.arrow.up")
                }
                FeatureIconButton(title: "切换名片", symbol: "arrow.left.arrow.right") {
                    placeholder("digital.switch", "切换名片", symbol: "arrow.left.arrow.right")
                }
            }
            .padding(.vertical, 12)
            .background(.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous))
        .shadow(color: AppShadow.cardColor, radius: AppShadow.cardRadius, y: AppShadow.cardY)
    }

    private var weChatButton: some View {
        Button {
            placeholder("wechat", "一键分享到微信", message: "演示版本不会调用微信或发送真实名片。", symbol: "bubble.left.and.bubble.right.fill")
        } label: {
            Label("一键分享到微信", systemImage: "bubble.left.and.bubble.right.fill")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    LinearGradient(colors: [Color.cyan, AppColors.primaryStrong], startPoint: .leading, endPoint: .trailing),
                    in: Capsule()
                )
        }
        .accessibilityIdentifier("placeholder.home.wechat")
    }

    private var featureHighlights: some View {
        HStack(spacing: 12) {
            highlightCard(
                title: "名片访客",
                subtitle: "近日有 1 位用户查看了你的名片",
                symbol: "person.crop.circle.badge.checkmark",
                color: .orange,
                id: "visitors"
            )
            highlightCard(
                title: "文字转名片",
                subtitle: "一键识别文本，自动保存成名片",
                symbol: "text.viewfinder",
                color: .purple,
                id: "textToCard"
            )
        }
    }

    private func highlightCard(title: String, subtitle: String, symbol: String, color: Color, id: String) -> some View {
        Button {
            placeholder(id, title, symbol: symbol)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(title).font(.headline)
                    Spacer()
                    Image(systemName: symbol)
                        .foregroundStyle(color)
                }
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.leading)
                    .frame(height: 34, alignment: .top)
                Text("立即体验  ›")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .appCard(padding: 14)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("placeholder.home.\(id)")
    }

    private var serviceGrid: some View {
        HStack(spacing: 0) {
            serviceButton("数字名片", "person.text.rectangle.fill", .blue, "digitalCard")
            serviceButton("企业认证", "checkmark.shield.fill", .cyan, "certification")
            serviceButton("名片更新", "arrow.triangle.2.circlepath", .green, "updates")
            serviceButton("精准识别", "viewfinder.circle.fill", .blue, "precision")
            serviceButton("VIP 服务", "diamond.fill", .orange, "vip")
        }
        .padding(.vertical, 14)
        .background(.white, in: RoundedRectangle(cornerRadius: AppRadius.medium))
    }

    private func serviceButton(_ title: String, _ symbol: String, _ color: Color, _ id: String) -> some View {
        Button {
            placeholder("service.\(id)", title, symbol: symbol)
        } label: {
            VStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.title2)
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 11))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("placeholder.home.service.\(id)")
    }

    private var latestMessages: some View {
        Button {
            placeholder("latestMessages", "最新消息", symbol: "bell.fill")
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 7) {
                    Text("最新消息")
                        .font(.headline)
                    Text("欢迎使用 Cardly，本地名片流程即将开放")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                Spacer()
                Text("查看全部消息")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .appCard(padding: 16)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("placeholder.home.latestMessages")
    }

    private var promotionStrip: some View {
        Button {
            placeholder("promotion", "限时优惠", message: "演示版本不提供购买或支付能力。", symbol: "tag.fill")
        } label: {
            HStack {
                Text("23 : 57 : 34 : 77")
                    .font(.system(.title3, design: .monospaced, weight: .semibold))
                    .foregroundStyle(.orange)
                Spacer()
                Text("立减 100 元  ›")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.orange, in: Capsule())
            }
            .padding(14)
            .background(Color.orange.opacity(0.14), in: RoundedRectangle(cornerRadius: AppRadius.medium))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("placeholder.home.promotion")
    }

    private func placeholder(_ id: String, _ title: String, message: String = "该功能用于展示完整产品入口，演示版本暂未开放。", symbol: String) {
        navigation.showPlaceholder(id: "home.\(id)", title: title, message: message, source: "首页", symbol: symbol)
    }
}

#Preview {
    HomeView()
        .environment(AppNavigationModel(initialStage: .main))
}
