import Foundation

/// Pass generation decisions that depend only on the pass's own data: which
/// pass style it is and which images belong in its package. GeneratePass.swift
/// uses these to write the package; keeping them on the model means the
/// decisions live with the data they are derived from.
extension PassObject {
    /// Whether a background image can be shown for this pass's barcode type
    var isBackgroundImageSupported: Bool {
        if (barcodeType == BarcodeType.code128) || (barcodeType == BarcodeType.pdf417) || (barcodeType == BarcodeType.qr) || (barcodeType == BarcodeType.none) {
            return true
        } else {
            return false
        }
    }

    /// Whether the background image belongs in the generated package
    var shouldIncludeBackgroundImage: Bool {
        if (isBackgroundImageOn == true && backgroundImage != Data()) && isBackgroundImageSupported {
            return true
        } else {
            return false
        }
    }

    /// Whether a strip image can be shown for this pass's barcode type
    var isStripImageSupported: Bool {
        if barcodeType.doesBarcodeUseStripImage() && (barcodeType.isEnteredBarcodeValueValid(string: barcodeString) || isCustomStripImageOn) {
            return true
        } else {
            return false
        }
    }

    /// Whether a strip image applies to this pass, before the background
    /// image is taken into account
    var shouldAddStripImage: Bool {
        guard stripImage != Data() else { return false }
        return isCustomStripImageOn || isStripImageSupported
    }

    /// Whether the strip image belongs in the generated package. A
    /// background image wins over a strip image: the two cannot coexist on
    /// a pass, and the strip is the one dropped.
    var shouldIncludeStripImage: Bool {
        shouldAddStripImage && !shouldIncludeBackgroundImage
    }

    /// The pass style key for pass.json, chosen from the images the package
    /// will actually contain, so the style never claims an image that is
    /// not included
    var passStyleKey: String {
        if shouldIncludeBackgroundImage {
            return "eventTicket"
        } else if isCoupon { // Coupon passes can have strip images, that toggle is the next-highest priority
            return "coupon"
        } else if shouldIncludeStripImage { // non-coupon passes with strip images
            return "storeCard"
        } else {
            // Default to generic
            return "generic"
        }
    }
}
