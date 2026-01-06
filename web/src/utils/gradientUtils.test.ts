import { describe, it, expect, vi } from 'vitest';
import {
  createSpiralGradient,
  configureLineContext,
  calculateCenter,
} from './gradientUtils';

// Mock canvas context
function createMockContext() {
  return {
    createLinearGradient: vi.fn().mockReturnValue({
      addColorStop: vi.fn(),
    }),
    lineCap: 'butt' as CanvasLineCap,
    lineJoin: 'miter' as CanvasLineJoin,
  } as unknown as CanvasRenderingContext2D;
}

describe('calculateCenter', () => {
  it('should calculate center without pan offset', () => {
    const result = calculateCenter(800, 600);
    expect(result.centerX).toBe(400);
    expect(result.centerY).toBe(300);
  });

  it('should calculate center with pan offset', () => {
    const result = calculateCenter(800, 600, 100, -50);
    expect(result.centerX).toBe(500);
    expect(result.centerY).toBe(250);
  });

  it('should handle zero dimensions', () => {
    const result = calculateCenter(0, 0, 10, 20);
    expect(result.centerX).toBe(10);
    expect(result.centerY).toBe(20);
  });
});

describe('createSpiralGradient', () => {
  it('should create a linear gradient with correct coordinates', () => {
    const ctx = createMockContext();
    
    createSpiralGradient(ctx, {
      centerX: 400,
      centerY: 300,
      width: 800,
      height: 600,
      colors: ['#ff0000', '#00ff00'],
    });

    // Gradient size is 40% of smaller dimension (600 * 0.4 = 240)
    expect(ctx.createLinearGradient).toHaveBeenCalledWith(
      400 - 240, // centerX - gradientSize
      300 - 240, // centerY - gradientSize
      400 + 240, // centerX + gradientSize
      300 + 240  // centerY + gradientSize
    );
  });

  it('should add color stops at correct positions', () => {
    const ctx = createMockContext();
    const gradient = createSpiralGradient(ctx, {
      centerX: 400,
      centerY: 300,
      width: 800,
      height: 600,
      colors: ['#ff0000', '#00ff00', '#0000ff'],
    });

    expect(gradient.addColorStop).toHaveBeenCalledTimes(3);
    expect(gradient.addColorStop).toHaveBeenCalledWith(0, '#ff0000');
    expect(gradient.addColorStop).toHaveBeenCalledWith(0.5, '#00ff00');
    expect(gradient.addColorStop).toHaveBeenCalledWith(1, '#0000ff');
  });

  it('should handle single color', () => {
    const ctx = createMockContext();
    const gradient = createSpiralGradient(ctx, {
      centerX: 400,
      centerY: 300,
      width: 800,
      height: 600,
      colors: ['#ff0000'],
    });

    // Single color should have one stop at 0 (1 / max(1, 0) = 1/1 = 1... wait no)
    // Actually with 1 color, colorCount - 1 = 0, so max(1, 0) = 1, stop at 0/1 = 0
    expect(gradient.addColorStop).toHaveBeenCalledTimes(1);
    expect(gradient.addColorStop).toHaveBeenCalledWith(0, '#ff0000');
  });

  it('should handle empty colors array', () => {
    const ctx = createMockContext();
    const gradient = createSpiralGradient(ctx, {
      centerX: 400,
      centerY: 300,
      width: 800,
      height: 600,
      colors: [],
    });

    expect(gradient.addColorStop).not.toHaveBeenCalled();
  });
});

describe('configureLineContext', () => {
  it('should set lineCap and lineJoin to round', () => {
    const ctx = createMockContext();
    
    configureLineContext(ctx);
    
    expect(ctx.lineCap).toBe('round');
    expect(ctx.lineJoin).toBe('round');
  });
});

