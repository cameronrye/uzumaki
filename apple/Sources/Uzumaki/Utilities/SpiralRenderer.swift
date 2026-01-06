import SwiftUI
import UzumakiCore

/// Shared rendering utilities for drawing spirals on Canvas contexts
public enum SpiralRenderer {
    
    /// Creates a Path from spiral points centered at the given point
    public static func createPath(points: SpiralPoints, center: CGPoint) -> Path {
        var path = Path()
        guard points.count > 0 else { return path }
        
        path.move(to: CGPoint(
            x: center.x + CGFloat(points.x(at: 0)),
            y: center.y + CGFloat(points.y(at: 0))
        ))
        
        for i in 1..<points.count {
            path.addLine(to: CGPoint(
                x: center.x + CGFloat(points.x(at: i)),
                y: center.y + CGFloat(points.y(at: i))
            ))
        }
        
        return path
    }
    
    /// Draw spiral as a gradient line
    public static func drawLine(
        context: GraphicsContext,
        points: SpiralPoints,
        center: CGPoint,
        colors: [Color],
        lineStyle: LineStyle
    ) {
        guard points.count > 1 else { return }
        
        let path = createPath(points: points, center: center)
        let gradient = Gradient(colors: colors)
        
        var strokeStyle = StrokeStyle(
            lineWidth: Constants.lineWidthDefault,
            lineCap: .round,
            lineJoin: .round
        )
        
        let dash = lineStyle.dashPattern
        if !dash.isEmpty {
            strokeStyle.dash = dash
        }
        
        context.stroke(path, with: .linearGradient(
            gradient,
            startPoint: CGPoint(x: center.x - 200, y: center.y - 200),
            endPoint: CGPoint(x: center.x + 200, y: center.y + 200)
        ), style: strokeStyle)
    }
    
    /// Draw spiral as individual colored points
    public static func drawPoints(
        context: GraphicsContext,
        points: SpiralPoints,
        center: CGPoint,
        colors: [Color],
        zoom: Double
    ) {
        let pointRadius = max(Constants.pointRadiusMin, Constants.pointRadiusBase * zoom)
        
        for i in 0..<points.count {
            let progress = Double(i) / Double(max(1, points.count - 1))
            let colorIndex = Int(progress * Double(colors.count - 1))
            let color = colors[min(colorIndex, colors.count - 1)]
            
            let point = CGPoint(
                x: center.x + CGFloat(points.x(at: i)),
                y: center.y + CGFloat(points.y(at: i))
            )
            
            let rect = CGRect(
                x: point.x - pointRadius,
                y: point.y - pointRadius,
                width: pointRadius * 2,
                height: pointRadius * 2
            )
            
            context.fill(Circle().path(in: rect), with: .color(color))
        }
    }
    
    /// Draw spiral as triangles emanating from origin
    public static func drawTriangles(
        context: GraphicsContext,
        points: SpiralPoints,
        center: CGPoint,
        colors: [Color]
    ) {
        guard points.count > 1 else { return }
        
        let origin = CGPoint(
            x: center.x + CGFloat(points.x(at: 0)),
            y: center.y + CGFloat(points.y(at: 0))
        )
        
        for i in 1..<points.count {
            let progress = Double(i) / Double(points.count)
            let colorIndex = Int(progress * Double(colors.count - 1))
            let color = colors[min(colorIndex, colors.count - 1)]
            
            var path = Path()
            path.move(to: origin)
            
            if i > 1 {
                path.addLine(to: CGPoint(
                    x: center.x + CGFloat(points.x(at: i - 1)),
                    y: center.y + CGFloat(points.y(at: i - 1))
                ))
            }
            
            path.addLine(to: CGPoint(
                x: center.x + CGFloat(points.x(at: i)),
                y: center.y + CGFloat(points.y(at: i))
            ))
            path.addLine(to: origin)
            
            context.stroke(path, with: .color(color), style: StrokeStyle(
                lineWidth: Constants.lineWidthTriangles,
                lineCap: .round,
                lineJoin: .round
            ))
        }
    }

    /// Draw glow effect around the spiral path
    public static func drawGlow(
        context: GraphicsContext,
        points: SpiralPoints,
        center: CGPoint,
        glowColor: Color,
        performanceMode: Bool,
        glowOnly: Bool
    ) {
        guard points.count > 1 else { return }

        let path = createPath(points: points, center: center)
        let layers = performanceMode
            ? Constants.glowLayersPerformance
            : Constants.glowLayersNormal

        for layer in layers {
            let opacity = glowOnly ? layer.opacity * 2 : layer.opacity
            let width = glowOnly ? layer.width * 1.5 : layer.width

            context.stroke(path, with: .color(glowColor.opacity(opacity)), style: StrokeStyle(
                lineWidth: width,
                lineCap: .round,
                lineJoin: .round
            ))
        }
    }
}

