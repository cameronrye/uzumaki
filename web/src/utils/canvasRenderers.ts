import {
  GLOW_LAYERS_NORMAL,
  GLOW_LAYERS_PERFORMANCE,
  LINE_WIDTH_DEFAULT,
  LINE_WIDTH_TRIANGLES,
  LINE_WIDTH_TRIANGLES_OUTER,
  POINT_RADIUS_MIN,
  POINT_RADIUS_BASE,
  THICKNESS_VARIATION_BUCKETS,
  THICKNESS_VARIATION_BASE,
  THICKNESS_VARIATION_RANGE,
  LINE_DASH_PATTERNS,
} from './constants';
import { TypedSpiralPoints, getX, getY } from './spiralTypedArrays';

// Re-export SpiralPoint for backward compatibility
export interface SpiralPoint {
  x: number;
  y: number;
}

/**
 * Unified point accessor interface for rendering functions.
 * Allows rendering code to work with both SpiralPoint[] and TypedSpiralPoints.
 */
export interface PointAccessor {
  length: number;
  getX(index: number): number;
  getY(index: number): number;
}

/**
 * Create a PointAccessor from a SpiralPoint array
 */
export function fromPointArray(points: SpiralPoint[]): PointAccessor {
  return {
    length: points.length,
    getX: (i: number) => points[i]?.x ?? 0,
    getY: (i: number) => points[i]?.y ?? 0,
  };
}

/**
 * Create a PointAccessor from TypedSpiralPoints
 */
export function fromTypedPoints(points: TypedSpiralPoints): PointAccessor {
  return {
    length: points.length,
    getX: (i: number) => getX(points, i),
    getY: (i: number) => getY(points, i),
  };
}

// Canvas context type that works with both regular and offscreen canvas
type AnyCanvasContext = CanvasRenderingContext2D | OffscreenCanvasRenderingContext2D;

export interface RenderContext<T extends AnyCanvasContext = CanvasRenderingContext2D> {
  ctx: T;
  centerX: number;
  centerY: number;
  points: PointAccessor;
  colors: string[];
  gradient: CanvasGradient;
  zoom: number;
  isPerformanceMode: boolean;
  hasThicknessVariation: boolean;
}

// Draw triangles from center (ideal for Theodorus spiral)
export function drawTriangles<T extends AnyCanvasContext>(context: RenderContext<T>): void {
  const { ctx, centerX, centerY, points, colors } = context;

  ctx.globalAlpha = 1;
  ctx.lineWidth = LINE_WIDTH_TRIANGLES;
  ctx.lineCap = 'round';
  ctx.lineJoin = 'round';

  // First point is the center for Theodorus spiral
  const originX = centerX + points.getX(0);
  const originY = centerY + points.getY(0);

  for (let i = 1; i < points.length; i++) {
    const progress = i / points.length;
    const colorIndex = Math.floor(progress * (colors.length - 1));
    ctx.strokeStyle = colors[colorIndex] ?? colors[0] ?? '#ffffff';

    // Draw triangle: center -> previous point -> current point -> center
    ctx.beginPath();
    ctx.moveTo(originX, originY);
    if (i > 1) {
      ctx.lineTo(centerX + points.getX(i - 1), centerY + points.getY(i - 1));
    }
    ctx.lineTo(centerX + points.getX(i), centerY + points.getY(i));
    ctx.lineTo(originX, originY);
    ctx.stroke();
  }

  // Draw hypotenuse markers (the outer edge)
  ctx.strokeStyle = colors[0] ?? '#ffffff';
  ctx.lineWidth = LINE_WIDTH_TRIANGLES_OUTER;
  ctx.beginPath();
  if (points.length > 1) {
    ctx.moveTo(centerX + points.getX(1), centerY + points.getY(1));
    for (let i = 2; i < points.length; i++) {
      ctx.lineTo(centerX + points.getX(i), centerY + points.getY(i));
    }
  }
  ctx.stroke();
}

// Draw discrete circles (ideal for Vogel/phyllotaxis patterns) - non-batched version
export function drawPoints<T extends AnyCanvasContext>(context: RenderContext<T>): void {
  const { ctx, centerX, centerY, points, colors, zoom } = context;

  ctx.globalAlpha = 1;
  const pointRadius = Math.max(POINT_RADIUS_MIN, POINT_RADIUS_BASE * zoom);

  for (let i = 0; i < points.length; i++) {
    const progress = i / points.length;
    const colorIndex = Math.floor(progress * (colors.length - 1));
    const nextColorIndex = Math.min(colorIndex + 1, colors.length - 1);
    const colorProgress = (progress * (colors.length - 1)) % 1;

    // Interpolate between colors for smooth gradient
    ctx.fillStyle = colors[colorIndex] ?? '#ffffff';
    if (colorProgress > 0 && colorIndex !== nextColorIndex) {
      ctx.fillStyle = colors[nextColorIndex] ?? '#ffffff';
    }

    ctx.beginPath();
    ctx.arc(centerX + points.getX(i), centerY + points.getY(i), pointRadius, 0, Math.PI * 2);
    ctx.fill();
  }
}

// Draw points with batched rendering by color - more efficient
export function drawPointsBatched<T extends AnyCanvasContext>(context: RenderContext<T>): void {
  const { ctx, centerX, centerY, points, colors, zoom } = context;

  ctx.globalAlpha = 1;
  const pointRadius = Math.max(POINT_RADIUS_MIN, POINT_RADIUS_BASE * zoom);
  const numColors = colors.length;
  const pointsPerColor = Math.ceil(points.length / numColors);

  for (let colorIdx = 0; colorIdx < numColors; colorIdx++) {
    ctx.fillStyle = colors[colorIdx] ?? '#ffffff';
    ctx.beginPath();

    const startIdx = colorIdx * pointsPerColor;
    const endIdx = Math.min((colorIdx + 1) * pointsPerColor, points.length);

    for (let i = startIdx; i < endIdx; i++) {
      const x = centerX + points.getX(i);
      const y = centerY + points.getY(i);
      ctx.moveTo(x + pointRadius, y);
      ctx.arc(x, y, pointRadius, 0, Math.PI * 2);
    }

    ctx.fill();
  }
}

// Draw triangles with batched rendering by color - more efficient
export function drawTrianglesBatched<T extends AnyCanvasContext>(context: RenderContext<T>): void {
  const { ctx, centerX, centerY, points, colors } = context;

  ctx.globalAlpha = 1;
  ctx.lineWidth = LINE_WIDTH_TRIANGLES;
  ctx.lineCap = 'round';
  ctx.lineJoin = 'round';

  const originX = centerX + points.getX(0);
  const originY = centerY + points.getY(0);
  const numColors = colors.length;
  const trianglesPerColor = Math.ceil((points.length - 1) / numColors);

  // Batch triangles by color
  for (let colorIdx = 0; colorIdx < numColors; colorIdx++) {
    ctx.strokeStyle = colors[colorIdx] ?? '#ffffff';
    ctx.beginPath();

    const startIdx = colorIdx * trianglesPerColor + 1;
    const endIdx = Math.min((colorIdx + 1) * trianglesPerColor + 1, points.length);

    for (let i = startIdx; i < endIdx; i++) {
      ctx.moveTo(originX, originY);
      if (i > 1) {
        ctx.lineTo(centerX + points.getX(i - 1), centerY + points.getY(i - 1));
      }
      ctx.lineTo(centerX + points.getX(i), centerY + points.getY(i));
      ctx.lineTo(originX, originY);
    }

    ctx.stroke();
  }

  // Draw outer edge
  ctx.strokeStyle = colors[0] ?? '#ffffff';
  ctx.lineWidth = LINE_WIDTH_TRIANGLES_OUTER;
  ctx.beginPath();
  if (points.length > 1) {
    ctx.moveTo(centerX + points.getX(1), centerY + points.getY(1));
    for (let i = 2; i < points.length; i++) {
      ctx.lineTo(centerX + points.getX(i), centerY + points.getY(i));
    }
  }
  ctx.stroke();
}

// Draw glow effect layers
export function drawGlow<T extends AnyCanvasContext>(context: RenderContext<T>, isGlowOnly: boolean): void {
  const { ctx, centerX, centerY, points, colors, isPerformanceMode } = context;

  const glowColor = colors[2] ?? colors[0] ?? '#ffffff';
  const glowLayers = isPerformanceMode ? GLOW_LAYERS_PERFORMANCE : GLOW_LAYERS_NORMAL;

  for (const layer of glowLayers) {
    ctx.beginPath();
    ctx.moveTo(centerX + points.getX(0), centerY + points.getY(0));
    for (let i = 1; i < points.length; i++) {
      ctx.lineTo(centerX + points.getX(i), centerY + points.getY(i));
    }
    ctx.strokeStyle = glowColor;
    ctx.globalAlpha = isGlowOnly ? layer.opacity * 2 : layer.opacity;
    ctx.lineWidth = isGlowOnly ? layer.width * 1.5 : layer.width;
    ctx.stroke();
  }
  ctx.globalAlpha = 1;
}

// Draw main spiral line with optional thickness variation
export function drawLine<T extends AnyCanvasContext>(context: RenderContext<T>): void {
  const { ctx, centerX, centerY, points, gradient, hasThicknessVariation } = context;

  ctx.globalAlpha = 1;
  ctx.strokeStyle = gradient;

  if (hasThicknessVariation) {
    // Batch similar widths to reduce draw calls
    const segmentsPerBucket = Math.ceil(points.length / THICKNESS_VARIATION_BUCKETS);

    for (let bucket = 0; bucket < THICKNESS_VARIATION_BUCKETS; bucket++) {
      const startIdx = bucket * segmentsPerBucket;
      const endIdx = Math.min((bucket + 1) * segmentsPerBucket, points.length);
      const midProgress = (startIdx + endIdx) / 2 / points.length;

      ctx.beginPath();
      ctx.lineWidth = THICKNESS_VARIATION_BASE + midProgress * THICKNESS_VARIATION_RANGE;

      if (startIdx < points.length) {
        ctx.moveTo(centerX + points.getX(startIdx), centerY + points.getY(startIdx));
        for (let i = startIdx + 1; i < endIdx; i++) {
          ctx.lineTo(centerX + points.getX(i), centerY + points.getY(i));
        }
        ctx.stroke();
      }
    }
  } else {
    // Draw with uniform thickness
    ctx.beginPath();
    ctx.moveTo(centerX + points.getX(0), centerY + points.getY(0));
    for (let i = 1; i < points.length; i++) {
      ctx.lineTo(centerX + points.getX(i), centerY + points.getY(i));
    }
    ctx.lineWidth = LINE_WIDTH_DEFAULT;
    ctx.stroke();
  }
}

// Get line dash pattern for a style
export function getLineDashPattern(lineStyle: string): readonly number[] {
  return LINE_DASH_PATTERNS[lineStyle as keyof typeof LINE_DASH_PATTERNS] ?? [];
}

