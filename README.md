# PixelThumb

A lightweight native thumbnail viewer designed for pixel art. Browse thousands of small sprite images at adjustable scales with crisp nearest-neighbor rendering.

Available for **Windows** (WPF) and **macOS** (SwiftUI).

## Features

- **Pixel-Perfect Scaling** — NearestNeighbor interpolation keeps pixel art sharp at any zoom level
- **Fit Small / Scale Mode** — Auto-fit small images or manually set pixel scale (1x-16x)
- **Virtualized Grid** — Smooth scrolling through thousands of images
- **Async Loading** — Images load in background batches without freezing the UI
- **Folder Recursion** — Scans all subfolders for supported image formats
- **Context Menu** — Right-click for image info (resolution, file size) or to reveal in Finder/Explorer
- **Dark Theme** — Easy on the eyes for long browsing sessions

## Screenshot

```text
┌─────────────────────────────────────────────────────────────────┐
│ [Open Folder]  ☑ Fit Small   Size: ────●──── 128px             │
├─────────────────────────────────────────────────────────────────┤
│ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐         │
│ │      │ │      │ │      │ │      │ │      │ │      │         │
│ │ img1 │ │ img2 │ │ img3 │ │ img4 │ │ img5 │ │ img6 │         │
│ └──────┘ └──────┘ └──────┘ └──────┘ └──────┘ └──────┘         │
│ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐         │
│ │      │ │      │ │      │ │      │ │      │ │      │         │
│ │ img7 │ │ img8 │ │ img9 │ │img10 │ │img11 │ │img12 │         │
│ └──────┘ └──────┘ └──────┘ └──────┘ └──────┘ └──────┘         │
├─────────────────────────────────────────────────────────────────┤
│ 📁 /path/to/sprites │ 1024 images                               │
└─────────────────────────────────────────────────────────────────┘
```

## Supported Formats

PNG, JPEG, BMP, GIF, ICO, TIFF

---

## Windows (WPF)

### Requirements

- Windows 10/11
- [.NET 8 Runtime](https://dotnet.microsoft.com/download/dotnet/8.0)

### Build & Run

```bash
cd PixelThumb
dotnet run
```

Or create a standalone single-file executable (~154 MB, no .NET install required):

```bash
dotnet publish -c Release -r win-x64 --self-contained -p:PublishSingleFile=true
```

Output: `bin/Release/net8.0-windows/win-x64/publish/PixelThumb.exe`

### Tech Stack

- **WPF** (.NET 8) — Windows native UI framework
- **VirtualizingWrapPanel** — Virtualized grid layout for large collections
- **MVVM** — Clean architecture with data binding

---

## macOS (SwiftUI)

### macOS Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15.0 or later

### macOS Build & Run

Open in Xcode:

```bash
open PixelThumbMac/PixelThumbMac.xcodeproj
```

Or build from command line:

```bash
cd PixelThumbMac
xcodebuild -scheme PixelThumbMac -configuration Release build
```

The built app will be in:

```
~/Library/Developer/Xcode/DerivedData/PixelThumbMac-*/Build/Products/Release/PixelThumbMac.app
```

### macOS Tech Stack

- **SwiftUI** — macOS native UI framework
- **LazyVGrid** — Virtualized grid with adaptive columns
- **@Observable** — Modern Swift observation for reactive updates
- **CALayer** — Nearest-neighbor rendering via `magnificationFilter = .nearest`
- **async/await** — Concurrent thumbnail loading with Task groups

### Project Structure

```text
PixelThumbMac/
├── PixelThumbMacApp.swift              # App entry point
├── Models/
│   └── ImageItem.swift                 # Image model with lazy thumbnail loading
├── ViewModels/
│   └── ImageBrowserViewModel.swift     # Main ViewModel (@Observable)
├── Views/
│   ├── ContentView.swift               # Main layout
│   ├── ToolbarView.swift               # Top toolbar controls
│   ├── ImageGridView.swift             # LazyVGrid thumbnail grid
│   ├── ThumbnailView.swift             # Individual thumbnail cell
│   └── StatusBarView.swift             # Bottom status bar
├── Components/
│   └── PixelPerfectImage.swift         # NSViewRepresentable for pixel rendering
└── Extensions/
    └── Color+Hex.swift                 # Color helpers
```

---

## License

MIT
