import SwiftUI

struct ToolbarView: View {
    @Bindable var viewModel: ImageBrowserViewModel

    var body: some View {
        HStack(spacing: 16) {
            Button(action: { viewModel.selectFolder() }) {
                Label("Open Folder", systemImage: "folder.badge.plus")
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)

            Divider()
                .frame(height: 20)

            Toggle("Fit Small", isOn: $viewModel.fitSmallImages)
                .toggleStyle(.checkbox)

            HStack(spacing: 8) {
                Text("Scale:")
                    .foregroundStyle(.secondary)

                Slider(value: $viewModel.pixelScale, in: 1...16, step: 1)
                    .frame(width: 100)

                Text("\(Int(viewModel.pixelScale))x")
                    .monospacedDigit()
                    .frame(width: 30, alignment: .trailing)
            }
            .disabled(viewModel.fitSmallImages)
            .opacity(viewModel.fitSmallImages ? 0.5 : 1.0)

            Divider()
                .frame(height: 20)

            HStack(spacing: 8) {
                Text("Size:")
                    .foregroundStyle(.secondary)

                Slider(value: $viewModel.thumbnailSize, in: 32...512, step: 16)
                    .frame(width: 120)

                Text("\(Int(viewModel.thumbnailSize))px")
                    .monospacedDigit()
                    .frame(width: 50, alignment: .trailing)
            }

            Spacer()

            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.6)
                    .frame(width: 16, height: 16)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.appToolbar)
    }
}
