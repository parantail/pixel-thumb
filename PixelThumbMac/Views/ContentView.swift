import SwiftUI

struct ContentView: View {
    @Bindable var viewModel: ImageBrowserViewModel

    var body: some View {
        VStack(spacing: 0) {
            ToolbarView(viewModel: viewModel)

            Divider()

            if viewModel.images.isEmpty && !viewModel.isLoading {
                emptyStateView
            } else {
                ImageGridView(viewModel: viewModel)
            }

            Divider()

            StatusBarView(
                message: viewModel.statusMessage,
                folderPath: viewModel.currentFolderPath
            )
        }
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 64))
                .foregroundStyle(.tertiary)

            Text("No Images")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("Use File → Open Folder (⌘O) to select a folder")
                .font(.callout)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }
}

#Preview {
    ContentView(viewModel: ImageBrowserViewModel())
        .frame(width: 800, height: 600)
}
