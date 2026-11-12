import CoreImage.CIFilterBuiltins
import SwiftUI

struct Code128View: View {
    var data: String
    // Width, in points, the code will be displayed at. The list passes its
    // exact width; other callers use the default, a high-res image SwiftUI
    // scales down. No GeometryReader: measuring the width here meant a layout
    // pass plus a barcode render per card while scrolling.
    var targetWidth: CGFloat = 1000
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        if let code128BarcodeImage = GenerateCode128Barcode(string: data, viewWidth: targetWidth, displayScale: displayScale) {
            Image(uiImage: code128BarcodeImage)
                .resizable()
                .scaledToFit()
                // Fill the width the parent offers; targetWidth only sets the
                // generated image's resolution, not its layout size, so the
                // default high-res image is safe in callers that don't know
                // their exact width (edit/picker previews).
                .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    Code128View(data: "Hello, Swift Barcode!")
}

func GenerateCode128Barcode(string: String, viewWidth: CGFloat, displayScale: CGFloat) -> UIImage? {
    let pixelWidth = max(1, Int((viewWidth * displayScale).rounded()))
    let cacheKey = "code128|\(string)|\(pixelWidth)"
    if let cached = BarcodeImageCache.cachedImage(forKey: cacheKey) {
        return cached
    }

    let filter = CIFilter.code128BarcodeGenerator()

    filter.quietSpace = 4
    filter.message = string.data(using: String.Encoding.ascii)!

    guard let outputImage = filter.outputImage else { return nil }

    let scale = CGFloat(pixelWidth) / outputImage.extent.size.width
    let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

    // Convert the CIImage to a UIImage, using the shared context (creating a
    // CIContext per render was a large part of the per-card cost).
    if let cgImage = BarcodeImageCache.context.createCGImage(scaledImage, from: scaledImage.extent) {
        let code128Image = UIImage(cgImage: cgImage, scale: displayScale, orientation: .up)
        BarcodeImageCache.store(code128Image, forKey: cacheKey)
        return code128Image
    }

    return nil
}
