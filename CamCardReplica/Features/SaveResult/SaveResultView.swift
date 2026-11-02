import SwiftUI
import SwiftData

struct SaveResultView: View {
    @Environment(AppNavigationModel.self) private var navigation
    @Environment(CardImportSession.self) private var importSession
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Query(sort: \BusinessCard.updatedAt, order: .reverse) private var cards: [BusinessCard]

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
        .onAppear {
            navigation.captureState = .completed
        }
    }

    private var successHeader: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                colors: [AppColors.primaryStrong, AppColors.primary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: dynamicTypeSize.isAccessibilitySize ? 250 : 210)

            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(spacing: 18) {
                        Label("名片保存成功", systemImage: "checkmark.circle.fill")
                            .font(.title2.weight(.medium))
                            .multilineTextAlignment(.center)
                        doneButton
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 42)
                } else {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("名片保存成功")
                            .font(.title2.weight(.medium))
                    }
                    .frame(maxWidth: .infinity)
                    .overlay(alignment: .trailing) {
                        doneButton
                            .padding(.trailing, 20)
                    }
                    .padding(.top, 38)
                }
            }
            .foregroundStyle(.white)
        }
    }

    private var doneButton: some View {
        Button("完成") {
            navigation.returnToCards()
        }
        .font(.headline)
        .foregroundStyle(.white)
        .accessibilityIdentifier("core.result.done")
    }

    private var summaryCard: some View {
        VStack(spacing: 16) {
            Button {
                if let cardID = importSession.savedCardID {
                    navigation.push(.cardDetail(cardID))
                }
            } label: {
                HStack(spacing: 14) {
                    Group {
                        if let image = importSession.selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        } else {
                            DemoBusinessCardImage(compact: true)
                        }
                    }
                    .frame(width: 114)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(summaryDraft.name.isEmpty ? "未填写姓名" : summaryDraft.name)
                            .font(.title2)
                            .foregroundStyle(AppColors.textPrimary)
                            .lineLimit(2)
                        Text(summaryDraft.jobTitle.isEmpty ? "未填写职位" : summaryDraft.jobTitle)
                            .font(.body)
                            .foregroundStyle(AppColors.textSecondary)
                            .lineLimit(2)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("core.result.detail")

            Divider()

            if dynamicTypeSize.isAccessibilitySize {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 18) {
                    resultActionButtons
                }
            } else {
                HStack(spacing: 0) {
                    resultActionButtons
                }
            }
        }
        .appCard(padding: 16)
    }

    @ViewBuilder
    private var resultActionButtons: some View {
        actionButton("分组", "person.2.fill", "group")
        actionButton("备注", "note.text", "note")
        actionButton("提醒", "alarm.fill", "reminder")
        actionButton("存入通讯录", "person.crop.rectangle.fill", "contacts")
    }

    private func actionButton(_ title: String, _ symbol: String, _ id: String) -> some View {
        FeatureIconButton(title: title, symbol: symbol) {
            if id == "note" {
                navigation.push(.review)
                return
            }
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
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 8) {
                    nextCardButton
                    returnToCardsButton
                }
            } else {
                HStack(spacing: 12) {
                    nextCardButton
                    returnToCardsButton
                }
            }
        }
    }

    private var nextCardButton: some View {
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
    }

    private var returnToCardsButton: some View {
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

    private var summaryDraft: BusinessCardDraft {
        guard let savedCardID = importSession.savedCardID,
              let card = cards.first(where: { $0.id == savedCardID }) else {
            return importSession.draft
        }
        return card.draft
    }
}

#Preview {
    NavigationStack {
        SaveResultView()
    }
    .environment(AppNavigationModel(initialStage: .main))
    .environment(CardImportSession())
    .modelContainer(for: BusinessCard.self, inMemory: true)
}

#Preview("超大动态字体") {
    NavigationStack {
        SaveResultView()
    }
    .environment(AppNavigationModel(initialStage: .main))
    .environment(CardImportSession())
    .environment(\.dynamicTypeSize, .accessibility2)
    .modelContainer(for: BusinessCard.self, inMemory: true)
}
