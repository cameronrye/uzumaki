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

    /// Share PNG using system share sheet (macOS)
    public static func share(data: Data, from view: NSView? = nil) {
        guard let image = NSImage(data: data) else { return }

        // Get the key window and a view to anchor the picker
        guard let window = NSApp.keyWindow,
              let contentView = view ?? window.contentView else {
            return
        }

        let picker = NSSharingServicePicker(items: [image])

        // Show picker anchored to center of the view
        let rect = CGRect(
            x: contentView.bounds.midX,
            y: contentView.bounds.midY,
            width: 1,
            height: 1
        )
        picker.show(relativeTo: rect, of: contentView, preferredEdge: .minY)
    }
    #endif

    /// Result of a save to photos operation
    public enum SaveResult {
        case success
        case permissionDenied
        case failed(Error?)
    }

    /// Save PNG to Photos library (iOS)
    #if os(iOS)
    public static func saveToPhotos(data: Data) async -> SaveResult {
        guard let image = UIImage(data: data) else { return .failed(nil) }

        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                guard status == .authorized || status == .limited else {
                    continuation.resume(returning: .permissionDenied)
                    return
                }

                PHPhotoLibrary.shared().performChanges {
                    PHAssetCreationRequest.creationRequestForAsset(from: image)
                } completionHandler: { success, error in
                    if success {
                        continuation.resume(returning: .success)
                    } else {
                        continuation.resume(returning: .failed(error))
                    }
                }
            }
        }
    }

    /// Open the Settings app to the app's settings page
    public static func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
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
            let colors = viewModel.colors

            // Draw based on line style using shared renderer
            switch viewModel.lineStyle {
            case .points:
                SpiralRenderer.drawPoints(
                    context: context,
                    points: points,
                    center: center,
                    colors: colors,
                    zoom: viewModel.zoom
                )
            case .triangles:
                SpiralRenderer.drawTriangles(
                    context: context,
                    points: points,
                    center: center,
                    colors: colors
                )
            case .glow:
                SpiralRenderer.drawGlow(
                    context: context,
                    points: points,
                    center: center,
                    glowColor: viewModel.glowColor,
                    performanceMode: false,
                    glowOnly: true
                )
            default:
                SpiralRenderer.drawGlow(
                    context: context,
                    points: points,
                    center: center,
                    glowColor: viewModel.glowColor,
                    performanceMode: false,
                    glowOnly: false
                )
                SpiralRenderer.drawLine(
                    context: context,
                    points: points,
                    center: center,
                    colors: colors,
                    lineStyle: viewModel.lineStyle
                )
            }
        }
        .frame(width: size.width, height: size.height)
        .background(viewModel.backgroundColor)
    }
}

