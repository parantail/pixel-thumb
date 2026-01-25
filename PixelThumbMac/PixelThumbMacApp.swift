import SwiftUI

@main
struct PixelThumbMacApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 600, minHeight: 400)
        }
        .windowStyle(.automatic)
        .defaultSize(width: 1024, height: 768)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
