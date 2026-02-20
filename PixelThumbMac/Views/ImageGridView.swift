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
                        onRevealInFinder: { viewModel.revealInFinder(item) },
                        onOpenWithDefaultApp: { viewModel.openWithDefaultApp(item) }
                    )
                }
            }
            .padding(12)
        }
        .background(Color.appBackground)
    }
}
