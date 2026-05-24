#if canImport(UIKit)
import SwiftUI
import AVFoundation

/// Camera-based QR code scanner that calls `onResult` when a valid
/// `aeropoint://pair?…` URL is detected.
public struct QRCodeScannerView: UIViewControllerRepresentable {
    public var onResult: (PairingPayload) -> Void

    public init(onResult: @escaping (PairingPayload) -> Void) {
        self.onResult = onResult
    }

    public func makeUIViewController(context: Context) -> ScannerViewController {
        let vc = ScannerViewController()
        vc.onResult = onResult
        return vc
    }

    public func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
}

public final class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onResult: ((PairingPayload) -> Void)?

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupSession()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession?.stopRunning()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    private func setupSession() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            startCameraSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.startCameraSession()
                    } else {
                        self?.showPermissionDenied()
                    }
                }
            }
        case .denied:
            showPermissionDenied()
        case .restricted:
            showPermissionRestricted()
        @unknown default:
            showPermissionDenied()
        }
    }

    private func startCameraSession() {
        guard captureSession == nil else { return }

        let session = AVCaptureSession()
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return }

        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.addSublayer(preview)
        previewLayer = preview

        captureSession = session
        DispatchQueue.global(qos: .userInitiated).async { session.startRunning() }
    }

    private func showPermissionRestricted() {
        let label = UILabel()
        label.text = "Camera access is restricted on this device."
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }

    public func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput objects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let object = objects.first as? AVMetadataMachineReadableCodeObject,
              let string = object.stringValue,
              let payload = PairingPayload(urlString: string) else { return }

        captureSession?.stopRunning()
        onResult?(payload)
    }

    private func showPermissionDenied() {
        let label = UILabel()
        label.text = "Camera access required.\nEnable in Settings → Privacy → Camera."
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }
}
#endif
