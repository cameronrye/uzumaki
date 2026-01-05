import SwiftUI
import UniformTypeIdentifiers
import UzumakiCore
#if canImport(UIKit)
import UIKit
import Photos
#endif

/// Handles exporting spiral canvas as images
@MainActor
public struct ExportManager {

    /// Export the current spiral as a PNG image
    @available(macOS 14.0, iOS 17.0, *)
    public static func exportAsPNG(
        viewModel: SpiralViewModel,
        size: CGSize = CGSize(width: 2048, height: 2048)
    ) async -> Data? {
        let renderer = ImageRenderer(content: ExportableCanvas(viewModel: viewModel, size: size))
        renderer.scale = 2.0  // Retina

        #if os(macOS)
        guard let nsImage = renderer.nsImage else { return nil }
        guard let tiffData = nsImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else { return nil }
        return bitmap.representation(using: .png, properties: [:])
        #else
        guard let uiImage = renderer.uiImage else { return nil }
        return uiImage.pngData()
        #endif
    }

    /// Save PNG to the user's chosen location (macOS)
    #if os(macOS)
    public static func savePNG(data: Data, filename: String = "uzumaki-spiral.png") {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png]
        savePanel.nameFieldStringValue = filename
        savePanel.canCreateDirectories = true

        savePanel.begin { result in
            if result == .OK, let url = savePanel.url {
                do {
                    try data.write(to: url)
                } catch {
                    print("Failed to save: \(error)")
                }
            }
        }
    }
    #endif

    /// Save PNG to Photos library (iOS)
    #if os(iOS)
    public static func saveToPhotos(data: Data) async -> Bool {
        guard let image = UIImage(data: data) else { return false }

        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                guard status == .authorized || status == .limited else {
                    continuation.resume(returning: false)
                    return
                }

                PHPhotoLibrary.shared().performChanges {
                    PHAssetCreationRequest.creationRequestForAsset(from: image)
                } completionHandler: { success, error in
                    if let error = error {
                        print("Failed to save to Photos: \(error)")
                    }
                    continuation.resume(returning: success)
                }
            }
        }
    }

    /// Share PNG using system share sheet (iOS)
    public static func share(data: Data, from sourceView: UIView? = nil) {
        guard let image = UIImage(data: data) else { return }

        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )

        // Get the key window scene
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            return
        }

        // iPad requires popover presentation
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = sourceView ?? rootVC.view
            popover.sourceRect = sourceView?.bounds ?? CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
        }

        rootVC.present(activityVC, animated: true)
    }
    #endif
}

// MARK: - Exportable Canvas View

/// A view designed for high-quality export rendering
struct ExportableCanvas: View {
    let viewModel: SpiralViewModel
    let size: CGSize
    
    var body: some View {
        Canvas { context, canvasSize in
            let points = viewModel.spiralPoints
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            
            // Draw based on line style (simplified for export)
            switch viewModel.lineStyle {
            case .points:
                drawPoints(context: context, points: points, center: center)
            case .triangles:
                drawTriangles(context: context, points: points, center: center)
            case .glow:
                drawGlow(context: context, points: points, center: center, glowOnly: true)
            default:
                drawGlow(context: context, points: points, center: center, glowOnly: false)
                drawLine(context: context, points: points, center: center)
            }
        }
        .frame(width: size.width, height: size.height)
        .background(viewModel.backgroundColor)
    }
    
    private func drawLine(context: GraphicsContext, points: SpiralPoints, center: CGPoint) {
        guard points.count > 1 else { return }
        
        var path = Path()
        path.move(to: CGPoint(x: center.x + CGFloat(points.x(at: 0)), y: center.y + CGFloat(points.y(at: 0))))
        for i in 1..<points.count {
            path.addLine(to: CGPoint(x: center.x + CGFloat(points.x(at: i)), y: center.y + CGFloat(points.y(at: i))))
        }
        
        let gradient = Gradient(colors: viewModel.colors)
        var strokeStyle = StrokeStyle(lineWidth: Constants.lineWidthDefault, lineCap: .round, lineJoin: .round)
        strokeStyle.dash = viewModel.lineStyle.dashPattern
        
        context.stroke(path, with: .linearGradient(
            gradient,
            startPoint: CGPoint(x: center.x - 200, y: center.y - 200),
            endPoint: CGPoint(x: center.x + 200, y: center.y + 200)
        ), style: strokeStyle)
    }
    
    private func drawPoints(context: GraphicsContext, points: SpiralPoints, center: CGPoint) {
        let colors = viewModel.colors
        let pointRadius = max(Constants.pointRadiusMin, Constants.pointRadiusBase * viewModel.zoom)
        
        for i in 0..<points.count {
            let progress = Double(i) / Double(points.count)
            let colorIndex = Int(progress * Double(colors.count - 1))
            let color = colors[min(colorIndex, colors.count - 1)]
            let point = CGPoint(x: center.x + CGFloat(points.x(at: i)), y: center.y + CGFloat(points.y(at: i)))
            let rect = CGRect(x: point.x - pointRadius, y: point.y - pointRadius, width: pointRadius * 2, height: pointRadius * 2)
            context.fill(Circle().path(in: rect), with: .color(color))
        }
    }
    
    private func drawTriangles(context: GraphicsContext, points: SpiralPoints, center: CGPoint) {
        guard points.count > 1 else { return }
        let colors = viewModel.colors
        let origin = CGPoint(x: center.x + CGFloat(points.x(at: 0)), y: center.y + CGFloat(points.y(at: 0)))
        
        for i in 1..<points.count {
            let progress = Double(i) / Double(points.count)
            let colorIndex = Int(progress * Double(colors.count - 1))
            let color = colors[min(colorIndex, colors.count - 1)]
            
            var path = Path()
            path.move(to: origin)
            if i > 1 { path.addLine(to: CGPoint(x: center.x + CGFloat(points.x(at: i - 1)), y: center.y + CGFloat(points.y(at: i - 1)))) }
            path.addLine(to: CGPoint(x: center.x + CGFloat(points.x(at: i)), y: center.y + CGFloat(points.y(at: i))))
            path.addLine(to: origin)
            
            context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: Constants.lineWidthTriangles, lineCap: .round, lineJoin: .round))
        }
    }
    
    private func drawGlow(context: GraphicsContext, points: SpiralPoints, center: CGPoint, glowOnly: Bool) {
        guard points.count > 1 else { return }
        var path = Path()
        path.move(to: CGPoint(x: center.x + CGFloat(points.x(at: 0)), y: center.y + CGFloat(points.y(at: 0))))
        for i in 1..<points.count { path.addLine(to: CGPoint(x: center.x + CGFloat(points.x(at: i)), y: center.y + CGFloat(points.y(at: i)))) }
        
        let glowColor = viewModel.glowColor
        for layer in Constants.glowLayersNormal {
            let opacity = glowOnly ? layer.opacity * 2 : layer.opacity
            let width = glowOnly ? layer.width * 1.5 : layer.width
            context.stroke(path, with: .color(glowColor.opacity(opacity)), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
        }
    }
}

