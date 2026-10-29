import SwiftUI

struct LaunchView: View {
    let onFinished: () -> Void
    @State private var didScheduleTransition = false

    private let symbols = [
        "person.2", "envelope", "phone", "building.2", "star",
        "clock", "person.crop.circle", "location", "briefcase", "paperplane"
    ]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.white.ignoresSafeArea()

                ForEach(0..<20, id: \.self) { index in
                    Image(systemName: symbols[index % symbols.count])
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(AppColors.primary.opacity(0.055))
                        .rotationEffect(.degrees(Double((index * 19) % 42) - 21))
                        .position(
                            x: CGFloat((index * 83) % 360) + 24,
                            y: CGFloat((index * 91) % 500) + 42
                        )
                }

                VStack {
                    Spacer()

                    HStack(spacing: 14) {
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.cyan, AppColors.primaryStrong],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 66, height: 66)
                            .overlay {
                                Image(systemName: "rectangle.stack.person.crop.fill")
                                    .font(.system(size: 31, weight: .bold))
                                    .foregroundStyle(.white)
                            }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Cardly")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                            Text("智能名片匣")
                                .font(.headline)
                        }
                        .foregroundStyle(AppColors.primary)
                    }
                    .offset(y: -proxy.size.height * 0.06)

                    Spacer()

                    VStack(spacing: 5) {
                        Text("课程演示项目")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppColors.textPrimary)
                        Text("本地智能名片体验")
                            .font(.caption)
                            .foregroundStyle(AppColors.textSecondary)
                        Text("离线演示 · 保护名片隐私")
                            .font(.caption2)
                            .foregroundStyle(AppColors.primary)
                            .padding(.top, 8)
                    }
                    .padding(.bottom, 28)
                }
            }
        }
        .screenIdentifier("screen.launch")
        .onAppear {
            guard !didScheduleTransition else { return }
            didScheduleTransition = true
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1.35))
                onFinished()
            }
        }
    }
}

#Preview {
    LaunchView(onFinished: {})
}
