import { useRef, useEffect, useCallback, useState, useMemo } from 'react';
import { generateSpiral, SpiralParams, COLOR_PRESETS, SpiralPoint } from '../utils/spirals';
import { useSpiralWorker } from '../hooks/useSpiralWorker';
import { supportsOffscreenCanvas } from '../utils/spiralTypedArrays';

// ============================================================================
// Batched rendering helpers for optimized canvas drawing
// ============================================================================

/** Render points with color batching - single beginPath/fill per color */
function renderPointsBatched(
  ctx: CanvasRenderingContext2D,
  points: SpiralPoint[],
  colors: string[],
  centerX: number,
  centerY: number,
  zoom: number
): void {
  ctx.globalAlpha = 1;
  const pointRadius = Math.max(1.5, 3 * zoom);
  const numColors = colors.length;
  const pointsPerColor = Math.ceil(points.length / numColors);

  for (let colorIdx = 0; colorIdx < numColors; colorIdx++) {
    ctx.fillStyle = colors[colorIdx];
    ctx.beginPath();

    const startIdx = colorIdx * pointsPerColor;
    const endIdx = Math.min((colorIdx + 1) * pointsPerColor, points.length);

    for (let i = startIdx; i < endIdx; i++) {
      const x = centerX + points[i].x;
      const y = centerY + points[i].y;
      ctx.moveTo(x + pointRadius, y);
      ctx.arc(x, y, pointRadius, 0, Math.PI * 2);
    }

    ctx.fill();
  }
}

/** Render triangles with color batching */
function renderTrianglesBatched(
  ctx: CanvasRenderingContext2D,
  points: SpiralPoint[],
  colors: string[],
  centerX: number,
  centerY: number
): void {
  ctx.globalAlpha = 1;
  ctx.lineWidth = 1.5;
  ctx.lineCap = 'round';
  ctx.lineJoin = 'round';

  const originX = centerX + points[0].x;
  const originY = centerY + points[0].y;
  const numColors = colors.length;
  const trianglesPerColor = Math.ceil((points.length - 1) / numColors);

  // Batch triangles by color
  for (let colorIdx = 0; colorIdx < numColors; colorIdx++) {
    ctx.strokeStyle = colors[colorIdx];
    ctx.beginPath();

    const startIdx = colorIdx * trianglesPerColor + 1;
    const endIdx = Math.min((colorIdx + 1) * trianglesPerColor + 1, points.length);

    for (let i = startIdx; i < endIdx; i++) {
      ctx.moveTo(originX, originY);
      if (i > 1) {
        ctx.lineTo(centerX + points[i - 1].x, centerY + points[i - 1].y);
      }
      ctx.lineTo(centerX + points[i].x, centerY + points[i].y);
      ctx.lineTo(originX, originY);
    }

    ctx.stroke();
  }

  // Draw outer edge
  ctx.strokeStyle = colors[0];
  ctx.lineWidth = 2;
  ctx.beginPath();
  if (points.length > 1) {
    ctx.moveTo(centerX + points[1].x, centerY + points[1].y);
    for (let i = 2; i < points.length; i++) {
      ctx.lineTo(centerX + points[i].x, centerY + points[i].y);
    }
  }
  ctx.stroke();
}

/** Render glow effect layers */
function renderGlow(
  ctx: CanvasRenderingContext2D,
  points: SpiralPoint[],
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
    ctx.moveTo(centerX + points[0].x, centerY + points[0].y);
    for (let i = 1; i < points.length; i++) {
      ctx.lineTo(centerX + points[i].x, centerY + points[i].y);
    }
    ctx.strokeStyle = glowColor;
    ctx.globalAlpha = isGlowOnly ? layer.opacity * 2 : layer.opacity;
    ctx.lineWidth = isGlowOnly ? layer.width * 1.5 : layer.width;
    ctx.stroke();
  }
  ctx.globalAlpha = 1;
}

/** Render main line with optional thickness variation (batched by width buckets) */
function renderLine(
  ctx: CanvasRenderingContext2D,
  points: SpiralPoint[],
  gradient: CanvasGradient,
  centerX: number,
  centerY: number,
  hasThicknessVariation: boolean | undefined
): void {
  ctx.strokeStyle = gradient;

  if (hasThicknessVariation) {
    const bucketCount = 10;
    const segmentsPerBucket = Math.ceil(points.length / bucketCount);

    for (let bucket = 0; bucket < bucketCount; bucket++) {
      const startIdx = bucket * segmentsPerBucket;
      const endIdx = Math.min((bucket + 1) * segmentsPerBucket, points.length);
      const midProgress = (startIdx + endIdx) / 2 / points.length;

      ctx.beginPath();
      ctx.lineWidth = 1 + midProgress * 3;

      if (startIdx < points.length) {
        ctx.moveTo(centerX + points[startIdx].x, centerY + points[startIdx].y);
        for (let i = startIdx + 1; i < endIdx; i++) {
          ctx.lineTo(centerX + points[i].x, centerY + points[i].y);
        }
        ctx.stroke();
      }
    }
  } else {
    ctx.beginPath();
    ctx.moveTo(centerX + points[0].x, centerY + points[0].y);
    for (let i = 1; i < points.length; i++) {
      ctx.lineTo(centerX + points[i].x, centerY + points[i].y);
    }
    ctx.lineWidth = 2;
    ctx.stroke();
  }
}

// ============================================================================

interface SpiralCanvasProps {
  params: SpiralParams;
  onZoomChange?: (zoom: number) => void;
  onPanChange?: (panX: number, panY: number) => void;
}

export function SpiralCanvas({ params, onZoomChange, onPanChange }: SpiralCanvasProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [isDragging, setIsDragging] = useState(false);
  const [dragStart, setDragStart] = useState({ x: 0, y: 0 });
  const [useWorker, setUseWorker] = useState(true);
  const workerInitializedRef = useRef(false);
  const dimensionsRef = useRef({ width: 0, height: 0 });

  // Use params for zoom/pan - single source of truth from parent
  const currentZoom = params.zoom ?? 1;
  const currentPanX = params.panX ?? 0;
  const currentPanY = params.panY ?? 0;

  // Memoize color preset lookup
  const colorPresetData = useMemo(() => {
    return COLOR_PRESETS.find(p => p.id === params.colorPreset) || COLOR_PRESETS[0];
  }, [params.colorPreset]);

  // Initialize spiral worker with OffscreenCanvas support
  const {
    isOffscreenMode,
    isReady: workerReady,
    requestRender,
    initOffscreenCanvas,
    isSupported: workerSupported,
  } = useSpiralWorker({
    useOffscreenCanvas: useWorker && supportsOffscreenCanvas(),
  });

  // Initialize OffscreenCanvas with worker (only once)
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas || !workerSupported || workerInitializedRef.current) return;

    // Try to initialize OffscreenCanvas rendering
    if (supportsOffscreenCanvas()) {
      const success = initOffscreenCanvas(canvas);
      if (success) {
        workerInitializedRef.current = true;
        // Store dimensions for worker
        const rect = canvas.getBoundingClientRect();
        const dpr = window.devicePixelRatio || 1;
        dimensionsRef.current = { width: rect.width * dpr, height: rect.height * dpr };
      } else {
        setUseWorker(false);
      }
    } else {
      setUseWorker(false);
    }
  }, [workerSupported, initOffscreenCanvas]);

  // Handle canvas resize (fallback mode only - worker handles its own canvas)
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    // In OffscreenCanvas mode, we just track dimensions
    const updateDimensions = () => {
      const dpr = window.devicePixelRatio || 1;
      const rect = canvas.getBoundingClientRect();
      dimensionsRef.current = { width: rect.width * dpr, height: rect.height * dpr };
    };

    // Only set up 2D context for fallback (non-offscreen) mode
    if (!isOffscreenMode) {
      const ctx = canvas.getContext('2d');
      if (!ctx) return;

      const resizeCanvas = () => {
        const dpr = window.devicePixelRatio || 1;
        const rect = canvas.getBoundingClientRect();
        canvas.width = rect.width * dpr;
        canvas.height = rect.height * dpr;
        ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
        dimensionsRef.current = { width: rect.width, height: rect.height };
      };

      resizeCanvas();

      let resizeTimeout: number;
      const debouncedResize = () => {
        clearTimeout(resizeTimeout);
        resizeTimeout = window.setTimeout(resizeCanvas, 100);
      };

      window.addEventListener('resize', debouncedResize);
      return () => {
        window.removeEventListener('resize', debouncedResize);
        clearTimeout(resizeTimeout);
      };
    } else {
      updateDimensions();

      let resizeTimeout: number;
      const debouncedResize = () => {
        clearTimeout(resizeTimeout);
        resizeTimeout = window.setTimeout(updateDimensions, 100);
      };

      window.addEventListener('resize', debouncedResize);
      return () => {
        window.removeEventListener('resize', debouncedResize);
        clearTimeout(resizeTimeout);
      };
    }
  }, [isOffscreenMode]);

  // Draw spiral - uses Web Worker with OffscreenCanvas when available, falls back to main thread
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    // OffscreenCanvas mode: delegate rendering to worker
    if (isOffscreenMode && workerReady) {
      const { width, height } = dimensionsRef.current;
      if (width > 0 && height > 0) {
        requestRender(params, width, height);
      }
      return;
    }

    // Fallback: render on main thread with batched operations
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const rect = canvas.getBoundingClientRect();
    const centerX = rect.width / 2 + currentPanX;
    const centerY = rect.height / 2 + currentPanY;

    ctx.clearRect(0, 0, rect.width, rect.height);

    const points = generateSpiral(params);
    if (points.length < 2) return;

    const colors = colorPresetData.colors;

    const gradientSize = Math.min(rect.width, rect.height) * 0.4;
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
      case 'dashed': ctx.setLineDash([10, 5]); break;
      case 'dotted': ctx.setLineDash([2, 4]); break;
      default: ctx.setLineDash([]);
    }

    const isGlowOnly = lineStyle === 'glow';
    const isPointsMode = lineStyle === 'points';
    const isTrianglesMode = lineStyle === 'triangles';
    const isPerformanceMode = params.performanceMode;
    const hasThicknessVariation = params.lineThicknessVariation;

    if (isTrianglesMode) {
      renderTrianglesBatched(ctx, points, colors, centerX, centerY);
    } else if (isPointsMode) {
      renderPointsBatched(ctx, points, colors, centerX, centerY, params.zoom ?? 1);
    } else {
      if (!isPerformanceMode || isGlowOnly) {
        renderGlow(ctx, points, colors, centerX, centerY, isGlowOnly, isPerformanceMode);
      }
      if (!isGlowOnly) {
        renderLine(ctx, points, gradient, centerX, centerY, hasThicknessVariation);
      }
    }

    ctx.setLineDash([]);
  }, [params, currentPanX, currentPanY, colorPresetData, isOffscreenMode, workerReady, requestRender]);

  // Mouse wheel zoom
  const handleWheel = useCallback((e: React.WheelEvent) => {
    e.preventDefault();
    const zoomFactor = e.deltaY > 0 ? 0.9 : 1.1;
    const newZoom = Math.max(0.1, Math.min(10, currentZoom * zoomFactor));
    onZoomChange?.(newZoom);
  }, [currentZoom, onZoomChange]);

  // Pan handlers
  const handleMouseDown = useCallback((e: React.MouseEvent) => {
    setIsDragging(true);
    setDragStart({ x: e.clientX - currentPanX, y: e.clientY - currentPanY });
  }, [currentPanX, currentPanY]);

  const handleMouseMove = useCallback((e: React.MouseEvent) => {
    if (!isDragging) return;
    const newPanX = e.clientX - dragStart.x;
    const newPanY = e.clientY - dragStart.y;
    onPanChange?.(newPanX, newPanY);
  }, [isDragging, dragStart, onPanChange]);

  const handleMouseUp = useCallback(() => {
    setIsDragging(false);
  }, []);

  // Touch handlers for mobile
  const handleTouchStart = useCallback((e: React.TouchEvent) => {
    if (e.touches.length === 1) {
      const touch = e.touches[0];
      setIsDragging(true);
      setDragStart({ x: touch.clientX - currentPanX, y: touch.clientY - currentPanY });
    }
  }, [currentPanX, currentPanY]);

  const handleTouchMove = useCallback((e: React.TouchEvent) => {
    if (!isDragging || e.touches.length !== 1) return;
    const touch = e.touches[0];
    const newPanX = touch.clientX - dragStart.x;
    const newPanY = touch.clientY - dragStart.y;
    onPanChange?.(newPanX, newPanY);
  }, [isDragging, dragStart, onPanChange]);

  const handleTouchEnd = useCallback(() => {
    setIsDragging(false);
  }, []);

  return (
    <canvas
      ref={canvasRef}
      onWheel={handleWheel}
      onMouseDown={handleMouseDown}
      onMouseMove={handleMouseMove}
      onMouseUp={handleMouseUp}
      onMouseLeave={handleMouseUp}
      onTouchStart={handleTouchStart}
      onTouchMove={handleTouchMove}
      onTouchEnd={handleTouchEnd}
      style={{
        width: '100%',
        height: '100%',
        display: 'block',
        cursor: isDragging ? 'grabbing' : 'grab',
        touchAction: 'none',
      }}
      aria-label={`${params.type} spiral visualization. Use mouse wheel to zoom, drag to pan.`}
      role="img"
    />
  );
}
