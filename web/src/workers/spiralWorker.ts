/**
 * Web Worker for spiral generation and optional OffscreenCanvas rendering.
 * This offloads computation from the main thread for smoother animation.
 */

import { SpiralParams, generateSpiralTyped, COLOR_PRESETS } from '../utils/spirals';
import { TypedSpiralPoints } from '../utils/spiralTypedArrays';
import {
  fromTypedPoints,
  drawPointsBatched,
  drawGlow,
  drawLine,
  getLineDashPattern,
  RenderContext,
} from '../utils/canvasRenderers';
import {
  createSpiralGradient,
  configureLineContext,
  calculateCenter,
} from '../utils/gradientUtils';

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
 * Render spiral directly to OffscreenCanvas using shared renderers
 */
function renderToCanvas(
  points: TypedSpiralPoints,
  params: SpiralParams,
  width: number,
  height: number
): void {
  if (!offscreenCtx || !offscreenCanvas) return;

  const ctx = offscreenCtx;
  const { centerX, centerY } = calculateCenter(width, height, params.panX, params.panY);

  // Clear canvas
  ctx.clearRect(0, 0, width, height);

  if (points.length < 2) return;

  // Get colors from preset
  const colorPreset = COLOR_PRESETS.find(p => p.id === params.colorPreset) ?? COLOR_PRESETS[0];
  const colors = colorPreset?.colors ?? ['#ffffff'];

  // Create gradient using shared utility
  const gradient = createSpiralGradient(ctx, {
    centerX,
    centerY,
    width,
    height,
    colors,
  });

  // Configure line context using shared utility
  configureLineContext(ctx);

  const lineStyle = params.lineStyle || 'solid';
  ctx.setLineDash(getLineDashPattern(lineStyle) as number[]);

  const isGlowOnly = lineStyle === 'glow';
  const isPointsMode = lineStyle === 'points';

  // Create unified render context for shared renderers
  const renderContext: RenderContext<OffscreenCanvasRenderingContext2D> = {
    ctx,
    centerX,
    centerY,
    points: fromTypedPoints(points),
    colors,
    gradient,
    zoom: params.zoom ?? 1,
    isPerformanceMode: params.performanceMode ?? false,
    hasThicknessVariation: params.lineThicknessVariation ?? false,
  };

  if (isPointsMode) {
    drawPointsBatched(renderContext);
  } else {
    if (!renderContext.isPerformanceMode || isGlowOnly) {
      drawGlow(renderContext, isGlowOnly);
    }
    if (!isGlowOnly) {
      drawLine(renderContext);
    }
  }

  ctx.setLineDash([]);
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

