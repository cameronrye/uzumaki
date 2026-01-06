import SwiftUI
import UzumakiCore

/// SwiftUI Canvas view for rendering spirals
public struct SpiralCanvasView: View {
    @Bindable var viewModel: SpiralViewModel

    public init(viewModel: SpiralViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        TimelineView(.animation(paused: viewModel.isPaused)) { timeline in
            Canvas { context, size in
                // Update animation time
                _ = timeline.date

                // Generate points
                let points = viewModel.spiralPoints
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
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
                        performanceMode: viewModel.performanceMode,
                        glowOnly: true
                    )
                default:
                    // Draw glow first (unless performance mode)
                    if !viewModel.performanceMode {
                        SpiralRenderer.drawGlow(
                            context: context,
                            points: points,
                            center: center,
                            glowColor: viewModel.glowColor,
                            performanceMode: viewModel.performanceMode,
                            glowOnly: false
                        )
                    }
                    SpiralRenderer.drawLine(
                        context: context,
                        points: points,
                        center: center,
                        colors: colors,
                        lineStyle: viewModel.lineStyle
                    )
                }
            }
            .onChange(of: timeline.date) { oldValue, newValue in
                let delta = newValue.timeIntervalSince(oldValue)
                viewModel.incrementTime(delta: delta)
            }
        }
        .background(viewModel.backgroundColor)
    }
}

