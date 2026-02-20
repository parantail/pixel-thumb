import SwiftUI

@main
struct PixelThumbMacApp: App {
    @State private var viewModel = ImageBrowserViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .frame(minWidth: 600, minHeight: 400)
        }
        .windowStyle(.automatic)
        .defaultSize(width: 1024, height: 768)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open Folder...") {
                    viewModel.selectFolder()
                }
                .keyboardShortcut("o", modifiers: .command)
            }
        }
    }
}
