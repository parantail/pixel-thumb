import SwiftUI

struct ThumbnailView: View {
    let item: ImageItem
    let size: CGFloat
    let fitSmall: Bool
    let fitLarge: Bool
    let pixelScale: CGFloat
    let onRevealInFinder: () -> Void
    let onOpenWithDefaultApp: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Color.black.opacity(0.3)

                if item.isLoaded, let thumbnail = item.thumbnail {
                    PixelPerfectImage(
                        image: thumbnail,
                        imageWidth: item.width,
                        imageHeight: item.height,
                        containerSize: size - 8,
                        fitSmall: fitSmall,
                        fitLarge: fitLarge,
                        pixelScale: pixelScale
                    )
                    .id("\(item.id)-\(fitSmall)-\(fitLarge)-\(pixelScale)-\(size)")
                } else {
                    ProgressView()
                        .scaleEffect(0.5)
                }
            }
            .frame(width: size - 8, height: size - 8)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            Text(item.fileName)
                .font(.system(size: 10))
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: size - 8)
                .foregroundStyle(.secondary)
        }
        .padding(4)
        .background(Color.clear)
        .contextMenu {
            Text(item.fileName)
                .font(.headline)

            if item.isLoaded {
                Text("Resolution: \(item.resolution)")
                Text("Size: \(item.formattedFileSize)")
            }

            Divider()

            Button("Reveal in Finder") {
                onRevealInFinder()
            }
            .keyboardShortcut("r", modifiers: .command)

            Button("Open with Default App") {
                onOpenWithDefaultApp()
            }
            .keyboardShortcut(.return, modifiers: .command)
        }
        .task {
            await item.loadThumbnail()
        }
    }
}
