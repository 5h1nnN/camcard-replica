@preconcurrency import AVFoundation
import Observation
import SwiftUI
import UIKit

enum CameraCaptureStatus: Equatable {
    case idle
    case requestingPermission
    case configuring
    case ready
    case capturing
    case denied
    case unavailable
    case failed(message: String)
}

enum CameraCaptureError: LocalizedError {
    case unavailable
    case notReady
    case captureFailed
    case invalidPhotoData

    var errorDescription: String? {
        switch self {
        case .unavailable:
            "此设备没有可用的后置相机。"
        case .notReady:
            "相机尚未准备好，请稍后重试。"
        case .captureFailed:
            "拍摄失败，请保持设备稳定后重试。"
        case .invalidPhotoData:
            "无法读取拍摄的照片，请重新拍摄。"
        }
    }
}

@MainActor
@Observable
final class CameraCaptureController: NSObject {
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var isConfigured = false
    private var continuation: CheckedContinuation<Data, Error>?

    private(set) var status: CameraCaptureStatus = .idle

    func start() async {
#if targetEnvironment(simulator)
        status = .unavailable
#else
        guard status != .ready,
              status != .capturing,
              status != .requestingPermission,
              status != .configuring else { return }

        let authorization = AVCaptureDevice.authorizationStatus(for: .video)
        if authorization == .notDetermined {
            status = .requestingPermission
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            guard granted else {
                status = .denied
                return
            }
        } else if authorization != .authorized {
            status = .denied
            return
        }

        do {
            status = .configuring
            try configureIfNeeded()
            let session = session
            await Task.detached(priority: .userInitiated) {
                if !session.isRunning {
                    session.startRunning()
                }
            }.value
            status = .ready
        } catch {
            status = .failed(message: error.localizedDescription)
        }
#endif
    }

    func stop() {
        guard session.isRunning else { return }
        let session = session
        Task.detached(priority: .utility) {
            session.stopRunning()
        }
    }

    func capturePhoto() async throws -> Data {
        guard status == .ready else { throw CameraCaptureError.notReady }
        guard continuation == nil else { throw CameraCaptureError.captureFailed }

        status = .capturing
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let settings = AVCapturePhotoSettings()
            if photoOutput.supportedFlashModes.contains(.auto) {
                settings.flashMode = .auto
            }
            if let connection = photoOutput.connection(with: .video),
               connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
            }
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    private func configureIfNeeded() throws {
        guard !isConfigured else { return }
        guard let camera = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back
        ) else {
            throw CameraCaptureError.unavailable
        }

        let input = try AVCaptureDeviceInput(device: camera)
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        session.sessionPreset = .photo

        guard session.canAddInput(input), session.canAddOutput(photoOutput) else {
            throw CameraCaptureError.unavailable
        }
        session.addInput(input)
        session.addOutput(photoOutput)
        photoOutput.maxPhotoQualityPrioritization = .quality
        isConfigured = true
    }

    private func finishCapture(with result: Result<Data, Error>) {
        let continuation = continuation
        self.continuation = nil
        status = session.isRunning ? .ready : .idle
        continuation?.resume(with: result)
    }
}

extension CameraCaptureController: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        let result: Result<Data, Error>
        if let error {
            result = .failure(error)
        } else if let data = photo.fileDataRepresentation(), UIImage(data: data) != nil {
            result = .success(data)
        } else {
            result = .failure(CameraCaptureError.invalidPhotoData)
        }

        Task { @MainActor [weak self] in
            self?.finishCapture(with: result)
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: CameraPreviewView, context: Context) {
        uiView.previewLayer.session = session
    }
}

final class CameraPreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}
