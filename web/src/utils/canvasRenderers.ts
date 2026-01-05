import { SpiralPoint } from './spirals';
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

export interface RenderContext {
  ctx: CanvasRenderingContext2D;
  centerX: number;
  centerY: number;
  points: SpiralPoint[];
  colors: string[];
  gradient: CanvasGradient;
  zoom: number;
  isPerformanceMode: boolean;
  hasThicknessVariation: boolean;
}

// Draw triangles from center (ideal for Theodorus spiral)
export function drawTriangles(context: RenderContext): void {
  const { ctx, centerX, centerY, points, colors } = context;
  
  ctx.globalAlpha = 1;
  ctx.lineWidth = LINE_WIDTH_TRIANGLES;
  ctx.lineCap = 'round';
  ctx.lineJoin = 'round';

  // First point is the center for Theodorus spiral
  const originX = centerX + points[0].x;
  const originY = centerY + points[0].y;

  for (let i = 1; i < points.length; i++) {
    const progress = i / points.length;
    const colorIndex = Math.floor(progress * (colors.length - 1));
    ctx.strokeStyle = colors[colorIndex];

    // Draw triangle: center -> previous point -> current point -> center
    ctx.beginPath();
    ctx.moveTo(originX, originY);
    if (i > 1) {
      ctx.lineTo(centerX + points[i - 1].x, centerY + points[i - 1].y);
    }
    ctx.lineTo(centerX + points[i].x, centerY + points[i].y);
    ctx.lineTo(originX, originY);
    ctx.stroke();
  }

  // Draw hypotenuse markers (the outer edge)
  ctx.strokeStyle = colors[0];
  ctx.lineWidth = LINE_WIDTH_TRIANGLES_OUTER;
  ctx.beginPath();
  if (points.length > 1) {
    ctx.moveTo(centerX + points[1].x, centerY + points[1].y);
    for (let i = 2; i < points.length; i++) {
      ctx.lineTo(centerX + points[i].x, centerY + points[i].y);
    }
  }
  ctx.stroke();
}

// Draw discrete circles (ideal for Vogel/phyllotaxis patterns)
export function drawPoints(context: RenderContext): void {
  const { ctx, centerX, centerY, points, colors, zoom } = context;
  
  ctx.globalAlpha = 1;
  const pointRadius = Math.max(POINT_RADIUS_MIN, POINT_RADIUS_BASE * zoom);

  for (let i = 0; i < points.length; i++) {
    const progress = i / points.length;
    const colorIndex = Math.floor(progress * (colors.length - 1));
    const nextColorIndex = Math.min(colorIndex + 1, colors.length - 1);
    const colorProgress = (progress * (colors.length - 1)) % 1;

    // Interpolate between colors for smooth gradient
    ctx.fillStyle = colors[colorIndex];
    if (colorProgress > 0 && colorIndex !== nextColorIndex) {
      ctx.fillStyle = colors[nextColorIndex];
    }

    ctx.beginPath();
    ctx.arc(centerX + points[i].x, centerY + points[i].y, pointRadius, 0, Math.PI * 2);
    ctx.fill();
  }
}

// Draw glow effect layers
export function drawGlow(context: RenderContext, isGlowOnly: boolean): void {
  const { ctx, centerX, centerY, points, colors, isPerformanceMode } = context;
  
  const glowColor = colors[2] || colors[0];
  const glowLayers = isPerformanceMode ? GLOW_LAYERS_PERFORMANCE : GLOW_LAYERS_NORMAL;

  for (const layer of glowLayers) {
    ctx.beginPath();
    ctx.moveTo(centerX + points[0].x, centerY + points[0].y);
    for (let i = 1; i < points.length; i++) {
      ctx.lineTo(centerX + points[i].x, centerY + points[i].y);
    }
    ctx.strokeStyle = glowColor;
    ctx.globalAlpha = isGlowOnly ? layer.opacity * 2 : layer.opacity;
    ctx.lineWidth = isGlowOnly ? layer.width * 1.5 : layer.width;
    ctx.stroke();
  }
}

// Draw main spiral line with optional thickness variation
export function drawLine(context: RenderContext): void {
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
        ctx.moveTo(centerX + points[startIdx].x, centerY + points[startIdx].y);
        for (let i = startIdx + 1; i < endIdx; i++) {
          ctx.lineTo(centerX + points[i].x, centerY + points[i].y);
        }
        ctx.stroke();
      }
    }
  } else {
    // Draw with uniform thickness
    ctx.beginPath();
    ctx.moveTo(centerX + points[0].x, centerY + points[0].y);
    for (let i = 1; i < points.length; i++) {
      ctx.lineTo(centerX + points[i].x, centerY + points[i].y);
    }
    ctx.lineWidth = LINE_WIDTH_DEFAULT;
    ctx.stroke();
  }
}

// Get line dash pattern for a style
export function getLineDashPattern(lineStyle: string): readonly number[] {
  return LINE_DASH_PATTERNS[lineStyle as keyof typeof LINE_DASH_PATTERNS] ?? [];
}

