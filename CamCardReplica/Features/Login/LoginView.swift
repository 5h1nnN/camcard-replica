import SwiftUI

struct LoginView: View {
    @Environment(AppNavigationModel.self) private var navigation
    @State private var hasAgreed = false
    @State private var showsAgreementAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                navigation.showPlaceholder(
                    id: "login.back",
                    title: "返回",
                    message: "这是本地演示的首个登录页面，没有更早的账号页面。",
                    source: "login",
                    symbol: "arrow.left"
                )
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(width: 44, height: 44)
            }
            .accessibilityIdentifier("placeholder.login.back")

            Spacer(minLength: 70)

            VStack(spacing: 9) {
                Text("191****6020")
                    .font(.system(size: 40, weight: .light, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)
                Text("本地演示账号提供认证外观")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity)

            Button {
                if hasAgreed {
                    navigation.enterMainApp()
                } else {
                    showsAgreementAlert = true
                }
            } label: {
                Text("一键登录")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        LinearGradient(
                            colors: [Color.cyan, AppColors.primaryStrong],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: Capsule()
                    )
            }
            .padding(.top, 64)
            .accessibilityIdentifier("core.login.submit")

            HStack(alignment: .top, spacing: 10) {
                Button {
                    hasAgreed.toggle()
                } label: {
                    Image(systemName: hasAgreed ? "checkmark.square.fill" : "square")
                        .font(.title3)
                        .foregroundStyle(hasAgreed ? AppColors.primary : Color.secondary)
                }
                .accessibilityLabel("同意用户协议")
                .accessibilityValue(hasAgreed ? "已同意" : "未同意")
                .accessibilityIdentifier("core.login.agreement")

                agreementText
            }
            .padding(.horizontal, 14)
            .padding(.top, 34)

            Spacer()

            Button {
                navigation.showPlaceholder(
                    id: "login.otherMethods",
                    title: "其他方式登录",
                    message: "演示版本不连接真实账号、短信或第三方认证服务。",
                    source: "login",
                    symbol: "person.badge.key.fill"
                )
            } label: {
                Text("其他方式登录")
                    .font(.headline)
                    .foregroundStyle(AppColors.primary)
                    .frame(maxWidth: .infinity)
            }
            .accessibilityIdentifier("placeholder.login.otherMethods")
            .padding(.bottom, 36)
        }
        .padding(.horizontal, 24)
        .background(Color.white.ignoresSafeArea())
        .screenIdentifier("screen.login")
        .alert("请先同意协议", isPresented: $showsAgreementAlert) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text("勾选用户协议后即可进入本地演示，不会发起真实认证。")
        }
    }

    private var agreementText: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("我已阅读并同意以下协议，并使用本机号码登录")
                .font(.caption)
                .foregroundStyle(AppColors.textSecondary)
            HStack(spacing: 8) {
                agreementButton("隐私协议", id: "privacy")
                agreementButton("用户协议", id: "user")
                agreementButton("账号服务协议", id: "account")
            }
            .font(.caption2)
        }
    }

    private func agreementButton(_ title: String, id: String) -> some View {
        Button(title) {
            navigation.showPlaceholder(
                id: "login.agreement.\(id)",
                title: title,
                message: "演示版本未连接远程协议页面。正式产品应在此展示完整条款。",
                source: "login",
                symbol: "doc.text.fill"
            )
        }
        .buttonStyle(.plain)
        .foregroundStyle(AppColors.primary)
        .accessibilityIdentifier("placeholder.login.agreement.\(id)")
    }
}

#Preview {
    LoginView()
        .environment(AppNavigationModel(initialStage: .login))
}
