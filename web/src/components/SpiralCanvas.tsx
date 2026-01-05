import { useRef, useEffect, useCallback, useState, useMemo } from 'react';
import { generateSpiral, SpiralParams, COLOR_PRESETS } from '../utils/spirals';

interface SpiralCanvasProps {
  params: SpiralParams;
  onZoomChange?: (zoom: number) => void;
  onPanChange?: (panX: number, panY: number) => void;
}

export function SpiralCanvas({ params, onZoomChange, onPanChange }: SpiralCanvasProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [isDragging, setIsDragging] = useState(false);
  const [dragStart, setDragStart] = useState({ x: 0, y: 0 });

  // Use params for zoom/pan - single source of truth from parent
  const currentZoom = params.zoom ?? 1;
  const currentPanX = params.panX ?? 0;
  const currentPanY = params.panY ?? 0;

  // Memoize color preset lookup (Fix #8)
  const colorPresetData = useMemo(() => {
    return COLOR_PRESETS.find(p => p.id === params.colorPreset) || COLOR_PRESETS[0];
  }, [params.colorPreset]);

  // Handle canvas resize
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const resizeCanvas = () => {
      const dpr = window.devicePixelRatio || 1;
      const rect = canvas.getBoundingClientRect();
      canvas.width = rect.width * dpr;
      canvas.height = rect.height * dpr;
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    };

    resizeCanvas();

    // Debounced resize handler
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
  }, []);

  // Draw spiral
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const rect = canvas.getBoundingClientRect();
    const centerX = rect.width / 2 + currentPanX;
    const centerY = rect.height / 2 + currentPanY;

    // Clear canvas - use transparent since background is handled by CSS
    ctx.clearRect(0, 0, rect.width, rect.height);

    // Generate spiral points (zoom is already in params)
    const points = generateSpiral(params);
    if (points.length < 2) return;

    // Use memoized color preset
    const colors = colorPresetData.colors;

    // Create gradient stroke that scales with viewport
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

    // Set line dash based on line style
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
    const isTrianglesMode = lineStyle === 'triangles';
    const isPerformanceMode = params.performanceMode;
    const hasThicknessVariation = params.lineThicknessVariation;

    // Triangles mode: draw triangles from center (ideal for Theodorus spiral)
    if (isTrianglesMode) {
      ctx.globalAlpha = 1;
      ctx.lineWidth = 1.5;
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
      ctx.lineWidth = 2;
      ctx.beginPath();
      if (points.length > 1) {
        ctx.moveTo(centerX + points[1].x, centerY + points[1].y);
        for (let i = 2; i < points.length; i++) {
          ctx.lineTo(centerX + points[i].x, centerY + points[i].y);
        }
      }
      ctx.stroke();
    } else if (isPointsMode) {
      // Points mode: draw discrete circles (ideal for Vogel/phyllotaxis patterns)
      ctx.globalAlpha = 1;
      const pointRadius = Math.max(1.5, 3 * (params.zoom ?? 1));

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
    } else {
      // Draw glow effect (skip in performance mode for glow-only, otherwise always draw)
      if (!isPerformanceMode || isGlowOnly) {
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
      }

      // Draw main spiral (skip for glow-only mode)
      if (!isGlowOnly) {
        ctx.globalAlpha = 1;
        ctx.strokeStyle = gradient;

        if (hasThicknessVariation) {
          // Fix #9: Optimize variable thickness - batch similar widths
          // Group segments into buckets to reduce draw calls
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
          // Draw with uniform thickness
          ctx.beginPath();
          ctx.moveTo(centerX + points[0].x, centerY + points[0].y);
          for (let i = 1; i < points.length; i++) {
            ctx.lineTo(centerX + points[i].x, centerY + points[i].y);
          }
          ctx.lineWidth = 2;
          ctx.stroke();
        }
      }
    }

    // Reset line dash
    ctx.setLineDash([]);

  }, [params, currentPanX, currentPanY, colorPresetData]);

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
