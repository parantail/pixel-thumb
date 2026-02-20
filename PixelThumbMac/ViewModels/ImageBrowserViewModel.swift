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

    var filterMinWidth: Int? { didSet { scheduleFilterUpdate() } }
    var filterMaxWidth: Int? { didSet { scheduleFilterUpdate() } }
    var filterMinHeight: Int? { didSet { scheduleFilterUpdate() } }
    var filterMaxHeight: Int? { didSet { scheduleFilterUpdate() } }

    private(set) var filteredImages: [ImageItem] = []
    private(set) var isLoading: Bool = false
    private(set) var statusMessage: String = "No folder selected"
    private(set) var currentFolderPath: String?
    private var filterDebounceTask: Task<Void, Never>?

    var isFilterActive: Bool {
        filterMinWidth != nil || filterMaxWidth != nil ||
        filterMinHeight != nil || filterMaxHeight != nil
    }

    private func applyFilter() -> [ImageItem] {
        guard isFilterActive else { return images }
        return images.filter { item in
            if !item.isLoaded { return true }
            if let minW = filterMinWidth, item.width < minW { return false }
            if let maxW = filterMaxWidth, item.width > maxW { return false }
            if let minH = filterMinHeight, item.height < minH { return false }
            if let maxH = filterMaxHeight, item.height > maxH { return false }
            return true
        }
    }

    private func scheduleFilterUpdate() {
        filterDebounceTask?.cancel()
        filterDebounceTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled, let self else { return }
            self.filteredImages = self.applyFilter()
            if self.isFilterActive {
                self.statusMessage = "\(self.filteredImages.count) / \(self.images.count) images"
            }
        }
    }

    func clearFilters() {
        filterMinWidth = nil
        filterMaxWidth = nil
        filterMinHeight = nil
        filterMaxHeight = nil
    }

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
        filteredImages.removeAll()
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
            self.filteredImages = self.applyFilter()
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
            self.filteredImages = applyFilter()
            if isFilterActive {
                self.statusMessage = "\(filteredImages.count) / \(items.count) images"
            } else {
                self.statusMessage = "\(items.count) images"
            }
        }
    }

    func revealInFinder(_ item: ImageItem) {
        NSWorkspace.shared.activateFileViewerSelecting([item.url])
    }

    func openWithDefaultApp(_ item: ImageItem) {
        NSWorkspace.shared.open(item.url)
    }
}
