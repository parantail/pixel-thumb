import SwiftUI
import AppKit

struct PixelPerfectImage: NSViewRepresentable {
    let image: NSImage?
    let imageWidth: Int
    let imageHeight: Int
    let containerSize: CGFloat
    let fitSmall: Bool
    let pixelScale: CGFloat

    func makeNSView(context: Context) -> PixelPerfectImageView {
        let view = PixelPerfectImageView()
        view.wantsLayer = true
        return view
    }

    func updateNSView(_ nsView: PixelPerfectImageView, context: Context) {
        nsView.configure(
            image: image,
            imageWidth: imageWidth,
            imageHeight: imageHeight,
            containerSize: containerSize,
            fitSmall: fitSmall,
            pixelScale: pixelScale
        )
    }
}

class PixelPerfectImageView: NSView {
    private var imageLayer: CALayer?
    private var currentConfig: (
        image: NSImage?,
        imageWidth: Int,
        imageHeight: Int,
        containerSize: CGFloat,
        fitSmall: Bool,
        pixelScale: CGFloat
    )?

    func configure(
        image: NSImage?,
        imageWidth: Int,
        imageHeight: Int,
        containerSize: CGFloat,
        fitSmall: Bool,
        pixelScale: CGFloat
    ) {
        currentConfig = (image, imageWidth, imageHeight, containerSize, fitSmall, pixelScale)

        guard let image = image else {
            imageLayer?.removeFromSuperlayer()
            imageLayer = nil
            return
        }

        if imageLayer == nil {
            let layer = CALayer()
            self.layer?.addSublayer(layer)
            imageLayer = layer
        }

        guard let layer = imageLayer else { return }

        layer.magnificationFilter = .nearest
        layer.minificationFilter = .nearest
        layer.contentsGravity = .resizeAspect

        var cgImage: CGImage?
        if let representations = image.representations.first as? NSBitmapImageRep {
            cgImage = representations.cgImage
        } else {
            var rect = NSRect(origin: .zero, size: image.size)
            cgImage = image.cgImage(forProposedRect: &rect, context: nil, hints: nil)
        }

        layer.contents = cgImage

        updateLayerFrame()
    }

    private func updateLayerFrame() {
        guard let config = currentConfig,
              let image = config.image,
              let layer = imageLayer else { return }

        let imgW = CGFloat(config.imageWidth > 0 ? config.imageWidth : Int(image.size.width))
        let imgH = CGFloat(config.imageHeight > 0 ? config.imageHeight : Int(image.size.height))
        let containerSize = config.containerSize
        let fitSmall = config.fitSmall
        let pixelScale = config.pixelScale

        guard imgW > 0 && imgH > 0 else { return }

        let displaySize: CGSize

        if fitSmall {
            // Fit Small: scale to fill container
            let scale = min(containerSize / imgW, containerSize / imgH)
            displaySize = CGSize(width: imgW * scale, height: imgH * scale)
        } else {
            // Scale mode: apply pixel scale
            let scaledW = imgW * pixelScale
            let scaledH = imgH * pixelScale

            if scaledW <= containerSize && scaledH <= containerSize {
                // Scaled image fits in container
                displaySize = CGSize(width: scaledW, height: scaledH)
            } else {
                // Scaled image too large, fit to container
                let fitScale = min(containerSize / scaledW, containerSize / scaledH)
                displaySize = CGSize(width: scaledW * fitScale, height: scaledH * fitScale)
            }
        }

        let x = (containerSize - displaySize.width) / 2
        let y = (containerSize - displaySize.height) / 2

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.frame = CGRect(x: x, y: y, width: displaySize.width, height: displaySize.height)
        CATransaction.commit()
    }

    override func layout() {
        super.layout()
        updateLayerFrame()
    }
}
