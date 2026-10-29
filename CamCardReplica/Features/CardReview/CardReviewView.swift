import SwiftUI
import UIKit

struct CardReviewView: View {
    @Environment(AppNavigationModel.self) private var navigation
    @Environment(CardImportSession.self) private var importSession
    @Environment(\.dismiss) private var dismiss
    @State private var usesPrecision = false

    var body: some View {
        VStack(spacing: 0) {
            reviewHeader

            ScrollView {
                LazyVStack(spacing: 12) {
                    cardPreview
                    if importSession.isManualEntry {
                        manualEntryBanner
                    }
                    recognitionSettings
                    languageRow
                    ReviewFieldSection(title: "姓名", showsAdd: false) {
                        fieldRow(type: "姓名", text: draftBinding(\.name))
                    }
                    ReviewFieldSection(title: "电话", showsAdd: true, addAction: addPhone) {
                        fieldRow(type: "手机", text: draftBinding(\.mobilePhone))
                        Divider().padding(.leading, 110)
                        fieldRow(type: "座机", text: draftBinding(\.officePhone))
                    }
                    ReviewFieldSection(title: "邮箱", showsAdd: true, addAction: addEmail) {
                        fieldRow(type: "工作邮箱", text: draftBinding(\.email))
                    }
                    ReviewFieldSection(title: "公司", showsAdd: true, addAction: addCompany) {
                        fieldRow(type: "公司", text: draftBinding(\.company))
                        Divider().padding(.leading, 110)
                        fieldRow(type: "职位", text: draftBinding(\.jobTitle))
                    }
                    ReviewFieldSection(title: "网站", showsAdd: true, addAction: addWebsite) {
                        fieldRow(type: "网站", text: draftBinding(\.website))
                    }
                    ReviewFieldSection(title: "地址", showsAdd: true, addAction: addAddress) {
                        fieldRow(type: "工作地址", text: draftBinding(\.address))
                    }
                    ReviewFieldSection(title: "备注", showsAdd: false) {
                        fieldRow(type: "备注", text: draftBinding(\.notes))
                    }
                    if !importSession.draft.ocrRawText.isEmpty {
                        rawTextSection
                    }
                }
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(AppColors.pageBackground)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .screenIdentifier("screen.review")
    }

    private var reviewHeader: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(width: 44, height: 44)
            }
            .accessibilityIdentifier("core.review.back")

            Text("核对名片信息")
                .font(.title3.weight(.semibold))
            Spacer()
            Button("保存") {
                navigation.captureState = .saving
                navigation.push(.saveResult)
            }
            .font(.headline)
            .foregroundStyle(AppColors.primary)
            .accessibilityIdentifier("core.review.save")
        }
        .padding(.horizontal, 8)
        .frame(height: 56)
        .background(.white)
    }

    private var cardPreview: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let image = importSession.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .accessibilityLabel("已选择的名片图片")
                } else {
                    DemoBusinessCardImage()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            Button {
                navigation.showPlaceholder(
                    id: "review.crop",
                    title: "裁剪与校正",
                    message: "透视校正和旋转裁剪将在后续扩展中开放。",
                    source: "核对信息",
                    symbol: "crop.rotate"
                )
            } label: {
                Image(systemName: "crop.rotate")
                    .font(.title3)
                    .foregroundStyle(AppColors.primary)
                    .frame(width: 46, height: 46)
                    .background(.thinMaterial, in: Circle())
            }
            .padding(10)
            .accessibilityIdentifier("placeholder.review.crop")
        }
        .padding(.horizontal, AppSize.pageInset)
        .padding(.top, 12)
    }

    private var manualEntryBanner: some View {
        Label {
            Text("图片中未识别到文字，当前为手动填写模式。")
                .font(.subheadline)
        } icon: {
            Image(systemName: "pencil.and.list.clipboard")
        }
        .foregroundStyle(AppColors.textPrimary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, AppSize.pageInset)
        .accessibilityIdentifier("core.review.manualEntry")
    }

    private var recognitionSettings: some View {
        Toggle(isOn: $usesPrecision) {
            VStack(alignment: .leading, spacing: 5) {
                Text("高精准识别")
                    .font(.headline)
                Text("保存并提交高精准识别")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .tint(AppColors.primary)
        .padding(16)
        .background(.white)
        .onChange(of: usesPrecision) { _, enabled in
            if enabled {
                navigation.showPlaceholder(
                    id: "review.precision",
                    title: "高精准识别",
                    message: "演示版本仅保留设置状态，不会上传名片或伪造远程识别结果。",
                    source: "核对信息",
                    symbol: "viewfinder.circle.fill"
                )
            }
        }
        .accessibilityIdentifier("placeholder.review.precision")
    }

    private var languageRow: some View {
        Button {
            navigation.showPlaceholder(
                id: "review.language",
                title: "更换识别语言",
                message: "当前本地 OCR 已同时启用简体中文和英文；其他语言将在后续扩展。",
                source: "核对信息",
                symbol: "character.book.closed.fill"
            )
        } label: {
            HStack {
                Text("识别语言")
                    .foregroundStyle(AppColors.textPrimary)
                Text("简体中文，英文")
                    .foregroundStyle(AppColors.textSecondary)
                Spacer()
                Text("更换语言")
                    .foregroundStyle(AppColors.primary)
            }
            .font(.subheadline)
            .padding(16)
            .background(.white)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("placeholder.review.language")
    }

    private var rawTextSection: some View {
        DisclosureGroup {
            Text(importSession.draft.ocrRawText)
                .font(.footnote.monospaced())
                .foregroundStyle(AppColors.textSecondary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 10)
        } label: {
            Label("OCR 原始文本", systemImage: "doc.text.magnifyingglass")
                .font(.headline)
                .foregroundStyle(AppColors.textPrimary)
        }
        .padding(16)
        .background(.white)
        .accessibilityIdentifier("core.review.rawText")
    }

    private func fieldRow(type: String, text: Binding<String>) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Menu {
                Text("当前类型：\(type)")
                Button("其他") {
                    navigation.showPlaceholder(
                        id: "review.fieldType.\(type)",
                        title: "字段类型",
                        source: "核对信息",
                        symbol: "list.bullet"
                    )
                }
            } label: {
                HStack(spacing: 4) {
                    Text(type)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .foregroundStyle(AppColors.textPrimary)
                .frame(width: 98, alignment: .leading)
            }

            TextField("点击填写", text: text)
                .textInputAutocapitalization(.never)

            Button {
                text.wrappedValue = ""
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(.secondary)
                    .frame(width: 30, height: 30)
            }
            .accessibilityLabel("清空\(type)")
        }
        .font(.body)
        .padding(.vertical, 8)
    }

    private func showAddPlaceholder(_ type: String, symbol: String) {
        navigation.showPlaceholder(
            id: "review.add.\(type)",
            title: "添加\(type)",
            message: "当前草稿支持一个主要值；多电话和多邮箱将在后续扩展。",
            source: "核对信息",
            symbol: symbol
        )
    }

    private func addPhone() { showAddPlaceholder("电话", symbol: "phone.badge.plus") }
    private func addEmail() { showAddPlaceholder("邮箱", symbol: "envelope.badge") }
    private func addCompany() { showAddPlaceholder("公司", symbol: "building.2") }
    private func addWebsite() { showAddPlaceholder("网站", symbol: "globe") }
    private func addAddress() { showAddPlaceholder("地址", symbol: "mappin.and.ellipse") }

    private func draftBinding(_ keyPath: WritableKeyPath<BusinessCardDraft, String>) -> Binding<String> {
        Binding(
            get: { importSession.draft[keyPath: keyPath] },
            set: { importSession.draft[keyPath: keyPath] = $0 }
        )
    }
}

private struct ReviewFieldSection<Content: View>: View {
    let title: String
    let showsAdd: Bool
    let addAction: () -> Void
    @ViewBuilder let content: Content

    init(
        title: String,
        showsAdd: Bool,
        addAction: @escaping () -> Void = {},
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.showsAdd = showsAdd
        self.addAction = addAction
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppColors.primary)
                Spacer()
                if showsAdd {
                    Button(action: addAction) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(AppColors.primary)
                    }
                    .accessibilityLabel("添加\(title)")
                    .accessibilityIdentifier("placeholder.review.add.\(title)")
                }
            }
            content
        }
        .padding(16)
        .background(.white)
    }
}

#Preview {
    NavigationStack {
        CardReviewView()
    }
    .environment(AppNavigationModel(initialStage: .main))
    .environment(CardImportSession())
}
