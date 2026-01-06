import { useRef, useEffect, useCallback, useState, useMemo } from 'react';
import { generateSpiral, SpiralParams, COLOR_PRESETS, fromPointArray } from '../utils/spirals';
import { useSpiralWorker } from '../hooks/useSpiralWorker';
import { supportsOffscreenCanvas } from '../utils/spiralTypedArrays';
import {
  drawPointsBatched,
  drawTrianglesBatched,
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
    const found = COLOR_PRESETS.find(p => p.id === params.colorPreset);
    const fallback = COLOR_PRESETS[0];
    return found ?? fallback ?? { id: 'rainbow' as const, name: 'Rainbow', colors: ['#ffffff'] };
  }, [params.colorPreset]);

  // Initialize spiral worker with OffscreenCanvas support
  const {
    isOffscreenMode,
    isReady: workerReady,
    isWorkerCreated,
    requestRender,
    initOffscreenCanvas,
    isSupported: workerSupported,
    isCanvasTransferred,
    checkCanvasTransferred,
  } = useSpiralWorker({
    useOffscreenCanvas: useWorker && supportsOffscreenCanvas(),
  });

  // Keep a ref to the latest initOffscreenCanvas to avoid dependency issues
  const initOffscreenCanvasRef = useRef(initOffscreenCanvas);
  initOffscreenCanvasRef.current = initOffscreenCanvas;

  // Initialize OffscreenCanvas with worker (only once, after worker is created)
  useEffect(() => {
    const canvas = canvasRef.current;
    // Skip if already transferred - canvas control transfer is irreversible
    // Use synchronous ref check to prevent race conditions
    if (!canvas || !workerSupported || isCanvasTransferred || checkCanvasTransferred()) return;
    // Skip if we've already successfully initialized
    if (workerInitializedRef.current) return;
    // Wait for worker to be created before attempting canvas transfer
    if (!isWorkerCreated) return;

    // Try to initialize OffscreenCanvas rendering
    if (supportsOffscreenCanvas()) {
      const success = initOffscreenCanvasRef.current(canvas);
      if (success) {
        workerInitializedRef.current = true;
        // Store dimensions for worker
        const rect = canvas.getBoundingClientRect();
        const dpr = window.devicePixelRatio || 1;
        dimensionsRef.current = { width: rect.width * dpr, height: rect.height * dpr };
      }
      // If init fails, don't disable worker mode - something else is wrong
    } else {
      // OffscreenCanvas not supported, fall back to main thread
      setUseWorker(false);
    }
  }, [workerSupported, isCanvasTransferred, checkCanvasTransferred, isWorkerCreated]);

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
    // Use synchronous check to prevent getContext on transferred canvas (state updates are async)
    if (!isOffscreenMode && !isCanvasTransferred && !checkCanvasTransferred()) {
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
  }, [isOffscreenMode, isCanvasTransferred, checkCanvasTransferred]);

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

    // If canvas has been transferred but worker not ready yet, skip main thread rendering
    // Use synchronous check to prevent getContext on transferred canvas (state updates are async)
    if (isCanvasTransferred || checkCanvasTransferred()) return;

    // Fallback: render on main thread with batched operations
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const rect = canvas.getBoundingClientRect();
    const { centerX, centerY } = calculateCenter(rect.width, rect.height, currentPanX, currentPanY);

    ctx.clearRect(0, 0, rect.width, rect.height);

    const points = generateSpiral(params);
    if (points.length < 2) return;

    const colors = colorPresetData.colors;

    // Create gradient using shared utility
    const gradient = createSpiralGradient(ctx, {
      centerX,
      centerY,
      width: rect.width,
      height: rect.height,
      colors,
    });

    // Configure line context using shared utility
    configureLineContext(ctx);

    const lineStyle = params.lineStyle || 'solid';
    ctx.setLineDash(getLineDashPattern(lineStyle) as number[]);

    const isGlowOnly = lineStyle === 'glow';
    const isPointsMode = lineStyle === 'points';
    const isTrianglesMode = lineStyle === 'triangles';

    // Create unified render context for shared renderers
    const renderContext: RenderContext = {
      ctx,
      centerX,
      centerY,
      points: fromPointArray(points),
      colors,
      gradient,
      zoom: params.zoom ?? 1,
      isPerformanceMode: params.performanceMode ?? false,
      hasThicknessVariation: params.lineThicknessVariation ?? false,
    };

    if (isTrianglesMode) {
      drawTrianglesBatched(renderContext);
    } else if (isPointsMode) {
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
  }, [params, currentPanX, currentPanY, colorPresetData, isOffscreenMode, workerReady, requestRender, isCanvasTransferred, checkCanvasTransferred]);

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
      if (touch) {
        setIsDragging(true);
        setDragStart({ x: touch.clientX - currentPanX, y: touch.clientY - currentPanY });
      }
    }
  }, [currentPanX, currentPanY]);

  const handleTouchMove = useCallback((e: React.TouchEvent) => {
    if (!isDragging || e.touches.length !== 1) return;
    const touch = e.touches[0];
    if (touch) {
      const newPanX = touch.clientX - dragStart.x;
      const newPanY = touch.clientY - dragStart.y;
      onPanChange?.(newPanX, newPanY);
    }
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
