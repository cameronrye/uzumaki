import { useState, useEffect, useCallback, useRef } from 'react';
import { SpiralCanvas } from './components/SpiralCanvas';
import { Controls } from './components/Controls';
import { SpiralIcon, MouseIcon } from './components/Icons';
import {
  SpiralType,
  SpiralParams,
  ColorPreset,
  SpiralPreset,
  LineStyle,
  BackgroundStyle,
  COLOR_PRESETS
} from './utils/spirals';
import { decodeStateFromURL, copyShareURL, ShareableState } from './utils/urlState';

// Default values for reset
const DEFAULTS = {
  spiralType: 'archimedean' as SpiralType,
  spinRate: 0.5,
  tightness: 3,
  stepSize: 0.1,
  numSteps: 500,
  colorPreset: 'rainbow' as ColorPreset,
  lineStyle: 'solid' as LineStyle,
  backgroundStyle: 'dark' as BackgroundStyle,
  performanceMode: false,
  lineThicknessVariation: false,
};

function App() {
  // Load initial state from URL or defaults
  const urlState = useRef(decodeStateFromURL());

  const [spiralType, setSpiralType] = useState<SpiralType>(urlState.current?.spiralType ?? DEFAULTS.spiralType);
  const [spinRate, setSpinRate] = useState(urlState.current?.spinRate ?? DEFAULTS.spinRate);
  const [tightness, setTightness] = useState(urlState.current?.tightness ?? DEFAULTS.tightness);
  const [stepSize, setStepSize] = useState(urlState.current?.stepSize ?? DEFAULTS.stepSize);
  const [numSteps, setNumSteps] = useState(urlState.current?.numSteps ?? DEFAULTS.numSteps);
  const [time, setTime] = useState(0);
  const [viewportScale, setViewportScale] = useState(1);
  const [isPaused, setIsPaused] = useState(false);
  const [colorPreset, setColorPreset] = useState<ColorPreset>(urlState.current?.colorPreset ?? DEFAULTS.colorPreset);
  const [lineStyle, setLineStyle] = useState<LineStyle>(urlState.current?.lineStyle ?? DEFAULTS.lineStyle);
  const [backgroundStyle, setBackgroundStyle] = useState<BackgroundStyle>(urlState.current?.backgroundStyle ?? DEFAULTS.backgroundStyle);
  const [performanceMode, setPerformanceMode] = useState(urlState.current?.performanceMode ?? DEFAULTS.performanceMode);
  const [lineThicknessVariation, setLineThicknessVariation] = useState(urlState.current?.lineThicknessVariation ?? DEFAULTS.lineThicknessVariation);
  const [zoom, setZoom] = useState(1);
  const [panX, setPanX] = useState(0);
  const [panY, setPanY] = useState(0);

  // UI state
  const [showOnboarding, setShowOnboarding] = useState(!urlState.current);
  const [showShortcuts, setShowShortcuts] = useState(false);
  const [toast, setToast] = useState<string | null>(null);

  const appRef = useRef<HTMLDivElement>(null);
  const hasInteracted = useRef(false);

  // Check for reduced motion preference
  const prefersReducedMotion = useRef(
    window.matchMedia('(prefers-reduced-motion: reduce)').matches
  );

  // Calculate viewport scale based on screen size
  useEffect(() => {
    const updateViewportScale = () => {
      const minDimension = Math.min(window.innerWidth, window.innerHeight);
      const scale = Math.max(0.5, Math.min(2, minDimension / 600));
      setViewportScale(scale);
    };

    updateViewportScale();

    let resizeTimeout: number;
    const debouncedResize = () => {
      clearTimeout(resizeTimeout);
      resizeTimeout = window.setTimeout(updateViewportScale, 100);
    };

    window.addEventListener('resize', debouncedResize);
    return () => {
      window.removeEventListener('resize', debouncedResize);
      clearTimeout(resizeTimeout);
    };
  }, []);

  // Animation loop with pause support and frame rate limiting
  useEffect(() => {
    if (isPaused || prefersReducedMotion.current) return;

    let animationId: number;
    let lastTime = performance.now();
    let lastFrameTime = 0;

    // Target 60fps in normal mode, 30fps in performance mode
    const targetFPS = performanceMode ? 30 : 60;
    const frameInterval = 1000 / targetFPS;

    const animate = (currentTime: number) => {
      // Frame rate limiting
      const elapsed = currentTime - lastFrameTime;

      if (elapsed >= frameInterval) {
        const deltaTime = (currentTime - lastTime) / 1000;
        lastTime = currentTime;
        lastFrameTime = currentTime - (elapsed % frameInterval);

        setTime(prev => prev + deltaTime);
      }

      animationId = requestAnimationFrame(animate);
    };

    animationId = requestAnimationFrame(animate);
    return () => cancelAnimationFrame(animationId);
  }, [isPaused, performanceMode]);

  // Hide onboarding on first interaction
  useEffect(() => {
    if (!showOnboarding) return;

    const handleInteraction = () => {
      if (!hasInteracted.current) {
        hasInteracted.current = true;
        setTimeout(() => setShowOnboarding(false), 300);
      }
    };

    window.addEventListener('mousedown', handleInteraction);
    window.addEventListener('wheel', handleInteraction);
    window.addEventListener('touchstart', handleInteraction);

    // Auto-hide after 4 seconds
    const timeout = setTimeout(() => setShowOnboarding(false), 4000);

    return () => {
      window.removeEventListener('mousedown', handleInteraction);
      window.removeEventListener('wheel', handleInteraction);
      window.removeEventListener('touchstart', handleInteraction);
      clearTimeout(timeout);
    };
  }, [showOnboarding]);

  // Toast auto-hide
  useEffect(() => {
    if (!toast) return;
    const timeout = setTimeout(() => setToast(null), 2000);
    return () => clearTimeout(timeout);
  }, [toast]);

  const params: SpiralParams = {
    type: spiralType,
    tightness,
    spinRate,
    stepSize,
    numSteps: performanceMode ? Math.min(numSteps, 500) : numSteps,
    time,
    viewportScale,
    isPaused,
    colorPreset,
    zoom,
    panX,
    panY,
    lineStyle,
    backgroundStyle,
    performanceMode,
    lineThicknessVariation,
  };

  // Get background color for matching mode
  const getBackgroundStyle = () => {
    if (backgroundStyle === 'matching') {
      const colorInfo = COLOR_PRESETS.find(c => c.id === colorPreset);
      if (colorInfo) {
        return `radial-gradient(circle at center, ${colorInfo.colors[0]}22 0%, #0a0a0f 100%)`;
      }
    }
    return undefined;
  };

  const handleTypeChange = useCallback((type: SpiralType) => {
    setSpiralType(type);
  }, []);

  const handleSpinRateChange = useCallback((value: number) => {
    setSpinRate(value);
  }, []);

  const handleTightnessChange = useCallback((value: number) => {
    setTightness(value);
  }, []);

  const handleStepSizeChange = useCallback((value: number) => {
    setStepSize(value);
  }, []);

  const handleNumStepsChange = useCallback((value: number) => {
    setNumSteps(value);
  }, []);

  const handlePauseToggle = useCallback(() => {
    setIsPaused(p => !p);
  }, []);

  const handleReset = useCallback(() => {
    setSpiralType(DEFAULTS.spiralType);
    setSpinRate(DEFAULTS.spinRate);
    setTightness(DEFAULTS.tightness);
    setStepSize(DEFAULTS.stepSize);
    setNumSteps(DEFAULTS.numSteps);
    setColorPreset(DEFAULTS.colorPreset);
    setLineStyle(DEFAULTS.lineStyle);
    setBackgroundStyle(DEFAULTS.backgroundStyle);
    setPerformanceMode(DEFAULTS.performanceMode);
    setLineThicknessVariation(DEFAULTS.lineThicknessVariation);
    setZoom(1);
    setPanX(0);
    setPanY(0);
    setTime(0);
    setIsPaused(false);
    // Clear URL params
    window.history.replaceState({}, '', window.location.pathname);
  }, []);

  const handleColorChange = useCallback((preset: ColorPreset) => {
    setColorPreset(preset);
  }, []);

  const handlePresetLoad = useCallback((preset: SpiralPreset) => {
    if (preset.params.type) setSpiralType(preset.params.type);
    if (preset.params.spinRate !== undefined) setSpinRate(preset.params.spinRate);
    if (preset.params.tightness !== undefined) setTightness(preset.params.tightness);
    if (preset.params.stepSize !== undefined) setStepSize(preset.params.stepSize);
    if (preset.params.numSteps !== undefined) setNumSteps(preset.params.numSteps);
  }, []);

  const handleShare = useCallback(async () => {
    const state: ShareableState = {
      spiralType,
      spinRate,
      tightness,
      stepSize,
      numSteps,
      colorPreset,
      lineStyle,
      backgroundStyle,
      performanceMode,
      lineThicknessVariation,
    };
    const success = await copyShareURL(state);
    if (success) {
      setToast('Link copied to clipboard!');
    }
  }, [spiralType, spinRate, tightness, stepSize, numSteps, colorPreset, lineStyle, backgroundStyle, performanceMode, lineThicknessVariation]);

  const handleExport = useCallback(() => {
    const canvas = document.querySelector('canvas');
    if (!canvas) return;

    const link = document.createElement('a');
    link.download = `uzumaki-${spiralType}-${Date.now()}.png`;
    link.href = canvas.toDataURL('image/png');
    link.click();
  }, [spiralType]);

  const handleFullscreen = useCallback(() => {
    const elem = appRef.current;
    if (!elem) return;

    if (!document.fullscreenElement) {
      if (elem.requestFullscreen) {
        elem.requestFullscreen();
      } else {
        (elem as HTMLDivElement & { webkitRequestFullscreen?: () => void }).webkitRequestFullscreen?.();
      }
    } else {
      if (document.exitFullscreen) {
        document.exitFullscreen();
      } else {
        (document as Document & { webkitExitFullscreen?: () => void }).webkitExitFullscreen?.();
      }
    }
  }, []);

  const handleZoomChange = useCallback((newZoom: number) => {
    setZoom(newZoom);
  }, []);

  const handlePanChange = useCallback((newPanX: number, newPanY: number) => {
    setPanX(newPanX);
    setPanY(newPanY);
  }, []);

  const handleLineStyleChange = useCallback((style: LineStyle) => {
    setLineStyle(style);
  }, []);

  const handleBackgroundStyleChange = useCallback((style: BackgroundStyle) => {
    setBackgroundStyle(style);
  }, []);

  const handlePerformanceModeChange = useCallback((enabled: boolean) => {
    setPerformanceMode(enabled);
  }, []);

  const handleLineThicknessVariationChange = useCallback((enabled: boolean) => {
    setLineThicknessVariation(enabled);
  }, []);

  const handleShowShortcuts = useCallback(() => {
    setShowShortcuts(true);
  }, []);

  // Keyboard shortcuts
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      // Ignore if user is typing in an input
      if (e.target instanceof HTMLInputElement) return;

      switch (e.key.toLowerCase()) {
        case ' ':
          e.preventDefault();
          setIsPaused(p => !p);
          break;
        case 'r':
          handleReset();
          break;
        case 'f':
          handleFullscreen();
          break;
        case 'e':
          handleExport();
          break;
        case '?':
          setShowShortcuts(s => !s);
          break;
        case 'escape':
          setShowShortcuts(false);
          break;
        case 'arrowleft':
          setSpinRate(r => Math.max(0, r - 0.1));
          break;
        case 'arrowright':
          setSpinRate(r => Math.min(2, r + 0.1));
          break;
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [handleExport, handleFullscreen, handleReset]);

  const dynamicBg = getBackgroundStyle();

  return (
    <div
      className="app"
      ref={appRef}
      role="application"
      aria-label="Uzumaki Spiral Visualizer"
      data-bg={backgroundStyle}
      style={dynamicBg ? { background: dynamicBg } : undefined}
    >
      {/* Header/Branding */}
      <header className="header">
        <SpiralIcon size={32} color="url(#spiral-gradient)" className="logo" />
        <h1 className="title">UZUMAKI</h1>
        <svg width="0" height="0">
          <defs>
            <linearGradient id="spiral-gradient" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" stopColor="#48dbfb" />
              <stop offset="100%" stopColor="#ff6b6b" />
            </linearGradient>
          </defs>
        </svg>
      </header>

      {/* Zoom/Pan Indicator */}
      <div className="zoom-indicator">
        <span>Zoom: <span className="zoom-value">{zoom.toFixed(1)}x</span></span>
        {(panX !== 0 || panY !== 0) && (
          <span>Pan: {Math.round(panX)}, {Math.round(panY)}</span>
        )}
      </div>

      <SpiralCanvas
        params={params}
        onZoomChange={handleZoomChange}
        onPanChange={handlePanChange}
      />

      <Controls
        spiralType={spiralType}
        spinRate={spinRate}
        tightness={tightness}
        stepSize={stepSize}
        numSteps={numSteps}
        isPaused={isPaused}
        colorPreset={colorPreset}
        lineStyle={lineStyle}
        backgroundStyle={backgroundStyle}
        performanceMode={performanceMode}
        lineThicknessVariation={lineThicknessVariation}
        onTypeChange={handleTypeChange}
        onSpinRateChange={handleSpinRateChange}
        onTightnessChange={handleTightnessChange}
        onStepSizeChange={handleStepSizeChange}
        onNumStepsChange={handleNumStepsChange}
        onPauseToggle={handlePauseToggle}
        onReset={handleReset}
        onColorChange={handleColorChange}
        onPresetLoad={handlePresetLoad}
        onExport={handleExport}
        onFullscreen={handleFullscreen}
        onShare={handleShare}
        onLineStyleChange={handleLineStyleChange}
        onBackgroundStyleChange={handleBackgroundStyleChange}
        onPerformanceModeChange={handlePerformanceModeChange}
        onLineThicknessVariationChange={handleLineThicknessVariationChange}
        onShowShortcuts={handleShowShortcuts}
      />

      {/* Onboarding hint for first-time users */}
      {showOnboarding && (
        <div className={`onboarding-hint ${hasInteracted.current ? 'hiding' : ''}`}>
          <span className="hint-icon"><MouseIcon size={24} /></span>
          <span className="hint-text">Scroll to zoom - Drag to pan</span>
          <span className="hint-subtext">Click anywhere to dismiss</span>
        </div>
      )}

      {/* Toast notifications */}
      {toast && (
        <div className="toast" role="status" aria-live="polite" aria-atomic="true">
          {toast}
        </div>
      )}

      {/* Keyboard shortcuts modal */}
      {showShortcuts && (
        <>
          <div className="shortcuts-backdrop" onClick={() => setShowShortcuts(false)} />
          <div className="shortcuts-panel">
            <h2 className="shortcuts-title">⌨️ Keyboard Shortcuts</h2>
            <div className="shortcut-row">
              <span className="shortcut-key">Space</span>
              <span className="shortcut-desc">Play / Pause</span>
            </div>
            <div className="shortcut-row">
              <span className="shortcut-key">R</span>
              <span className="shortcut-desc">Reset</span>
            </div>
            <div className="shortcut-row">
              <span className="shortcut-key">E</span>
              <span className="shortcut-desc">Export PNG</span>
            </div>
            <div className="shortcut-row">
              <span className="shortcut-key">F</span>
              <span className="shortcut-desc">Fullscreen</span>
            </div>
            <div className="shortcut-row">
              <span className="shortcut-key">←/→</span>
              <span className="shortcut-desc">Adjust speed</span>
            </div>
            <div className="shortcut-row">
              <span className="shortcut-key">?</span>
              <span className="shortcut-desc">Toggle shortcuts</span>
            </div>
            <div className="shortcut-row">
              <span className="shortcut-key">Esc</span>
              <span className="shortcut-desc">Close this panel</span>
            </div>
          </div>
        </>
      )}

      {/* Hidden screen reader text */}
      <div className="sr-only" aria-live="polite">
        Keyboard shortcuts: Space to pause/play, R to reset, F for fullscreen, E to export
      </div>
    </div>
  );
}

export default App;

