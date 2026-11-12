import CoreImage
import UIKit

// Shared cache for the CoreImage barcode generators (QR, Code128, PDF417).
//
// The barcode views used to call their Generate... function inline in body,
// inside a GeometryReader, and each call built a fresh CIContext and rendered
// a fresh CGImage. In a scrolling list that meant every card entering the
// viewport re-rendered its barcode from scratch on the main thread.
//
// Now the views take an explicit target width instead of measuring one, and
// the Generate... functions go through here: one shared CIContext, and one
// cached UIImage per (barcode type, payload, settings, pixel size). A cache
// hit is just an NSCache lookup, so repeated body evaluations while scrolling
// cost almost nothing. NSCache evicts under memory pressure, so a miss just
// regenerates.
enum BarcodeImageCache {
    static let context = CIContext()
    static let cache = NSCache<NSString, UIImage>()

    static func cachedImage(forKey key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    static func store(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
}
