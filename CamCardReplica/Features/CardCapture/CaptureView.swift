import PhotosUI
import SwiftUI
import UIKit

struct CaptureView: View {
    @Environment(AppNavigationModel.self) private var navigation
    @Environment(CardImportSession.self) private var importSession
    @Environment(\.dismiss) private var dismiss
    @State private var precisionMode = 0
    @State private var captureMode = 2
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var activeAlert: CaptureAlert?
    @State private var didPrepareImport = false
    @State private var camera = CameraCaptureController()

    private var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("-UITesting")
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.36, green: 0.40, blue: 0.39), Color(red: 0.18, green: 0.22, blue: 0.24)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            cameraTexture

#if !targetEnvironment(simulator)
            if camera.status == .ready || camera.status == .capturing {
                CameraPreview(session: camera.session)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
#endif

            VStack(spacing: 18) {
                captureHeader
                    .padding(.top, 8)
                viewfinder
                captureModes
                captureControls
                    .padding(.bottom, 12)
            }
            .padding(.horizontal, 22)

            if importSession.state == .loadingImage ||
                importSession.state == .detectingEdges ||
                importSession.state == .recognizing ||
                camera.status == .capturing {
                recognitionProgress
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .screenIdentifier("screen.capture")
        .onAppear {
            guard !didPrepareImport else { return }
            didPrepareImport = true
            importSession.beginNewImport()
            navigation.captureState = .idle
        }
        .onChange(of: selectedPhoto) { _, item in
            guard let item else { return }
            Task { await importPhoto(item) }
        }
        .task {
            guard !isUITesting else { return }
            await camera.start()
        }
        .onDisappear {
            camera.stop()
        }
        .alert(item: $activeAlert) { alert in
            switch alert {
            case .noText:
                Alert(
                    title: Text("未识别到文字"),
                    message: Text("可以重新选择更清晰的名片图片，或保留当前图片并手动填写。"),
                    primaryButton: .default(Text("手动填写")) {
                        importSession.continueWithManualEntry()
                        navigation.captureState = .reviewing
                        navigation.push(.review)
                    },
                    secondaryButton: .cancel(Text("重新选择")) {
                        selectedPhoto = nil
                        navigation.captureState = .selectingImage
                    }
                )
            case let .failure(message):
                Alert(
                    title: Text("无法识别图片"),
                    message: Text(message),
                    dismissButton: .default(Text("重新选择")) {
                        selectedPhoto = nil
                        navigation.captureState = .selectingImage
                    }
                )
            case .cameraPermission:
                Alert(
                    title: Text("需要相机权限"),
                    message: Text("请在系统设置中允许 Cardly 使用相机；图片仅在设备本地检测、校正和识别。"),
                    primaryButton: .default(Text("打开设置")) {
                        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                        UIApplication.shared.open(url)
                    },
                    secondaryButton: .cancel(Text("取消"))
                )
            case .cameraUnavailable:
                Alert(
                    title: Text("相机不可用"),
                    message: Text("iOS 模拟器不能访问实体相机，请使用左侧相册入口；真机上会显示实时取景并可直接拍摄。"),
                    dismissButton: .default(Text("知道了"))
                )
            }
        }
    }

    private var cameraTexture: some View {
        GeometryReader { proxy in
            ForEach(0..<16, id: \.self) { index in
                Capsule()
                    .fill(.white.opacity(0.018))
                    .frame(width: proxy.size.width * 0.9, height: 28)
                    .rotationEffect(.degrees(index.isMultiple(of: 2) ? 22 : -18))
                    .position(
                        x: proxy.size.width * CGFloat((index % 3) + 1) / 4,
                        y: CGFloat(index) * 61 + 20
                    )
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private var captureHeader: some View {
        HStack(spacing: 14) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.title2.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
            }
            .accessibilityIdentifier("core.capture.close")

            HStack(spacing: 0) {
                precisionButton("基础识别", index: 0)
                precisionButton("高精准识别", index: 1)
            }
            .padding(4)
            .background(.black.opacity(0.45), in: Capsule())

            Button {
                navigation.showPlaceholder(
                    id: "capture.more",
                    title: "拍摄更多设置",
                    source: "拍摄",
                    symbol: "ellipsis"
                )
            } label: {
                Image(systemName: "ellipsis")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
            }
            .accessibilityIdentifier("placeholder.capture.more")
        }
    }

    private func precisionButton(_ title: String, index: Int) -> some View {
        Button {
            precisionMode = index
            if index == 1 {
                navigation.showPlaceholder(
                    id: "capture.precision",
                    title: "高精准识别",
                    message: "入口和选择状态已保留；云端高精准识别不会在离线演示中伪装执行。",
                    source: "拍摄",
                    symbol: "viewfinder.circle.fill"
                )
            }
        } label: {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(precisionMode == index ? AppColors.textPrimary : .white.opacity(0.7))
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(precisionMode == index ? Color.white : Color.clear, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(index == 0 ? "core.capture.basic" : "placeholder.capture.precision")
    }

    private var viewfinder: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 2)
                .stroke(.white.opacity(0.9), lineWidth: 1.2)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Text(cameraGuidance)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 13)
                .padding(.vertical, 8)
                .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 8))
                .padding(.top, 26)
        }
        .frame(minHeight: 390)
        .accessibilityLabel("名片取景框，正在寻找名片边框")
    }

    private var captureModes: some View {
        HStack(spacing: 26) {
            modeButton("连续拍摄", index: 0)
            modeButton("多张拍摄", index: 1)
            modeButton("单张拍摄", index: 2)
        }
        .frame(maxWidth: .infinity)
    }

    private func modeButton(_ title: String, index: Int) -> some View {
        Button {
            captureMode = index
            if index != 2 {
                navigation.showPlaceholder(
                    id: "capture.mode.\(index)",
                    title: title,
                    message: "该拍摄模式保留完整入口与选中状态，批量处理将在后续版本开放。",
                    source: "拍摄",
                    symbol: "camera.on.rectangle"
                )
            }
        } label: {
            Text(title)
                .font(.subheadline.weight(captureMode == index ? .semibold : .regular))
                .foregroundStyle(captureMode == index ? .white : .white.opacity(0.62))
        }
        .accessibilityIdentifier(index == 2 ? "core.capture.single" : "placeholder.capture.mode.\(index)")
    }

    private var captureControls: some View {
        HStack {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                VStack(spacing: 7) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.title2)
                    Text("相册")
                        .font(.caption)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("从相册选择名片")
            .accessibilityIdentifier("core.capture.album")

            if isUITesting {
                Button(action: openFixtureForUITest) {
                    shutterLabel
                }
                .accessibilityLabel("载入合成测试名片")
                .accessibilityIdentifier("core.capture.shutter")
            } else {
#if targetEnvironment(simulator)
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    shutterLabel
                }
                .buttonStyle(.plain)
                .accessibilityLabel("模拟器从相册选择名片图片")
                .accessibilityIdentifier("core.capture.shutter")
#else
                Button {
                    Task { await capturePhoto() }
                } label: {
                    shutterLabel
                }
                .buttonStyle(.plain)
                .accessibilityLabel("拍摄名片")
                .accessibilityIdentifier("core.capture.shutter")
#endif
            }

            Button {
                navigation.showPlaceholder(
                    id: "capture.stack",
                    title: "待处理名片",
                    source: "拍摄",
                    symbol: "rectangle.stack.badge.plus"
                )
            } label: {
                VStack(spacing: 7) {
                    Image(systemName: "rectangle.stack.badge.plus")
                        .font(.title2)
                    Text("7")
                        .font(.caption)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
            }
            .accessibilityIdentifier("placeholder.capture.stack")
        }
    }

    private var shutterLabel: some View {
        Circle()
            .fill(AppColors.primary)
            .frame(width: 76, height: 76)
            .overlay {
                Circle().stroke(.white.opacity(0.72), lineWidth: 10)
            }
            .shadow(color: .black.opacity(0.2), radius: 8)
    }

    private var recognitionProgress: some View {
        VStack(spacing: 14) {
            ProgressView()
                .tint(.white)
                .scaleEffect(1.2)
            Text(progressTitle)
                .font(.headline)
                .foregroundStyle(.white)
            Text("图片仅在设备上处理")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.72))
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 24)
        .background(.black.opacity(0.78), in: RoundedRectangle(cornerRadius: 16))
        .accessibilityIdentifier("core.capture.recognizing")
    }

    private var cameraGuidance: String {
        switch camera.status {
        case .ready, .capturing:
            "将名片完整放入框内"
        case .denied:
            "相机权限未开启，请使用相册"
        case .unavailable:
            "模拟器请使用相册导入"
        case .failed:
            "相机启动失败，请使用相册"
        default:
            "正在准备相机"
        }
    }

    private var progressTitle: String {
        if camera.status == .capturing { return "正在拍摄名片…" }
        switch importSession.state {
        case .loadingImage:
            return "正在读取图片…"
        case .detectingEdges:
            return "正在检测边缘并校正透视…"
        case .recognizing:
            return "正在本地识别名片…"
        default:
            return "正在处理图片…"
        }
    }

    private func openFixtureForUITest() {
        importSession.loadFixture()
        navigation.captureState = .reviewing
        navigation.push(.review)
    }

    private func importPhoto(_ item: PhotosPickerItem) async {
        navigation.captureState = .previewing
        let outcome = await importSession.importPhoto(item)
        selectedPhoto = nil
        handleImportOutcome(outcome)
    }

    private func capturePhoto() async {
        if camera.status == .idle {
            await camera.start()
        }

        switch camera.status {
        case .denied:
            activeAlert = .cameraPermission
            return
        case .unavailable:
            activeAlert = .cameraUnavailable
            return
        case let .failed(message):
            activeAlert = .failure(message)
            return
        case .idle, .requestingPermission, .configuring:
            return
        case .capturing:
            return
        case .ready:
            break
        }

        do {
            let data = try await camera.capturePhoto()
            navigation.captureState = .previewing
            handleImportOutcome(await importSession.importImageData(data))
        } catch {
            activeAlert = .failure(error.localizedDescription)
        }
    }

    private func handleImportOutcome(_ outcome: CardImportOutcome) {
        switch outcome {
        case .cancelled:
            navigation.captureState = .idle
        case .ready:
            navigation.captureState = .reviewing
            navigation.push(.review)
        case .noText:
            navigation.captureState = .failed(message: "未识别到文字")
            activeAlert = .noText
        case let .failed(message):
            navigation.captureState = .failed(message: message)
            activeAlert = .failure(message)
        }
    }
}

private enum CaptureAlert: Identifiable {
    case noText
    case failure(String)
    case cameraPermission
    case cameraUnavailable

    var id: String {
        switch self {
        case .noText: "noText"
        case let .failure(message): "failure-\(message)"
        case .cameraPermission: "cameraPermission"
        case .cameraUnavailable: "cameraUnavailable"
        }
    }
}

#Preview {
    NavigationStack {
        CaptureView()
    }
    .environment(AppNavigationModel(initialStage: .main))
    .environment(CardImportSession())
}
