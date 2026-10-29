import SwiftUI

struct SaveResultView: View {
    @Environment(AppNavigationModel.self) private var navigation

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    successHeader
                    summaryCard
                        .padding(.horizontal, AppSize.pageInset)
                        .offset(y: -42)
                    Spacer(minLength: 260)
                }
            }

            bottomActions
                .padding(.horizontal, AppSize.pageInset)
                .padding(.vertical, 12)
                .background(.white)
        }
        .background(AppColors.pageBackground)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .screenIdentifier("screen.result")
    }

    private var successHeader: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(
                colors: [AppColors.primaryStrong, AppColors.primary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 210)

            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                Text("名片保存成功")
                    .font(.title2.weight(.medium))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.top, 38)

            Button("完成") {
                navigation.returnToCards()
            }
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.top, 42)
            .padding(.trailing, 20)
            .accessibilityIdentifier("core.result.done")
        }
    }

    private var summaryCard: some View {
        VStack(spacing: 16) {
            Button {
                navigation.push(.cardDetail(FixtureCatalog.demoID))
            } label: {
                HStack(spacing: 14) {
                    DemoBusinessCardImage(compact: true)
                        .frame(width: 114)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(FixtureCatalog.syntheticBusinessCard.name)
                            .font(.title2)
                            .foregroundStyle(AppColors.textPrimary)
                        Text(FixtureCatalog.syntheticBusinessCard.jobTitle)
                            .font(.body)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("core.result.detail")

            Divider()

            HStack(spacing: 0) {
                actionButton("分组", "person.2.fill", "group")
                actionButton("备注", "note.text", "note")
                actionButton("提醒", "alarm.fill", "reminder")
                actionButton("存入通讯录", "person.crop.rectangle.fill", "contacts")
            }
        }
        .appCard(padding: 16)
    }

    private func actionButton(_ title: String, _ symbol: String, _ id: String) -> some View {
        FeatureIconButton(title: title, symbol: symbol) {
            navigation.showPlaceholder(
                id: "result.\(id)",
                title: title,
                message: id == "contacts" ? "演示版本不会写入系统通讯录。" : "该操作入口已保留，演示版本暂未开放。",
                source: "保存结果",
                symbol: symbol
            )
        }
        .accessibilityIdentifier("placeholder.result.\(id)")
    }

    private var bottomActions: some View {
        HStack(spacing: 12) {
            Button {
                navigation.path = [.capture]
            } label: {
                Label("拍下一张", systemImage: "camera.fill")
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.bordered)
            .tint(AppColors.primary)
            .accessibilityIdentifier("core.result.next")

            Button {
                navigation.returnToCards()
            } label: {
                Label("返回名片夹", systemImage: "paperplane.fill")
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.primary)
            .accessibilityIdentifier("core.result.returnCards")
        }
    }
}

#Preview {
    NavigationStack {
        SaveResultView()
    }
    .environment(AppNavigationModel(initialStage: .main))
}
