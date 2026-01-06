#!/usr/bin/env swift

// Script to generate launch logo with just the gradient spiral (no rounded button)
// Run with: swift scripts/generate-launch-logo.swift
//
// Creates a transparent PNG with just the gradient spiral centered.
// The spiral uses the brand gradient: #48dbfb -> #ff6b6b (cyan to coral)

import Foundation
import AppKit

// Launch logo sizes (base size, we generate @1x, @2x, @3x)
let baseSize = 120  // Base size for the spiral

// Brand colors (matching web/public/icon-*.svg)
let primaryColor = NSColor(red: 0.282, green: 0.859, blue: 0.984, alpha: 1.0)  // #48DBFB (cyan)
let secondaryColor = NSColor(red: 1.0, green: 0.420, blue: 0.420, alpha: 1.0)  // #FF6B6B (coral)

func createLaunchLogo(size: Int) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    
    // Transparent background (no fill)
    
    // Draw spiral in center
    // The spiral is drawn within a 24x24 viewBox
    let padding = CGFloat(size) * 0.1  // 10% padding
    let spiralSize = CGFloat(size) * 0.8
    let scale = spiralSize / 24.0
    
    // Build the spiral path matching the web SVG path:
    // M12 12c-2-2.67-6-2.67-6 2 0 3.5 2.5 6 6 6 5 0 8-4 8-8 0-6-4-10-10-10-8 0-12 6-12 12
    let path = NSBezierPath()
    path.lineWidth = 2.5 * scale
    path.lineCapStyle = .round
    path.lineJoinStyle = .round
    
    // Convert from SVG coordinates (12,12 is center in 24x24 viewBox) to our coordinate system
    func svgToLocal(_ x: CGFloat, _ y: CGFloat) -> NSPoint {
        let localX = padding + x * scale
        let localY = CGFloat(size) - (padding + y * scale)  // Flip Y for Cocoa coordinates
        return NSPoint(x: localX, y: localY)
    }
    
    // Start at (12, 12)
    path.move(to: svgToLocal(12, 12))
    
    // c-2-2.67-6-2.67-6 2
    path.curve(to: svgToLocal(6, 14),
               controlPoint1: svgToLocal(10, 9.33),
               controlPoint2: svgToLocal(6, 9.33))
    
    // c0 3.5 2.5 6 6 6
    path.curve(to: svgToLocal(12, 20),
               controlPoint1: svgToLocal(6, 17.5),
               controlPoint2: svgToLocal(8.5, 20))
    
    // c5 0 8-4 8-8
    path.curve(to: svgToLocal(20, 12),
               controlPoint1: svgToLocal(17, 20),
               controlPoint2: svgToLocal(20, 16))
    
    // c0-6-4-10-10-10
    path.curve(to: svgToLocal(10, 2),
               controlPoint1: svgToLocal(20, 6),
               controlPoint2: svgToLocal(16, 2))
    
    // c-8 0-12 6-12 12
    path.curve(to: svgToLocal(-2, 14),
               controlPoint1: svgToLocal(2, 2),
               controlPoint2: svgToLocal(-2, 8))
    
    // Draw with gradient stroke
    drawGradientStroke(path: path, from: primaryColor, to: secondaryColor)
    
    image.unlockFocus()
    return image
}

/// Draws a path with a gradient stroke from startColor to endColor
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
let scriptURL = URL(fileURLWithPath: #file)
let projectRoot = scriptURL.deletingLastPathComponent().deletingLastPathComponent()
let imagesetPath = projectRoot.appendingPathComponent("Uzumaki/Assets.xcassets/LaunchLogo.imageset")

print("Generating launch logos to: \(imagesetPath.path)")

// Generate @1x, @2x, @3x
let scales = [(1, "launch-logo.png"), (2, "launch-logo@2x.png"), (3, "launch-logo@3x.png")]
for (scale, filename) in scales {
    let size = baseSize * scale
    let logo = createLaunchLogo(size: size)
    savePNG(image: logo, to: imagesetPath.appendingPathComponent(filename))
}

print("Done! Launch logos regenerated with just the gradient spiral.")

