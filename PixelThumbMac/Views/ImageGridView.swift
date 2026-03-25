import SwiftUI

struct ImageGridView: View {
    @Bindable var viewModel: ImageBrowserViewModel

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: viewModel.thumbnailSize), spacing: 8)]
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(viewModel.filteredImages) { item in
                    ThumbnailView(
                        item: item,
                        size: viewModel.thumbnailSize,
                        fitSmall: viewModel.fitSmallImages,
                        fitLarge: viewModel.fitLargeImages,
                        pixelScale: viewModel.pixelScale,
                        isSelected: viewModel.selectedItems.contains(item.id),
                        onTap: { event in
                            handleSelection(item: item, event: event)
                        },
                        onRevealInFinder: { viewModel.revealInFinder(item) },
                        onOpenWithDefaultApp: { viewModel.openWithDefaultApp(item) },
                        onCopyFilePath: { viewModel.copyFilePath(item) }
                    )
                }
            }
            .padding(12)
        }
        .background(Color.appBackground)
        .copyable(viewModel.selectedItems.isEmpty ? [] :
            viewModel.images.filter { viewModel.selectedItems.contains($0.id) }.map { $0.url as NSURL })
    }

    private func handleSelection(item: ImageItem, event: NSEvent?) {
        let hasCommand = event?.modifierFlags.contains(.command) ?? false
        let hasShift = event?.modifierFlags.contains(.shift) ?? false

        if hasCommand {
            if viewModel.selectedItems.contains(item.id) {
                viewModel.selectedItems.remove(item.id)
            } else {
                viewModel.selectedItems.insert(item.id)
            }
        } else if hasShift, let lastSelected = viewModel.filteredImages.last(where: { viewModel.selectedItems.contains($0.id) }) {
            let items = viewModel.filteredImages
            guard let startIdx = items.firstIndex(where: { $0.id == lastSelected.id }),
                  let endIdx = items.firstIndex(where: { $0.id == item.id }) else { return }
            let range = min(startIdx, endIdx)...max(startIdx, endIdx)
            for i in range {
                viewModel.selectedItems.insert(items[i].id)
            }
        } else {
            viewModel.selectedItems = [item.id]
        }
    }
}
