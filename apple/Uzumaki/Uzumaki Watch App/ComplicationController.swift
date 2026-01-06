//
//  ComplicationController.swift
//  Uzumaki Watch App
//
//  Provides complications for the watch face that launch the app.
//  Note: To enable complications, add a Widget Extension target to the project
//  and use the SpiralComplicationBundle as the entry point.
//

import WidgetKit
import SwiftUI

// MARK: - Complication Entry

/// Complication entry for the spiral widget
struct SpiralComplicationEntry: TimelineEntry {
    let date: Date
}

// MARK: - Timeline Provider

/// Provider for spiral complication timeline
struct SpiralComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> SpiralComplicationEntry {
        SpiralComplicationEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SpiralComplicationEntry) -> Void) {
        completion(SpiralComplicationEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SpiralComplicationEntry>) -> Void) {
        // Static complication - just needs one entry
        let entry = SpiralComplicationEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

// MARK: - Complication Views

/// Spiral logo view for circular complications
struct SpiralCircularView: View {
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let scale = min(size.width, size.height) / 28

                var path = Path()
                path.move(to: CGPoint(x: center.x, y: center.y))

                // Simple spiral curve
                path.addCurve(
                    to: CGPoint(x: center.x - 5 * scale, y: center.y + 2 * scale),
                    control1: CGPoint(x: center.x - 2 * scale, y: center.y - 2.5 * scale),
                    control2: CGPoint(x: center.x - 5 * scale, y: center.y - 2.5 * scale)
                )

                path.addCurve(
                    to: CGPoint(x: center.x, y: center.y + 7 * scale),
                    control1: CGPoint(x: center.x - 5 * scale, y: center.y + 5 * scale),
                    control2: CGPoint(x: center.x - 3 * scale, y: center.y + 7 * scale)
                )

                path.addCurve(
                    to: CGPoint(x: center.x + 7 * scale, y: center.y - 2 * scale),
                    control1: CGPoint(x: center.x + 4 * scale, y: center.y + 7 * scale),
                    control2: CGPoint(x: center.x + 7 * scale, y: center.y + 3 * scale)
                )

                context.stroke(
                    path,
                    with: .color(.white),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )
            }
        }
        .widgetAccentable()
    }
}

/// Inline text complication view
struct SpiralInlineView: View {
    var body: some View {
        Label("Uzumaki", systemImage: "hurricane")
    }
}

/// Rectangular complication view
struct SpiralRectangularView: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "hurricane")
                .font(.title2)
                .widgetAccentable()
            VStack(alignment: .leading, spacing: 2) {
                Text("Uzumaki")
                    .font(.headline)
                Text("Spiral Visualizer")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}

/// Corner complication view
struct SpiralCornerView: View {
    var body: some View {
        Image(systemName: "hurricane")
            .font(.title3)
            .widgetAccentable()
    }
}

// MARK: - Widget Configuration

/// Widget configuration for the spiral complication
struct SpiralComplication: Widget {
    let kind: String = "SpiralComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SpiralComplicationProvider()) { _ in
            SpiralComplicationEntryView()
        }
        .configurationDisplayName("Uzumaki")
        .description("Launch the spiral visualizer")
        #if os(watchOS)
        .supportedFamilies([
            .accessoryCircular,
            .accessoryCorner,
            .accessoryRectangular,
            .accessoryInline
        ])
        #endif
    }
}

/// Entry view that adapts to the widget family
struct SpiralComplicationEntryView: View {
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            SpiralCircularView()
        case .accessoryInline:
            SpiralInlineView()
        case .accessoryRectangular:
            SpiralRectangularView()
        case .accessoryCorner:
            SpiralCornerView()
        default:
            SpiralCircularView()
        }
    }
}

// MARK: - Widget Bundle

/// Widget bundle for complications - use this as entry point for Widget Extension
struct SpiralComplicationBundle: WidgetBundle {
    var body: some Widget {
        SpiralComplication()
    }
}

