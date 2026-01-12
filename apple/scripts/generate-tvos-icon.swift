#!/usr/bin/env swift

// Script to generate Apple TV app icon
// Run with: swift scripts/generate-tvos-icon.swift
//
// Matches the brand design:
// - Gradient background: #0a0a0f -> #1a1a2e (top-left to bottom-right)
// - Gradient spiral stroke: #48dbfb -> #ff6b6b (cyan to coral)
//
// Apple TV icon sizes:
// - App Icon: 400x240 @1x (800x480 @2x) - displayed on tvOS home screen
// - Top Shelf Wide: 2320x720 @1x (4640x1440 @2x)
// - Top Shelf: 1920x720 @1x (3840x1440 @2x)

import Foundation
import AppKit

// Brand colors (matching web/public/icon-*.svg)
let primaryColor = NSColor(red: 0.282, green: 0.859, blue: 0.984, alpha: 1.0)  // #48DBFB (cyan)
let secondaryColor = NSColor(red: 1.0, green: 0.420, blue: 0.420, alpha: 1.0)  // #FF6B6B (coral)
let bgColorStart = NSColor(red: 0.039, green: 0.039, blue: 0.059, alpha: 1.0)  // #0A0A0F
let bgColorEnd = NSColor(red: 0.102, green: 0.102, blue: 0.180, alpha: 1.0)    // #1A1A2E

// tvOS icon layer types
enum LayerType {
    case front   // Spiral only (transparent background for parallax)
    case back    // Background gradient only
    case combined // Both combined (for top shelf images)
}

// tvOS icon sizes: (width, height, scale, layerType, filename)
let tvOSIconSizes: [(Int, Int, Int, LayerType, String)] = [
    // App icon layers - home screen (400x240)
    (400, 240, 1, .front, "tvos-icon-front"),
    (400, 240, 2, .front, "tvos-icon-front@2x"),
    (400, 240, 1, .back, "tvos-icon-back"),
    (400, 240, 2, .back, "tvos-icon-back@2x"),
    // App icon layers - App Store (1280x768)
    (1280, 768, 1, .front, "tvos-appstore-front"),
    (1280, 768, 1, .back, "tvos-appstore-back"),
    // Top Shelf Wide (combined image)
    (2320, 720, 1, .combined, "tvos-top-shelf-wide"),
    (2320, 720, 2, .combined, "tvos-top-shelf-wide@2x"),
    // Top Shelf (combined image)
    (1920, 720, 1, .combined, "tvos-top-shelf"),
    (1920, 720, 2, .combined, "tvos-top-shelf@2x"),
]

func createTVOSIcon(width: Int, height: Int, layerType: LayerType) -> NSImage {
    let image = NSImage(size: NSSize(width: width, height: height))
    image.lockFocus()

    let rect = NSRect(x: 0, y: 0, width: width, height: height)

    // Draw gradient background (for back layer or combined)
    if layerType == .back || layerType == .combined {
        let bgGradient = NSGradient(colors: [bgColorStart, bgColorEnd])!
        bgGradient.draw(in: rect, angle: -45)
    }

    // Draw spiral (for front layer or combined)
    if layerType == .front || layerType == .combined {
        // Use the shorter dimension to determine spiral size
        let minDim = CGFloat(min(width, height))
        let padding = minDim * 0.15
        let spiralSize = minDim - (padding * 2)
        let scale = spiralSize / 24.0

        // Center the spiral
        let offsetX = (CGFloat(width) - spiralSize) / 2
        let offsetY = (CGFloat(height) - spiralSize) / 2

        func svgToLocal(_ x: CGFloat, _ y: CGFloat) -> NSPoint {
            let localX = offsetX + (x - 0) * scale
            let localY = CGFloat(height) - (offsetY + y * scale)
            return NSPoint(x: localX, y: localY)
        }

        // Build spiral path (same as other icons)
        let path = NSBezierPath()
        path.lineWidth = 2.0 * scale
        path.lineCapStyle = .round
        path.lineJoinStyle = .round

        path.move(to: svgToLocal(12, 12))
        path.curve(to: svgToLocal(6, 14), controlPoint1: svgToLocal(10, 9.33), controlPoint2: svgToLocal(6, 9.33))
        path.curve(to: svgToLocal(12, 20), controlPoint1: svgToLocal(6, 17.5), controlPoint2: svgToLocal(8.5, 20))
        path.curve(to: svgToLocal(20, 12), controlPoint1: svgToLocal(17, 20), controlPoint2: svgToLocal(20, 16))
        path.curve(to: svgToLocal(10, 2), controlPoint1: svgToLocal(20, 6), controlPoint2: svgToLocal(16, 2))
        path.curve(to: svgToLocal(-2, 14), controlPoint1: svgToLocal(2, 2), controlPoint2: svgToLocal(-2, 8))

        drawGradientStroke(path: path, from: primaryColor, to: secondaryColor)
    }

    image.unlockFocus()
    return image
}

func drawGradientStroke(path: NSBezierPath, from startColor: NSColor, to endColor: NSColor) {
    let flatness = path.flatness
    path.flatness = 0.1
    
    let flatPath = path.flattened
    var points: [NSPoint] = []
    
    for i in 0..<flatPath.elementCount {
        var pointArray = [NSPoint](repeating: .zero, count: 3)
        let elementType = flatPath.element(at: i, associatedPoints: &pointArray)
        if elementType == .moveTo || elementType == .lineTo {
            points.append(pointArray[0])
        }
    }
    
    path.flatness = flatness
    guard points.count > 1 else { return }
    
    for i in 0..<(points.count - 1) {
        let t = CGFloat(i) / CGFloat(points.count - 1)
        let color = interpolateColor(from: startColor, to: endColor, t: t)
        
        let segment = NSBezierPath()
        segment.lineWidth = path.lineWidth
        segment.lineCapStyle = .round
        segment.lineJoinStyle = .round
        segment.move(to: points[i])
        segment.line(to: points[i + 1])
        
        color.setStroke()
        segment.stroke()
    }
}

func interpolateColor(from: NSColor, to: NSColor, t: CGFloat) -> NSColor {
    let fromRGB = from.usingColorSpace(.sRGB) ?? from
    let toRGB = to.usingColorSpace(.sRGB) ?? to
    
    let r = fromRGB.redComponent + (toRGB.redComponent - fromRGB.redComponent) * t
    let g = fromRGB.greenComponent + (toRGB.greenComponent - fromRGB.greenComponent) * t
    let b = fromRGB.blueComponent + (toRGB.blueComponent - fromRGB.blueComponent) * t
    let a = fromRGB.alphaComponent + (toRGB.alphaComponent - fromRGB.alphaComponent) * t
    
    return NSColor(red: r, green: g, blue: b, alpha: a)
}

func savePNG(image: NSImage, to url: URL, pixelWidth: Int, pixelHeight: Int) {
    // Create a bitmap at exact pixel dimensions
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelWidth,
        pixelsHigh: pixelHeight,
        bitsPerSample: 8,
        samplesPerPixel: 3,
        hasAlpha: false,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        print("Failed to create bitmap for \(url.lastPathComponent)")
        return
    }

    bitmap.size = NSSize(width: pixelWidth, height: pixelHeight)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

    // Draw the image into the bitmap
    image.draw(in: NSRect(x: 0, y: 0, width: pixelWidth, height: pixelHeight),
               from: NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height),
               operation: .copy,
               fraction: 1.0)

    NSGraphicsContext.restoreGraphicsState()

    guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to create PNG data for \(url.lastPathComponent)")
        return
    }

    do {
        try pngData.write(to: url)
        print("Created: \(url.lastPathComponent) (\(pixelWidth)x\(pixelHeight))")
    } catch {
        print("Failed to write \(url.lastPathComponent): \(error)")
    }
}

// Main
let fileManager = FileManager.default
let scriptURL = URL(fileURLWithPath: #file)
let projectRoot = scriptURL.deletingLastPathComponent().deletingLastPathComponent()
let assetsPath = projectRoot.appendingPathComponent("Uzumaki/Assets.xcassets/TVAppIcon.brandassets")

print("Generating tvOS app icons...")

// Define output paths for different asset types
func getOutputPath(for filename: String) -> URL {
    if filename.hasPrefix("tvos-icon-front") {
        return assetsPath.appendingPathComponent("App Icon.imagestack/Front.imagestacklayer/Content.imageset")
    } else if filename.hasPrefix("tvos-icon-back") {
        return assetsPath.appendingPathComponent("App Icon.imagestack/Back.imagestacklayer/Content.imageset")
    } else if filename.hasPrefix("tvos-appstore-front") {
        return assetsPath.appendingPathComponent("App Icon - App Store.imagestack/Front.imagestacklayer/Content.imageset")
    } else if filename.hasPrefix("tvos-appstore-back") {
        return assetsPath.appendingPathComponent("App Icon - App Store.imagestack/Back.imagestacklayer/Content.imageset")
    } else if filename.hasPrefix("tvos-top-shelf-wide") {
        return assetsPath.appendingPathComponent("Top Shelf Image Wide.imageset")
    } else {
        return assetsPath.appendingPathComponent("Top Shelf Image.imageset")
    }
}

for (width, height, scaleFactor, layerType, name) in tvOSIconSizes {
    let actualWidth = width * scaleFactor
    let actualHeight = height * scaleFactor
    let icon = createTVOSIcon(width: actualWidth, height: actualHeight, layerType: layerType)
    let outputPath = getOutputPath(for: name)
    try? fileManager.createDirectory(at: outputPath, withIntermediateDirectories: true)
    savePNG(image: icon, to: outputPath.appendingPathComponent("\(name).png"), pixelWidth: actualWidth, pixelHeight: actualHeight)
}

print("Done! tvOS app icons generated.")

