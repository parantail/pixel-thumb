import SwiftUI

struct ContentView: View {
    @State private var viewModel = ImageBrowserViewModel()

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

            Text("Click \"Open Folder\" to select a folder containing images")
                .font(.callout)
                .foregroundStyle(.tertiary)

            Button("Open Folder") {
                viewModel.selectFolder()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }
}

#Preview {
    ContentView()
        .frame(width: 800, height: 600)
}
