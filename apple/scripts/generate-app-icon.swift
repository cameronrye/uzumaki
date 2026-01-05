#!/usr/bin/env swift

// Script to generate app icon from the spiral logo
// Run with: swift scripts/generate-app-icon.swift

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

// Brand colors
let primaryColor = NSColor(red: 0.282, green: 0.859, blue: 0.984, alpha: 1.0)  // #48DBFB
let secondaryColor = NSColor(red: 1.0, green: 0.420, blue: 0.420, alpha: 1.0)  // #FF6B6B
let backgroundColor = NSColor(red: 0.039, green: 0.039, blue: 0.059, alpha: 1.0)  // #0A0A0F

func createAppIcon(size: Int) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    
    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    
    // Background
    backgroundColor.setFill()
    NSBezierPath(roundedRect: rect, xRadius: CGFloat(size) * 0.2, yRadius: CGFloat(size) * 0.2).fill()
    
    // Draw spiral in center
    let center = CGPoint(x: CGFloat(size) / 2, y: CGFloat(size) / 2)
    let scale = CGFloat(size) / 24.0 * 0.6
    
    let path = NSBezierPath()
    path.lineWidth = 2.0 * scale
    path.lineCapStyle = .round
    path.lineJoinStyle = .round
    
    // Spiral path (matching SpiralLogo)
    path.move(to: NSPoint(x: center.x, y: center.y))
    path.curve(to: NSPoint(x: center.x - 6 * scale, y: center.y + 2 * scale),
               controlPoint1: NSPoint(x: center.x - 2 * scale, y: center.y - 2.67 * scale),
               controlPoint2: NSPoint(x: center.x - 6 * scale, y: center.y - 2.67 * scale))
    path.curve(to: NSPoint(x: center.x, y: center.y + 8 * scale),
               controlPoint1: NSPoint(x: center.x - 6 * scale, y: center.y + 5.5 * scale),
               controlPoint2: NSPoint(x: center.x - 3.5 * scale, y: center.y + 8 * scale))
    path.curve(to: NSPoint(x: center.x + 8 * scale, y: center.y),
               controlPoint1: NSPoint(x: center.x + 5 * scale, y: center.y + 8 * scale),
               controlPoint2: NSPoint(x: center.x + 8 * scale, y: center.y + 4 * scale))
    path.curve(to: NSPoint(x: center.x - 2 * scale, y: center.y - 10 * scale),
               controlPoint1: NSPoint(x: center.x + 8 * scale, y: center.y - 6 * scale),
               controlPoint2: NSPoint(x: center.x + 4 * scale, y: center.y - 10 * scale))
    
    // Gradient stroke
    let gradient = NSGradient(colors: [primaryColor, secondaryColor])!
    primaryColor.setStroke()
    path.stroke()
    
    image.unlockFocus()
    return image
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

