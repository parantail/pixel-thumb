import SwiftUI

struct ToolbarView: View {
    @Bindable var viewModel: ImageBrowserViewModel
    @State private var showFilterPopover = false

    var body: some View {
        HStack(spacing: 16) {
            Button {
                showFilterPopover.toggle()
            } label: {
                HStack(spacing: 4) {
                    Text("Filter")
                    if viewModel.isFilterActive {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 6, height: 6)
                    }
                }
            }
            .popover(isPresented: $showFilterPopover, arrowEdge: .bottom) {
                FilterPopoverView(viewModel: viewModel)
            }

            Toggle("Fit Small", isOn: $viewModel.fitSmallImages)
                .toggleStyle(.checkbox)

            Toggle("Fit Large", isOn: $viewModel.fitLargeImages)
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

private struct FilterPopoverView: View {
    @Bindable var viewModel: ImageBrowserViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Filter by Dimensions")
                .font(.headline)

            Grid(alignment: .trailing, horizontalSpacing: 8, verticalSpacing: 6) {
                GridRow {
                    Text("Min W:")
                        .foregroundStyle(.secondary)
                    TextField("", value: $viewModel.filterMinWidth, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 70)
                    Text("Max W:")
                        .foregroundStyle(.secondary)
                    TextField("", value: $viewModel.filterMaxWidth, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 70)
                }
                GridRow {
                    Text("Min H:")
                        .foregroundStyle(.secondary)
                    TextField("", value: $viewModel.filterMinHeight, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 70)
                    Text("Max H:")
                        .foregroundStyle(.secondary)
                    TextField("", value: $viewModel.filterMaxHeight, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 70)
                }
            }

            HStack {
                Spacer()
                Button("Clear") {
                    viewModel.clearFilters()
                }
                .disabled(!viewModel.isFilterActive)
            }
        }
        .padding()
        .frame(width: 280)
    }
}
