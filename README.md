# PixelThumb

A lightweight Windows native thumbnail viewer designed for pixel art. Browse thousands of small sprite images at adjustable scales with crisp nearest-neighbor rendering.

## Features

- **Pixel-Perfect Scaling** — NearestNeighbor interpolation keeps pixel art sharp at any zoom level (32px to 512px)
- **Virtualized Grid** — Smooth scrolling through thousands of images using UI virtualization
- **Async Loading** — Images load in background batches without freezing the UI
- **Folder Recursion** — Scans all subfolders for supported image formats
- **Context Menu** — Right-click for image info (resolution, file size) or to reveal in Explorer
- **Dark Theme** — Easy on the eyes for long browsing sessions

## Screenshot

```
┌─────────────────────────────────────────────────────┐
│ [Open Folder]  ────────●──────── 128px              │
├─────────────────────────────────────────────────────┤
│ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐      │
│ │      │ │      │ │      │ │      │ │      │      │
│ │ img1 │ │ img2 │ │ img3 │ │ img4 │ │ img5 │      │
│ └──────┘ └──────┘ └──────┘ └──────┘ └──────┘      │
│ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐      │
│ │      │ │      │ │      │ │      │ │      │      │
│ │ img6 │ │ img7 │ │ img8 │ │ img9 │ │img10 │      │
│ └──────┘ └──────┘ └──────┘ └──────┘ └──────┘      │
├─────────────────────────────────────────────────────┤
│ 1024 images (C:\sprites\characters)                 │
└─────────────────────────────────────────────────────┘
```

## Requirements

- Windows 10/11
- [.NET 8 Runtime](https://dotnet.microsoft.com/download/dotnet/8.0)

## Build & Run

```bash
cd PixelThumb
dotnet run
```

Or to create a standalone single-file executable (~154 MB, no .NET install required):

```bash
dotnet publish -c Release -r win-x64 --self-contained -p:PublishSingleFile=true
```

Output: `bin/Release/net8.0-windows/win-x64/publish/PixelThumb.exe`

## Supported Formats

PNG, JPEG, BMP, GIF, ICO, TIFF

## Tech Stack

- **WPF** (.NET 8) — Windows native UI framework
- **VirtualizingWrapPanel** — Virtualized grid layout for large collections
- **MVVM** — Clean architecture with data binding

## License

MIT
