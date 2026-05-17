import SwiftUI
import CoreImage.CIFilterBuiltins

struct PairingQRCodeView: View {
    let payload: String

    var body: some View {
        VStack(spacing: 8) {
            if let image = generateQRCode(from: payload) {
                Image(nsImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)
                    .cornerRadius(6)
            } else {
                Color.secondary
                    .frame(width: 140, height: 140)
                    .cornerRadius(6)
            }

            Text("Scan with iPhone to pair")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func generateQRCode(from string: String) -> NSImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        guard let ciImage = filter.outputImage else { return nil }
        let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return NSImage(cgImage: cgImage, size: NSSize(width: scaled.extent.width, height: scaled.extent.height))
    }
}
