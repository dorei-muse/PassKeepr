import AppIntents
import Foundation
import Vision

struct CreatePassIntent: AppIntent {
    static var title: LocalizedStringResource = "Create Pass"
    static var description = IntentDescription(
        "Creates a new PassKeepr pass from a title and barcode. Provide the barcode as text, or as an image containing a barcode."
    )

    @Parameter(
        title: "Title",
        requestDescription: "A short name identifying what this pass is for, e.g. 'Amazon Return'"
    )
    var title: String

    @Parameter(
        title: "Barcode",
        requestDescription: "The barcode value to encode, e.g. a loyalty card number. Not needed if an image is provided."
    )
    var barcodeData: String?

    @Parameter(
        title: "Image",
        requestDescription: "A photo or screenshot containing a barcode. The barcode is detected automatically."
    )
    var image: IntentFile?

    func perform() async throws -> some IntentResult & ReturnsValue<PassEntity> {
        let payload: String
        var barcodeType: BarcodeType = .qr

        if let image {
            guard let detected = try await detectBarcode(in: image) else {
                throw IntentError.noBarcodeFound
            }
            payload = detected.payload
            barcodeType = detected.symbology.toBarcodeType() ?? .qr
        } else if let barcodeData, !barcodeData.isEmpty {
            payload = barcodeData
        } else {
            throw IntentError.missingBarcode
        }

        var pass = PassObject()
        pass.description = title
        pass.barcodeString = payload
        pass.barcodeType = barcodeType

        let modelData = await MainActor.run {
            await ModelData.loadShared()
        }
        await MainActor.run {
            modelData.passObjects.append(pass)
            modelData.save()
        }

        let entity = PassEntity(
            id: pass.id,
            title: pass.description,
            barcodeType: pass.barcodeType.description
        )
        return .result(value: entity)
    }

    private func detectBarcode(in file: IntentFile) async throws -> (payload: String, symbology: VNBarcodeSymbology)? {
        let data = try Data(contentsOf: file.fileURL)
        guard let ciImage = CIImage(data: data) else { return nil }

        let request = VNDetectBarcodesRequest()
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        try handler.perform([request])

        guard let barcode = request.results?.first,
              let payload = barcode.payloadStringValue
        else { return nil }

        return (payload, barcode.symbology)
    }
}

enum IntentError: Error, CustomLocalizedStringResourceConvertible {
    case noBarcodeFound
    case missingBarcode

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .noBarcodeFound:
            "No barcode was found in the provided image."
        case .missingBarcode:
            "Provide a barcode value or an image containing a barcode."
        }
    }
}
