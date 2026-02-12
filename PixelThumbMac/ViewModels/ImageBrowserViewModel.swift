import SwiftUI
import AppKit

@Observable
@MainActor
final class ImageBrowserViewModel {
    private(set) var images: [ImageItem] = []
    var thumbnailSize: CGFloat = 128
    var fitSmallImages: Bool = true
    var fitLargeImages: Bool = true
    var pixelScale: CGFloat = 4

    private(set) var isLoading: Bool = false
    private(set) var statusMessage: String = "No folder selected"
    private(set) var currentFolderPath: String?

    private var loadingTask: Task<Void, Never>?

    private static let supportedExtensions: Set<String> = [
        "png", "jpg", "jpeg", "bmp", "gif", "ico", "tiff", "tif"
    ]

    func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.message = "Select folder(s) containing images"
        panel.prompt = "Open"

        if panel.runModal() == .OK, !panel.urls.isEmpty {
            loadImages(from: panel.urls)
        }
    }

    func loadImages(from folderURLs: [URL]) {
        loadingTask?.cancel()
        images.removeAll()
        currentFolderPath = folderURLs.count == 1
            ? folderURLs[0].path
            : folderURLs.map { $0.lastPathComponent }.joined(separator: "; ")
        isLoading = true
        statusMessage = "Scanning folder..."

        loadingTask = Task {
            var allImageURLs: [URL] = []
            for folderURL in folderURLs {
                let urls = await scanForImages(in: folderURL)
                allImageURLs.append(contentsOf: urls)
            }

            if Task.isCancelled { return }

            let items = allImageURLs.map { ImageItem(url: $0) }
            self.images = items
            self.statusMessage = "\(items.count) images found"
            self.isLoading = false

            await loadThumbnailsInBatches(items: items, batchSize: 50)
        }
    }

    private func scanForImages(in folderURL: URL) async -> [URL] {
        await Task.detached(priority: .userInitiated) {
            var urls: [URL] = []

            let resourceKeys: Set<URLResourceKey> = [.isRegularFileKey, .nameKey]
            guard let enumerator = FileManager.default.enumerator(
                at: folderURL,
                includingPropertiesForKeys: Array(resourceKeys),
                options: [.skipsHiddenFiles]
            ) else {
                return urls
            }

            for case let fileURL as URL in enumerator {
                let ext = fileURL.pathExtension.lowercased()
                if Self.supportedExtensions.contains(ext) {
                    urls.append(fileURL)
                }
            }

            return urls.sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
        }.value
    }

    private func loadThumbnailsInBatches(items: [ImageItem], batchSize: Int) async {
        for batchStart in stride(from: 0, to: items.count, by: batchSize) {
            if Task.isCancelled { break }

            let batchEnd = min(batchStart + batchSize, items.count)
            let batch = Array(items[batchStart..<batchEnd])

            await withTaskGroup(of: Void.self) { group in
                for item in batch {
                    group.addTask {
                        await item.loadThumbnail(maxSize: 512)
                    }
                }
            }

            self.statusMessage = "Loaded \(batchEnd) of \(items.count) thumbnails"
        }

        if !Task.isCancelled {
            self.statusMessage = "\(items.count) images"
        }
    }

    func revealInFinder(_ item: ImageItem) {
        NSWorkspace.shared.activateFileViewerSelecting([item.url])
    }

    func openWithDefaultApp(_ item: ImageItem) {
        NSWorkspace.shared.open(item.url)
    }
}
