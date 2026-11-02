import SwiftUI
import UIKit

struct DemoAvatar: View {
    let initials: String
    var size: CGFloat = 48
    var color: Color = AppColors.primaryDark

    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [color.opacity(0.72), color],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                Text(initials)
                    .font(.system(size: size * 0.38, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

struct SearchHeader: View {
    let source: String
    let addAction: () -> Void
    @Environment(AppNavigationModel.self) private var navigation

    var body: some View {
        HStack(spacing: 12) {
            Button {
                navigation.showPlaceholder(
                    id: "\(source).messages",
                    title: "消息中心",
                    source: source,
                    symbol: "message.fill"
                )
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
            .accessibilityIdentifier("placeholder.\(source).messages")

            Button {
                navigation.showPlaceholder(
                    id: "\(source).search",
                    title: "搜索",
                    message: source == "cards" ? "请使用名片夹顶部搜索框查找已保存名片。" : "可前往名片夹搜索已保存名片；演示首页搜索暂未开放。",
                    source: source,
                    symbol: "magnifyingglass"
                )
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                    Text("请输入姓名/公司/职位搜索")
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14)
                .frame(height: 44)
                .background(.white, in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("placeholder.\(source).search")

            Button(action: addAction) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 31, weight: .regular))
                    .foregroundStyle(AppColors.textPrimary)
            }
            .accessibilityIdentifier("core.\(source).add")
        }
    }
}

struct FeatureIconButton: View {
    let title: String
    let symbol: String
    var color: Color = AppColors.primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 44, height: 38)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

struct DemoBusinessCardImage: View {
    var compact = false

    var body: some View {
        Image("SyntheticBusinessCard")
            .resizable()
            .scaledToFit()
            .clipShape(RoundedRectangle(cornerRadius: compact ? 6 : 12, style: .continuous))
            .accessibilityLabel("合成演示名片")
    }
}

struct StoredCardImage: View {
    let relativePath: String?
    var cornerRadius: CGFloat = 10
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(
                    colors: [AppColors.primary.opacity(0.08), AppColors.primary.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay {
                    Image(systemName: "person.text.rectangle.fill")
                        .font(.title2)
                        .foregroundStyle(AppColors.primary)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .clipped()
        .task(id: relativePath) {
            let path = relativePath
            let store = CardImageStore.live
            let data = await Task.detached(priority: .utility) {
                try? store.load(relativePath: path)
            }.value
            image = data.flatMap(UIImage.init(data:))
        }
        .accessibilityHidden(true)
    }
}

extension View {
    func appCard(padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
            .shadow(color: AppShadow.cardColor, radius: AppShadow.cardRadius, y: AppShadow.cardY)
    }

    func screenIdentifier(_ identifier: String) -> some View {
        overlay(alignment: .topLeading) {
            Text(identifier)
                .font(.system(size: 1))
                .foregroundStyle(.clear)
                .frame(width: 1, height: 1)
                .accessibilityLabel(identifier)
                .accessibilityIdentifier(identifier)
        }
    }
}
