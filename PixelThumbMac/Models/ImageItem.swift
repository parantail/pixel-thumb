import SwiftUI
import AppKit

@Observable
final class ImageItem: Identifiable {
    let id = UUID()
    let url: URL
    let fileName: String
    let fileSize: Int64

    private(set) var thumbnail: NSImage?
    private(set) var width: Int = 0
    private(set) var height: Int = 0
    private(set) var isLoaded: Bool = false
    private var isLoading: Bool = false

    var resolution: String {
        guard width > 0 && height > 0 else { return "Unknown" }
        return "\(width) × \(height)"
    }

    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }

    init(url: URL) {
        self.url = url
        self.fileName = url.lastPathComponent

        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
           let size = attrs[.size] as? Int64 {
            self.fileSize = size
        } else {
            self.fileSize = 0
        }
    }

    @MainActor
    func loadThumbnail(maxSize: CGFloat = 512) async {
        guard !isLoaded && !isLoading else { return }
        isLoading = true

        let result = await Task.detached(priority: .utility) { [url] in
            guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
                return (nil as NSImage?, 0, 0)
            }

            let options: [CFString: Any] = [
                kCGImageSourceThumbnailMaxPixelSize: maxSize,
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceShouldCacheImmediately: true
            ]

            guard let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
                return (nil as NSImage?, 0, 0)
            }

            var imageWidth = 0
            var imageHeight = 0

            if let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any] {
                imageWidth = properties[kCGImagePropertyPixelWidth] as? Int ?? cgImage.width
                imageHeight = properties[kCGImagePropertyPixelHeight] as? Int ?? cgImage.height
            } else {
                imageWidth = cgImage.width
                imageHeight = cgImage.height
            }

            let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
            return (nsImage, imageWidth, imageHeight)
        }.value

        self.thumbnail = result.0
        self.width = result.1
        self.height = result.2
        self.isLoaded = true
        self.isLoading = false
    }
}
