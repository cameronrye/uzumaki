/**
 * Shared gradient and canvas configuration utilities.
 * These are used by both main thread rendering (SpiralCanvas) and
 * Web Worker rendering (spiralWorker) to ensure consistent visuals.
 */

// Canvas context type that works with both regular and offscreen canvas
type AnyCanvasContext = CanvasRenderingContext2D | OffscreenCanvasRenderingContext2D;

/**
 * Configuration for creating a linear gradient along the spiral
 */
export interface GradientConfig {
  centerX: number;
  centerY: number;
  width: number;
  height: number;
  colors: string[];
}

/**
 * Create a linear gradient for spiral rendering.
 * The gradient is configured to span from top-left to bottom-right
 * at 40% of the smaller canvas dimension for consistent appearance.
 * 
 * @param ctx - Canvas rendering context (2D or OffscreenCanvas)
 * @param config - Gradient configuration
 * @returns CanvasGradient ready for use
 */
export function createSpiralGradient<T extends AnyCanvasContext>(
  ctx: T,
  config: GradientConfig
): CanvasGradient {
  const { centerX, centerY, width, height, colors } = config;
  const gradientSize = Math.min(width, height) * 0.4;
  
  const gradient = ctx.createLinearGradient(
    centerX - gradientSize,
    centerY - gradientSize,
    centerX + gradientSize,
    centerY + gradientSize
  );
  
  // Distribute colors evenly along the gradient
  const colorCount = colors.length;
  if (colorCount > 0) {
    colors.forEach((color, index) => {
      gradient.addColorStop(index / Math.max(1, colorCount - 1), color);
    });
  }
  
  return gradient;
}

/**
 * Configure canvas context with standard line rendering settings
 */
export function configureLineContext<T extends AnyCanvasContext>(ctx: T): void {
  ctx.lineCap = 'round';
  ctx.lineJoin = 'round';
}

/**
 * Calculate canvas center position with pan offset
 */
export function calculateCenter(
  width: number,
  height: number,
  panX: number = 0,
  panY: number = 0
): { centerX: number; centerY: number } {
  return {
    centerX: width / 2 + panX,
    centerY: height / 2 + panY,
  };
}

