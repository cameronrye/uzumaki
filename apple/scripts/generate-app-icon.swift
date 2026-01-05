#!/usr/bin/env swift

// Script to generate app icon from the spiral logo
// Run with: swift scripts/generate-app-icon.swift
//
// Matches the web favicon design:
// - Gradient background: #0a0a0f -> #1a1a2e (top-left to bottom-right)
// - Gradient spiral stroke: #48dbfb -> #ff6b6b (cyan to coral)
// - 12.5% corner radius (matching web icon-192.svg and icon-512.svg)

import Foundation
import AppKit

// Icon sizes needed
let iOSSizes: [(Int, String)] = [
    (1024, "ios-1024")
]

let macSizes: [(Int, Int, String)] = [
    (16, 1, "mac-16"),
    (16, 2, "mac-16@2x"),
    (32, 1, "mac-32"),
    (32, 2, "mac-32@2x"),
    (128, 1, "mac-128"),
    (128, 2, "mac-128@2x"),
    (256, 1, "mac-256"),
    (256, 2, "mac-256@2x"),
    (512, 1, "mac-512"),
    (512, 2, "mac-512@2x")
]

// Brand colors (matching web/public/icon-*.svg)
let primaryColor = NSColor(red: 0.282, green: 0.859, blue: 0.984, alpha: 1.0)  // #48DBFB (cyan)
let secondaryColor = NSColor(red: 1.0, green: 0.420, blue: 0.420, alpha: 1.0)  // #FF6B6B (coral)
let bgColorStart = NSColor(red: 0.039, green: 0.039, blue: 0.059, alpha: 1.0)  // #0A0A0F
let bgColorEnd = NSColor(red: 0.102, green: 0.102, blue: 0.180, alpha: 1.0)    // #1A1A2E

func createAppIcon(size: Int) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let cornerRadius = CGFloat(size) * 0.125  // 12.5% corner radius (matches web icons)

    // Save graphics state for clipping
    NSGraphicsContext.current?.saveGraphicsState()

    // Create rounded rect path for clipping
    let clipPath = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
    clipPath.addClip()

    // Draw gradient background (top-left to bottom-right, matching web)
    let bgGradient = NSGradient(colors: [bgColorStart, bgColorEnd])!
    bgGradient.draw(in: rect, angle: -45)  // -45 degrees = top-left to bottom-right

    // Restore graphics state
    NSGraphicsContext.current?.restoreGraphicsState()

    // Draw spiral in center
    // The spiral is drawn within a 24x24 viewBox, centered with padding
    // Web uses: translate(48, 48) scale(4) for 192px = 25% padding each side
    // Web uses: translate(128, 128) scale(10.67) for 512px = 25% padding each side
    let padding = CGFloat(size) * 0.25
    let spiralSize = CGFloat(size) * 0.5
    let scale = spiralSize / 24.0

    // Build the spiral path matching the web SVG path:
    // M12 12c-2-2.67-6-2.67-6 2 0 3.5 2.5 6 6 6 5 0 8-4 8-8 0-6-4-10-10-10-8 0-12 6-12 12
    // This is a series of cubic bezier curves (c = relative cubic bezier)
    let path = NSBezierPath()
    path.lineWidth = 2.0 * scale
    path.lineCapStyle = .round
    path.lineJoinStyle = .round

    // Convert from SVG coordinates (12,12 is center in 24x24 viewBox) to our coordinate system
    // Note: NSImage coordinate system has Y increasing upward, so we flip Y
    func svgToLocal(_ x: CGFloat, _ y: CGFloat) -> NSPoint {
        let localX = padding + x * scale
        let localY = CGFloat(size) - (padding + y * scale)  // Flip Y for Cocoa coordinates
        return NSPoint(x: localX, y: localY)
    }

    // Start at (12, 12)
    path.move(to: svgToLocal(12, 12))

    // c-2-2.67-6-2.67-6 2 -> relative cubic bezier: control1(dx=-2,dy=-2.67), control2(dx=-6,dy=-2.67), end(dx=-6,dy=2)
    // From (12,12): control1(10,9.33), control2(6,9.33), end(6,14)
    path.curve(to: svgToLocal(6, 14),
               controlPoint1: svgToLocal(10, 9.33),
               controlPoint2: svgToLocal(6, 9.33))

    // c0 3.5 2.5 6 6 6 -> from (6,14): control1(6,17.5), control2(8.5,20), end(12,20)
    path.curve(to: svgToLocal(12, 20),
               controlPoint1: svgToLocal(6, 17.5),
               controlPoint2: svgToLocal(8.5, 20))

    // c5 0 8-4 8-8 -> from (12,20): control1(17,20), control2(20,16), end(20,12)
    path.curve(to: svgToLocal(20, 12),
               controlPoint1: svgToLocal(17, 20),
               controlPoint2: svgToLocal(20, 16))

    // c0-6-4-10-10-10 -> from (20,12): control1(20,6), control2(16,2), end(10,2)
    path.curve(to: svgToLocal(10, 2),
               controlPoint1: svgToLocal(20, 6),
               controlPoint2: svgToLocal(16, 2))

    // c-8 0-12 6-12 12 -> from (10,2): control1(2,2), control2(-2,8), end(-2,14)
    // Note: extends outside the viewBox slightly (that's intentional in original SVG)
    path.curve(to: svgToLocal(-2, 14),
               controlPoint1: svgToLocal(2, 2),
               controlPoint2: svgToLocal(-2, 8))

    // Draw with gradient stroke (approximated with multiple segments)
    // For true gradient stroke, we sample colors along the path
    drawGradientStroke(path: path, from: primaryColor, to: secondaryColor)

    image.unlockFocus()
    return image
}

/// Draws a path with a gradient stroke from startColor to endColor
func drawGradientStroke(path: NSBezierPath, from startColor: NSColor, to endColor: NSColor) {
    let flatness = path.flatness
    path.flatness = 0.1  // Higher precision for flattening

    let element = path.elementCount
    guard element > 0 else { return }

    // Get all points along the path by flattening it
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

    // Draw line segments with interpolated colors
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

/// Interpolates between two colors
func interpolateColor(from: NSColor, to: NSColor, t: CGFloat) -> NSColor {
    let fromRGB = from.usingColorSpace(.sRGB) ?? from
    let toRGB = to.usingColorSpace(.sRGB) ?? to

    let r = fromRGB.redComponent + (toRGB.redComponent - fromRGB.redComponent) * t
    let g = fromRGB.greenComponent + (toRGB.greenComponent - fromRGB.greenComponent) * t
    let b = fromRGB.blueComponent + (toRGB.blueComponent - fromRGB.blueComponent) * t
    let a = fromRGB.alphaComponent + (toRGB.alphaComponent - fromRGB.alphaComponent) * t

    return NSColor(red: r, green: g, blue: b, alpha: a)
}

func savePNG(image: NSImage, to url: URL) {
    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to create PNG for \(url.lastPathComponent)")
        return
    }
    
    do {
        try pngData.write(to: url)
        print("Created: \(url.lastPathComponent)")
    } catch {
        print("Failed to write \(url.lastPathComponent): \(error)")
    }
}

// Main
let fileManager = FileManager.default
let scriptURL = URL(fileURLWithPath: #file)
let projectRoot = scriptURL.deletingLastPathComponent().deletingLastPathComponent()
let iconsetPath = projectRoot.appendingPathComponent("Uzumaki/Assets.xcassets/AppIcon.appiconset")

print("Generating app icons to: \(iconsetPath.path)")

// iOS 1024x1024
let iosIcon = createAppIcon(size: 1024)
savePNG(image: iosIcon, to: iconsetPath.appendingPathComponent("ios-1024.png"))

// Mac sizes
for (size, scaleFactor, name) in macSizes {
    let actualSize = size * scaleFactor
    let icon = createAppIcon(size: actualSize)
    savePNG(image: icon, to: iconsetPath.appendingPathComponent("\(name).png"))
}

print("Done! Remember to update Contents.json with filenames.")

