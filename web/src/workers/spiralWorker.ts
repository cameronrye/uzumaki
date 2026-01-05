/**
 * Web Worker for spiral generation and optional OffscreenCanvas rendering.
 * This offloads computation from the main thread for smoother animation.
 */

import { SpiralParams, generateSpiralTyped, COLOR_PRESETS } from '../utils/spirals';
import { TypedSpiralPoints, getX, getY } from '../utils/spiralTypedArrays';

// Message types for worker communication
export interface WorkerMessage {
  type: 'generate' | 'render' | 'init';
  params?: SpiralParams;
  canvas?: OffscreenCanvas;
  width?: number;
  height?: number;
}

export interface WorkerResponse {
  type: 'points' | 'rendered' | 'ready';
  points?: TypedSpiralPoints;
  buffer?: ArrayBuffer | SharedArrayBuffer;
}

let offscreenCanvas: OffscreenCanvas | null = null;
let offscreenCtx: OffscreenCanvasRenderingContext2D | null = null;

/**
 * Initialize OffscreenCanvas if provided
 */
function initCanvas(canvas: OffscreenCanvas): void {
  offscreenCanvas = canvas;
  offscreenCtx = canvas.getContext('2d');
}

/**
 * Render spiral directly to OffscreenCanvas
 */
function renderToCanvas(
  points: TypedSpiralPoints,
  params: SpiralParams,
  width: number,
  height: number
): void {
  if (!offscreenCtx || !offscreenCanvas) return;

  const ctx = offscreenCtx;
  const centerX = width / 2 + (params.panX ?? 0);
  const centerY = height / 2 + (params.panY ?? 0);

  // Clear canvas
  ctx.clearRect(0, 0, width, height);

  if (points.length < 2) return;

  // Get colors from preset
  const colorPreset = COLOR_PRESETS.find(p => p.id === params.colorPreset) || COLOR_PRESETS[0];
  const colors = colorPreset.colors;

  // Create gradient
  const gradientSize = Math.min(width, height) * 0.4;
  const gradient = ctx.createLinearGradient(
    centerX - gradientSize, centerY - gradientSize,
    centerX + gradientSize, centerY + gradientSize
  );
  colors.forEach((color, i) => {
    gradient.addColorStop(i / (colors.length - 1), color);
  });

  ctx.lineCap = 'round';
  ctx.lineJoin = 'round';

  const lineStyle = params.lineStyle || 'solid';
  switch (lineStyle) {
    case 'dashed':
      ctx.setLineDash([10, 5]);
      break;
    case 'dotted':
      ctx.setLineDash([2, 4]);
      break;
    default:
      ctx.setLineDash([]);
  }

  const isGlowOnly = lineStyle === 'glow';
  const isPointsMode = lineStyle === 'points';
  const isPerformanceMode = params.performanceMode;

  if (isPointsMode) {
    // Batched points rendering
    renderPointsBatched(ctx, points, colors, centerX, centerY, params.zoom ?? 1);
  } else {
    // Draw glow if needed
    if (!isPerformanceMode || isGlowOnly) {
      renderGlow(ctx, points, colors, centerX, centerY, isGlowOnly, isPerformanceMode);
    }

    // Draw main line
    if (!isGlowOnly) {
      renderLine(ctx, points, gradient, centerX, centerY, params.lineThicknessVariation);
    }
  }

  ctx.setLineDash([]);
}

/**
 * Render points with batching by color
 */
function renderPointsBatched(
  ctx: OffscreenCanvasRenderingContext2D,
  points: TypedSpiralPoints,
  colors: string[],
  centerX: number,
  centerY: number,
  zoom: number
): void {
  const pointRadius = Math.max(1.5, 3 * zoom);
  const numColors = colors.length;
  const pointsPerColor = Math.ceil(points.length / numColors);

  for (let colorIdx = 0; colorIdx < numColors; colorIdx++) {
    ctx.fillStyle = colors[colorIdx];
    ctx.beginPath();

    const startIdx = colorIdx * pointsPerColor;
    const endIdx = Math.min((colorIdx + 1) * pointsPerColor, points.length);

    for (let i = startIdx; i < endIdx; i++) {
      const x = centerX + getX(points, i);
      const y = centerY + getY(points, i);
      ctx.moveTo(x + pointRadius, y);
      ctx.arc(x, y, pointRadius, 0, Math.PI * 2);
    }

    ctx.fill();
  }
}

/**
 * Render glow effect layers
 */
function renderGlow(
  ctx: OffscreenCanvasRenderingContext2D,
  points: TypedSpiralPoints,
  colors: string[],
  centerX: number,
  centerY: number,
  isGlowOnly: boolean,
  isPerformanceMode: boolean | undefined
): void {
  const glowColor = colors[2] || colors[0];
  const glowLayers = isPerformanceMode
    ? [{ width: 8, opacity: 0.2 }]
    : [
        { width: 12, opacity: 0.1 },
        { width: 8, opacity: 0.15 },
        { width: 5, opacity: 0.2 },
      ];

  for (const layer of glowLayers) {
    ctx.beginPath();
    ctx.moveTo(centerX + getX(points, 0), centerY + getY(points, 0));
    for (let i = 1; i < points.length; i++) {
      ctx.lineTo(centerX + getX(points, i), centerY + getY(points, i));
    }
    ctx.strokeStyle = glowColor;
    ctx.globalAlpha = isGlowOnly ? layer.opacity * 2 : layer.opacity;
    ctx.lineWidth = isGlowOnly ? layer.width * 1.5 : layer.width;
    ctx.stroke();
  }
  ctx.globalAlpha = 1;
}

/**
 * Render main spiral line with optional thickness variation
 */
function renderLine(
  ctx: OffscreenCanvasRenderingContext2D,
  points: TypedSpiralPoints,
  gradient: CanvasGradient,
  centerX: number,
  centerY: number,
  hasThicknessVariation: boolean | undefined
): void {
  ctx.strokeStyle = gradient;

  if (hasThicknessVariation) {
    // Batch segments by width buckets
    const bucketCount = 10;
    const segmentsPerBucket = Math.ceil(points.length / bucketCount);

    for (let bucket = 0; bucket < bucketCount; bucket++) {
      const startIdx = bucket * segmentsPerBucket;
      const endIdx = Math.min((bucket + 1) * segmentsPerBucket, points.length);
      const midProgress = (startIdx + endIdx) / 2 / points.length;

      ctx.beginPath();
      ctx.lineWidth = 1 + midProgress * 3;

      if (startIdx < points.length) {
        ctx.moveTo(centerX + getX(points, startIdx), centerY + getY(points, startIdx));
        for (let i = startIdx + 1; i < endIdx; i++) {
          ctx.lineTo(centerX + getX(points, i), centerY + getY(points, i));
        }
        ctx.stroke();
      }
    }
  } else {
    ctx.beginPath();
    ctx.moveTo(centerX + getX(points, 0), centerY + getY(points, 0));
    for (let i = 1; i < points.length; i++) {
      ctx.lineTo(centerX + getX(points, i), centerY + getY(points, i));
    }
    ctx.lineWidth = 2;
    ctx.stroke();
  }
}

// Worker message handler
self.onmessage = (e: MessageEvent<WorkerMessage>) => {
  const { type, params, canvas, width, height } = e.data;

  switch (type) {
    case 'init':
      if (canvas) {
        initCanvas(canvas);
        self.postMessage({ type: 'ready' } as WorkerResponse);
      }
      break;

    case 'generate':
      if (params) {
        const points = generateSpiralTyped(params);
        // Transfer the buffer for zero-copy performance
        const response: WorkerResponse = { type: 'points', points, buffer: points.data.buffer };
        self.postMessage(response, { transfer: [points.data.buffer] });
      }
      break;

    case 'render':
      if (params && width && height) {
        const points = generateSpiralTyped(params);
        renderToCanvas(points, params, width, height);
        self.postMessage({ type: 'rendered' } as WorkerResponse);
      }
      break;
  }
};

