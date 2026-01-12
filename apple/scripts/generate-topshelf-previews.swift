#!/usr/bin/env swift

// Script to generate Top Shelf preview images for tvOS
// Run with: swift scripts/generate-topshelf-previews.swift
//
// Generates poster-style images (404x608) for each spiral preset
// These are used by the Top Shelf Extension to display dynamic content
//
// This script uses the same spiral algorithms as the main app to ensure
// TopShelf previews accurately represent each preset.

import Foundation
import AppKit

// MARK: - Constants

let PHI = (1.0 + sqrt(5.0)) / 2.0  // Golden ratio
let GOLDEN_ANGLE = Double.pi * (3.0 - sqrt(5.0))  // ~137.5 degrees

// Top Shelf poster dimensions
let posterWidth = 404
let posterHeight = 608

// Background color matching the app
let bgColor = NSColor(red: 0.039, green: 0.039, blue: 0.059, alpha: 1.0)

// MARK: - Color Definitions (matching ColorPreset.swift)

struct ColorDefinition {
    let colors: [NSColor]

    static let rainbow = ColorDefinition(colors: [
        NSColor(red: 1.000, green: 0.420, blue: 0.420, alpha: 1.0), // FF6B6B
        NSColor(red: 0.996, green: 0.792, blue: 0.341, alpha: 1.0), // FECA57
        NSColor(red: 0.282, green: 0.859, blue: 0.984, alpha: 1.0), // 48DBFB
        NSColor(red: 1.000, green: 0.624, blue: 0.953, alpha: 1.0), // FF9FF3
        NSColor(red: 0.329, green: 0.627, blue: 1.000, alpha: 1.0)  // 54A0FF
    ])

    static let aurora = ColorDefinition(colors: [
        NSColor(red: 0.000, green: 0.851, blue: 1.000, alpha: 1.0), // 00D9FF
        NSColor(red: 0.000, green: 1.000, blue: 0.529, alpha: 1.0), // 00FF87
        NSColor(red: 0.722, green: 1.000, blue: 0.000, alpha: 1.0), // B8FF00
        NSColor(red: 0.482, green: 0.408, blue: 0.933, alpha: 1.0), // 7B68EE
        NSColor(red: 0.255, green: 0.412, blue: 0.882, alpha: 1.0)  // 4169E1
    ])

    static let sunset = ColorDefinition(colors: [
        NSColor(red: 1.000, green: 0.420, blue: 0.208, alpha: 1.0), // FF6B35
        NSColor(red: 0.969, green: 0.773, blue: 0.624, alpha: 1.0), // F7C59F
        NSColor(red: 0.937, green: 0.627, blue: 0.043, alpha: 1.0), // EFA00B
        NSColor(red: 0.839, green: 0.318, blue: 0.031, alpha: 1.0), // D65108
        NSColor(red: 0.349, green: 0.122, blue: 0.039, alpha: 1.0)  // 591F0A
    ])

    static let neon = ColorDefinition(colors: [
        NSColor(red: 1.000, green: 0.000, blue: 1.000, alpha: 1.0), // FF00FF
        NSColor(red: 0.000, green: 1.000, blue: 1.000, alpha: 1.0), // 00FFFF
        NSColor(red: 1.000, green: 0.000, blue: 0.667, alpha: 1.0), // FF00AA
        NSColor(red: 0.000, green: 1.000, blue: 0.000, alpha: 1.0), // 00FF00
        NSColor(red: 1.000, green: 1.000, blue: 0.000, alpha: 1.0)  // FFFF00
    ])

    static let candy = ColorDefinition(colors: [
        NSColor(red: 1.000, green: 0.435, blue: 0.847, alpha: 1.0), // FF6FD8
        NSColor(red: 1.000, green: 0.604, blue: 0.620, alpha: 1.0), // FF9A9E
        NSColor(red: 0.996, green: 0.812, blue: 0.937, alpha: 1.0), // FECFEF
        NSColor(red: 0.631, green: 0.549, blue: 0.820, alpha: 1.0), // A18CD1
        NSColor(red: 0.984, green: 0.761, blue: 0.922, alpha: 1.0)  // FBC2EB
    ])

    static let ocean = ColorDefinition(colors: [
        NSColor(red: 0.000, green: 0.122, blue: 0.247, alpha: 1.0), // 001F3F
        NSColor(red: 0.000, green: 0.455, blue: 0.851, alpha: 1.0), // 0074D9
        NSColor(red: 0.498, green: 0.859, blue: 1.000, alpha: 1.0), // 7FDBFF
        NSColor(red: 0.224, green: 0.800, blue: 0.800, alpha: 1.0), // 39CCCC
        NSColor(red: 0.239, green: 0.600, blue: 0.439, alpha: 1.0)  // 3D9970
    ])

    static let retro = ColorDefinition(colors: [
        NSColor(red: 1.000, green: 0.000, blue: 1.000, alpha: 1.0), // FF00FF
        NSColor(red: 0.000, green: 1.000, blue: 1.000, alpha: 1.0), // 00FFFF
        NSColor(red: 1.000, green: 0.078, blue: 0.576, alpha: 1.0), // FF1493
        NSColor(red: 1.000, green: 0.431, blue: 0.780, alpha: 1.0), // FF6EC7
        NSColor(red: 0.490, green: 0.976, blue: 1.000, alpha: 1.0)  // 7DF9FF
    ])

    static let matrix = ColorDefinition(colors: [
        NSColor(red: 0.000, green: 1.000, blue: 0.000, alpha: 1.0), // 00FF00
        NSColor(red: 0.000, green: 0.800, blue: 0.000, alpha: 1.0), // 00CC00
        NSColor(red: 0.000, green: 0.600, blue: 0.000, alpha: 1.0), // 009900
        NSColor(red: 0.000, green: 1.000, blue: 0.000, alpha: 1.0), // 00FF00
        NSColor(red: 0.200, green: 1.000, blue: 0.200, alpha: 1.0)  // 33FF33
    ])

    static let monochrome = ColorDefinition(colors: [
        NSColor(red: 1.000, green: 1.000, blue: 1.000, alpha: 1.0), // FFFFFF
        NSColor(red: 0.800, green: 0.800, blue: 0.800, alpha: 1.0), // CCCCCC
        NSColor(red: 0.600, green: 0.600, blue: 0.600, alpha: 1.0), // 999999
        NSColor(red: 0.400, green: 0.400, blue: 0.400, alpha: 1.0), // 666666
        NSColor(red: 1.000, green: 1.000, blue: 1.000, alpha: 1.0)  // FFFFFF
    ])
}

// MARK: - Spiral Types

enum SpiralType: String {
    case archimedean, fermat, logarithmic, hyperbolic, lituus
    case fibonacci, theodorus, vogel, uzumaki, curlicue
}

// MARK: - Line Style

enum LineStyle: String {
    case solid, dashed, dotted, glow, points, triangles
}

// MARK: - Preset Definition (matching SpiralPreset.swift)

struct PresetDefinition {
    let id: String
    let name: String
    let type: SpiralType
    let tightness: Double
    let spinRate: Double
    let stepSize: Double
    let numSteps: Int
    let colors: ColorDefinition
    let lineStyle: LineStyle
    let zoom: Double
}

let presets: [PresetDefinition] = [
    PresetDefinition(id: "classic-golden", name: "Classic Golden", type: .fibonacci,
                     tightness: 3, spinRate: 0.3, stepSize: 0.1, numSteps: 500,
                     colors: .aurora, lineStyle: .glow, zoom: 1),
    PresetDefinition(id: "sunflower", name: "Sunflower", type: .vogel,
                     tightness: 2, spinRate: 0.1, stepSize: 0.1, numSteps: 1000,
                     colors: .sunset, lineStyle: .points, zoom: 2),
    PresetDefinition(id: "fractal-dance", name: "Fractal Dance", type: .curlicue,
                     tightness: 1, spinRate: 0.2, stepSize: 0.1, numSteps: 800,
                     colors: .neon, lineStyle: .solid, zoom: 10),
    PresetDefinition(id: "chaos", name: "Chaos", type: .uzumaki,
                     tightness: 5, spinRate: 0.5, stepSize: 0.1, numSteps: 600,
                     colors: .rainbow, lineStyle: .dashed, zoom: 1),
    PresetDefinition(id: "tight-archimedean", name: "Tight Archimedean", type: .archimedean,
                     tightness: 1, spinRate: 0.5, stepSize: 0.05, numSteps: 1000,
                     colors: .rainbow, lineStyle: .solid, zoom: 1),
    PresetDefinition(id: "hypnotic", name: "Hypnotic", type: .logarithmic,
                     tightness: 2, spinRate: 1, stepSize: 0.15, numSteps: 300,
                     colors: .candy, lineStyle: .glow, zoom: 1.5),
    PresetDefinition(id: "wheel-of-theodorus", name: "Wheel of Theodorus", type: .theodorus,
                     tightness: 5, spinRate: 0.2, stepSize: 0.1, numSteps: 50,
                     colors: .ocean, lineStyle: .triangles, zoom: 1),
    PresetDefinition(id: "trumpet", name: "Trumpet", type: .lituus,
                     tightness: 4, spinRate: 0.4, stepSize: 0.2, numSteps: 400,
                     colors: .retro, lineStyle: .dashed, zoom: 1),
    PresetDefinition(id: "matrix-rain", name: "Matrix Rain", type: .fermat,
                     tightness: 3, spinRate: 0.3, stepSize: 0.1, numSteps: 500,
                     colors: .matrix, lineStyle: .dotted, zoom: 5),
    PresetDefinition(id: "deep-space", name: "Deep Space", type: .hyperbolic,
                     tightness: 5, spinRate: 0.2, stepSize: 0.15, numSteps: 400,
                     colors: .monochrome, lineStyle: .glow, zoom: 1)
]

// MARK: - Spiral Point Generation

struct SpiralPoint {
    var x: Double
    var y: Double
}

func calculateRadius(theta: Double, type: SpiralType, tightness: Double, viewportScale: Double) -> Double {
    let a = tightness * viewportScale

    switch type {
    case .archimedean:
        return a * theta
    case .fibonacci:
        return a * pow(PHI, (2 * theta) / Double.pi) * 0.1
    case .fermat:
        return a * sqrt(abs(theta)) * 2
    case .logarithmic:
        return a * exp(0.1 * theta)
    case .hyperbolic:
        return theta > 0.1 ? (a * 50) / theta : a * 500
    case .lituus:
        return theta > 0.1 ? (a * 30) / sqrt(theta) : a * 100
    default:
        return a * theta
    }
}

func generatePolarSpiral(preset: PresetDefinition, time: Double, viewportScale: Double) -> [SpiralPoint] {
    var points: [SpiralPoint] = []
    let rotation = time * preset.spinRate

    for i in 0..<preset.numSteps {
        let baseTheta = Double(i) * preset.stepSize
        let theta = baseTheta + rotation
        let r = calculateRadius(theta: baseTheta, type: preset.type, tightness: preset.tightness, viewportScale: viewportScale)
        points.append(SpiralPoint(x: r * cos(theta), y: r * sin(theta)))
    }
    return points
}

func generateVogel(preset: PresetDefinition, time: Double, viewportScale: Double) -> [SpiralPoint] {
    var points: [SpiralPoint] = []
    let scale = preset.tightness * viewportScale
    let rotation = time * preset.spinRate

    for n in 0..<preset.numSteps {
        let theta = Double(n) * GOLDEN_ANGLE + rotation
        let r = scale * sqrt(Double(n)) * 2
        points.append(SpiralPoint(x: r * cos(theta), y: r * sin(theta)))
    }
    return points
}

func generateTheodorus(preset: PresetDefinition, time: Double, viewportScale: Double) -> [SpiralPoint] {
    var points: [SpiralPoint] = []
    let scale = preset.tightness * 3 * viewportScale
    let rotation = time * preset.spinRate

    var x = 0.0, y = 0.0, angle = rotation
    points.append(SpiralPoint(x: 0, y: 0))

    for n in 1...preset.numSteps {
        angle += atan(1 / sqrt(Double(n)))
        x += cos(angle)
        y += sin(angle)
        points.append(SpiralPoint(x: x * scale, y: y * scale))
    }
    return points
}

func generateUzumaki(preset: PresetDefinition, time: Double, viewportScale: Double) -> [SpiralPoint] {
    var points: [SpiralPoint] = []

    for n in 1...preset.numSteps {
        let nf = Double(n)
        let scale = pow(nf, 1.5) / (nf + 1000) * preset.tightness * 10 * viewportScale
        let angle = 0.1 * nf * sin(83.3333 * time * 0.01)
        let spiral = 0.1 * nf * time * 0.1
        points.append(SpiralPoint(x: scale * sin(angle + spiral), y: scale * cos(angle + spiral)))
    }
    return points
}

func generateCurlicue(preset: PresetDefinition, time: Double, viewportScale: Double) -> [SpiralPoint] {
    var points: [SpiralPoint] = []
    let segmentLength = preset.tightness * 0.5 * viewportScale
    let timeOffset = time * 0.1
    var x = 0.0, y = 0.0

    for n in 0..<preset.numSteps {
        points.append(SpiralPoint(x: x, y: y))
        let angle = 2 * Double.pi * PHI * Double(n * n) + timeOffset
        x += segmentLength * cos(angle)
        y += segmentLength * sin(angle)
    }
    return points
}

func generatePoints(preset: PresetDefinition, time: Double, viewportScale: Double) -> [SpiralPoint] {
    switch preset.type {
    case .vogel: return generateVogel(preset: preset, time: time, viewportScale: viewportScale)
    case .theodorus: return generateTheodorus(preset: preset, time: time, viewportScale: viewportScale)
    case .uzumaki: return generateUzumaki(preset: preset, time: time, viewportScale: viewportScale)
    case .curlicue: return generateCurlicue(preset: preset, time: time, viewportScale: viewportScale)
    default: return generatePolarSpiral(preset: preset, time: time, viewportScale: viewportScale)
    }
}

func applyZoom(points: inout [SpiralPoint], zoom: Double) {
    for i in 0..<points.count {
        points[i].x *= zoom
        points[i].y *= zoom
    }
}

// MARK: - Color Interpolation

func interpolateColor(colors: [NSColor], t: Double) -> NSColor {
    guard colors.count > 1 else { return colors.first ?? .white }
    let scaledT = t * Double(colors.count - 1)
    let index = Int(scaledT)
    let fraction = scaledT - Double(index)
    let fromColor = colors[min(index, colors.count - 1)]
    let toColor = colors[min(index + 1, colors.count - 1)]

    let fromRGB = fromColor.usingColorSpace(.sRGB) ?? fromColor
    let toRGB = toColor.usingColorSpace(.sRGB) ?? toColor

    return NSColor(
        red: fromRGB.redComponent + (toRGB.redComponent - fromRGB.redComponent) * fraction,
        green: fromRGB.greenComponent + (toRGB.greenComponent - fromRGB.greenComponent) * fraction,
        blue: fromRGB.blueComponent + (toRGB.blueComponent - fromRGB.blueComponent) * fraction,
        alpha: 1.0
    )
}

// MARK: - Drawing Functions

func drawPoints(points: [SpiralPoint], centerX: CGFloat, centerY: CGFloat, colors: [NSColor], scale: CGFloat) {
    let radius: CGFloat = 2.0 * scale
    for (i, point) in points.enumerated() {
        let t = Double(i) / Double(max(1, points.count - 1))
        let color = interpolateColor(colors: colors, t: t)
        let x = centerX + CGFloat(point.x)
        let y = centerY + CGFloat(point.y)

        color.setFill()
        NSBezierPath(ovalIn: NSRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)).fill()
    }
}

func drawTriangles(points: [SpiralPoint], centerX: CGFloat, centerY: CGFloat, colors: [NSColor], scale: CGFloat) {
    let origin = NSPoint(x: centerX, y: centerY)
    for i in 1..<points.count {
        let t = Double(i) / Double(max(1, points.count - 1))
        let color = interpolateColor(colors: colors, t: t)

        let path = NSBezierPath()
        path.move(to: origin)
        if i > 1 {
            path.line(to: NSPoint(x: centerX + CGFloat(points[i-1].x), y: centerY + CGFloat(points[i-1].y)))
        }
        path.line(to: NSPoint(x: centerX + CGFloat(points[i].x), y: centerY + CGFloat(points[i].y)))
        path.line(to: origin)

        color.setStroke()
        path.lineWidth = 1.5 * scale
        path.stroke()
    }
}

func drawSolidSpiral(points: [SpiralPoint], centerX: CGFloat, centerY: CGFloat, colors: [NSColor], scale: CGFloat) {
    guard points.count > 1 else { return }
    for i in 0..<(points.count - 1) {
        let t = Double(i) / Double(max(1, points.count - 1))
        let color = interpolateColor(colors: colors, t: t)

        let path = NSBezierPath()
        path.move(to: NSPoint(x: centerX + CGFloat(points[i].x), y: centerY + CGFloat(points[i].y)))
        path.line(to: NSPoint(x: centerX + CGFloat(points[i+1].x), y: centerY + CGFloat(points[i+1].y)))
        path.lineWidth = 2.0 * scale
        path.lineCapStyle = .round
        color.setStroke()
        path.stroke()
    }
}

func drawGlowSpiral(points: [SpiralPoint], centerX: CGFloat, centerY: CGFloat, colors: [NSColor], scale: CGFloat) {
    guard points.count > 1 else { return }

    // Draw glow layers
    for (glowWidth, opacity) in [(12.0, 0.08), (8.0, 0.12), (5.0, 0.18)] as [(CGFloat, CGFloat)] {
        for i in 0..<(points.count - 1) {
            let t = Double(i) / Double(max(1, points.count - 1))
            let color = interpolateColor(colors: colors, t: t).withAlphaComponent(opacity)

            let path = NSBezierPath()
            path.move(to: NSPoint(x: centerX + CGFloat(points[i].x), y: centerY + CGFloat(points[i].y)))
            path.line(to: NSPoint(x: centerX + CGFloat(points[i+1].x), y: centerY + CGFloat(points[i+1].y)))
            path.lineWidth = glowWidth * scale
            path.lineCapStyle = .round
            color.setStroke()
            path.stroke()
        }
    }

    // Draw main line
    drawSolidSpiral(points: points, centerX: centerX, centerY: centerY, colors: colors, scale: scale)
}

func drawDashedSpiral(points: [SpiralPoint], centerX: CGFloat, centerY: CGFloat, colors: [NSColor], scale: CGFloat) {
    guard points.count > 1 else { return }
    let dashPattern: [CGFloat] = [8.0 * scale, 4.0 * scale]

    for i in stride(from: 0, to: points.count - 1, by: 3) {
        let t = Double(i) / Double(max(1, points.count - 1))
        let color = interpolateColor(colors: colors, t: t)
        let endIdx = min(i + 3, points.count - 1)

        let path = NSBezierPath()
        path.move(to: NSPoint(x: centerX + CGFloat(points[i].x), y: centerY + CGFloat(points[i].y)))
        for j in (i+1)...endIdx {
            path.line(to: NSPoint(x: centerX + CGFloat(points[j].x), y: centerY + CGFloat(points[j].y)))
        }
        path.lineWidth = 2.0 * scale
        path.lineCapStyle = .round
        path.setLineDash(dashPattern, count: 2, phase: 0)
        color.setStroke()
        path.stroke()
    }
}

func drawDottedSpiral(points: [SpiralPoint], centerX: CGFloat, centerY: CGFloat, colors: [NSColor], scale: CGFloat) {
    let radius: CGFloat = 1.5 * scale
    for (i, point) in points.enumerated() {
        let t = Double(i) / Double(max(1, points.count - 1))
        let color = interpolateColor(colors: colors, t: t)
        let x = centerX + CGFloat(point.x)
        let y = centerY + CGFloat(point.y)

        color.setFill()
        NSBezierPath(ovalIn: NSRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)).fill()
    }
}

// MARK: - Text Rendering

func drawPresetName(name: String, in rect: NSRect, scale: CGFloat) {
    let fontSize = 24.0 * scale
    let font = NSFont.systemFont(ofSize: fontSize, weight: .semibold)

    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .center

    // Draw text shadow for better readability
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.8)
    shadow.shadowOffset = NSSize(width: 0, height: -1 * scale)
    shadow.shadowBlurRadius = 4 * scale

    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.white.withAlphaComponent(0.95),
        .paragraphStyle: paragraphStyle,
        .shadow: shadow
    ]

    // Position text at the bottom with padding
    let bottomPadding = 30.0 * scale
    let textHeight = 40.0 * scale
    let textRect = NSRect(
        x: 0,
        y: bottomPadding,
        width: rect.width,
        height: textHeight
    )

    name.draw(in: textRect, withAttributes: attributes)
}

// MARK: - Image Generation

func createPreviewImage(preset: PresetDefinition, width: Int, height: Int) -> NSImage {
    let image = NSImage(size: NSSize(width: width, height: height))
    image.lockFocus()

    let rect = NSRect(x: 0, y: 0, width: width, height: height)

    // Draw background
    bgColor.setFill()
    rect.fill()

    // Calculate viewport scale for this image size
    let viewportScale = Double(min(width, height)) / 800.0
    let drawScale = CGFloat(width) / CGFloat(posterWidth)

    // Generate spiral points
    var points = generatePoints(preset: preset, time: 2.0, viewportScale: viewportScale)
    applyZoom(points: &points, zoom: preset.zoom)

    let centerX = CGFloat(width) / 2
    let centerY = CGFloat(height) / 2 + CGFloat(height) * 0.05  // Shift up slightly for text
    let colors = preset.colors.colors

    // Draw based on line style
    switch preset.lineStyle {
    case .points:
        drawPoints(points: points, centerX: centerX, centerY: centerY, colors: colors, scale: drawScale)
    case .triangles:
        drawTriangles(points: points, centerX: centerX, centerY: centerY, colors: colors, scale: drawScale)
    case .glow:
        drawGlowSpiral(points: points, centerX: centerX, centerY: centerY, colors: colors, scale: drawScale)
    case .dashed:
        drawDashedSpiral(points: points, centerX: centerX, centerY: centerY, colors: colors, scale: drawScale)
    case .dotted:
        drawDottedSpiral(points: points, centerX: centerX, centerY: centerY, colors: colors, scale: drawScale)
    case .solid:
        drawSolidSpiral(points: points, centerX: centerX, centerY: centerY, colors: colors, scale: drawScale)
    }

    // Draw preset name at the bottom
    drawPresetName(name: preset.name, in: rect, scale: drawScale)

    image.unlockFocus()
    return image
}

// MARK: - PNG Saving

func savePNG(image: NSImage, to url: URL, pixelWidth: Int, pixelHeight: Int) {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelWidth,
        pixelsHigh: pixelHeight,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
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

    image.draw(in: NSRect(x: 0, y: 0, width: pixelWidth, height: pixelHeight),
               from: NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height),
               operation: .copy, fraction: 1.0)

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

// MARK: - Main

let fileManager = FileManager.default
let scriptURL = URL(fileURLWithPath: #file)
let projectRoot = scriptURL.deletingLastPathComponent().deletingLastPathComponent()
let outputPath = projectRoot.appendingPathComponent("Uzumaki/TopShelfExtension/Resources")

print("Generating Top Shelf preview images...")
print("Output: \(outputPath.path)")
print("Resolution: \(posterWidth)x\(posterHeight) (1x and 2x)")
print("")

// Create output directory
try? fileManager.createDirectory(at: outputPath, withIntermediateDirectories: true)

// Generate images for each preset at 1x and 2x
for preset in presets {
    // 1x
    let image1x = createPreviewImage(preset: preset, width: posterWidth, height: posterHeight)
    savePNG(image: image1x, to: outputPath.appendingPathComponent("topshelf-\(preset.id).png"),
            pixelWidth: posterWidth, pixelHeight: posterHeight)

    // 2x
    let image2x = createPreviewImage(preset: preset, width: posterWidth * 2, height: posterHeight * 2)
    savePNG(image: image2x, to: outputPath.appendingPathComponent("topshelf-\(preset.id)@2x.png"),
            pixelWidth: posterWidth * 2, pixelHeight: posterHeight * 2)

    print("  Generated: \(preset.name)")
}

print("")
print("Done! Top Shelf preview images generated at: \(outputPath.path)")

