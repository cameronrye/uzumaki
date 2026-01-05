import { useEffect, useCallback, useRef } from 'react';
import { SpiralCanvas } from './components/SpiralCanvas';
import { Controls } from './components/Controls';
import { SpiralIcon, MouseIcon } from './components/Icons';
import { SpiralProvider, useSpiralContext, useBackgroundStyle } from './context/SpiralContext';
import { copyShareURL, ShareableState } from './utils/urlState';
import {
  ANIMATION_FPS_NORMAL,
  ANIMATION_FPS_PERFORMANCE,
  TOAST_DURATION_MS,
  ONBOARDING_AUTO_HIDE_MS,
  ONBOARDING_FADE_DELAY_MS,
  RESIZE_DEBOUNCE_MS,
  VIEWPORT_SCALE_MIN,
  VIEWPORT_SCALE_MAX,
  VIEWPORT_BASE_SIZE,
  SPIN_RATE_KEYBOARD_STEP,
} from './utils/constants';

function AppContent() {
  const { state, actions, params } = useSpiralContext();
  const dynamicBg = useBackgroundStyle();

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
      const scale = Math.max(VIEWPORT_SCALE_MIN, Math.min(VIEWPORT_SCALE_MAX, minDimension / VIEWPORT_BASE_SIZE));
      actions.setViewportScale(scale);
    };

    updateViewportScale();

    let resizeTimeout: number;
    const debouncedResize = () => {
      clearTimeout(resizeTimeout);
      resizeTimeout = window.setTimeout(updateViewportScale, RESIZE_DEBOUNCE_MS);
    };

    window.addEventListener('resize', debouncedResize);
    return () => {
      window.removeEventListener('resize', debouncedResize);
      clearTimeout(resizeTimeout);
    };
  }, [actions]);

  // Animation loop with pause support and frame rate limiting
  useEffect(() => {
    if (state.isPaused || prefersReducedMotion.current) return;

    let animationId: number;
    let lastTime = performance.now();
    let lastFrameTime = 0;

    const targetFPS = state.performanceMode ? ANIMATION_FPS_PERFORMANCE : ANIMATION_FPS_NORMAL;
    const frameInterval = 1000 / targetFPS;

    const animate = (currentTime: number) => {
      const elapsed = currentTime - lastFrameTime;

      if (elapsed >= frameInterval) {
        const deltaTime = (currentTime - lastTime) / 1000;
        lastTime = currentTime;
        lastFrameTime = currentTime - (elapsed % frameInterval);

        actions.incrementTime(deltaTime);
      }

      animationId = requestAnimationFrame(animate);
    };

    animationId = requestAnimationFrame(animate);
    return () => cancelAnimationFrame(animationId);
  }, [state.isPaused, state.performanceMode, actions]);

  // Hide onboarding on first interaction
  useEffect(() => {
    if (!state.showOnboarding) return;

    const handleInteraction = () => {
      if (!hasInteracted.current) {
        hasInteracted.current = true;
        setTimeout(() => actions.setShowOnboarding(false), ONBOARDING_FADE_DELAY_MS);
      }
    };

    window.addEventListener('mousedown', handleInteraction);
    window.addEventListener('wheel', handleInteraction);
    window.addEventListener('touchstart', handleInteraction);

    // Auto-hide after delay
    const timeout = setTimeout(() => actions.setShowOnboarding(false), ONBOARDING_AUTO_HIDE_MS);

    return () => {
      window.removeEventListener('mousedown', handleInteraction);
      window.removeEventListener('wheel', handleInteraction);
      window.removeEventListener('touchstart', handleInteraction);
      clearTimeout(timeout);
    };
  }, [state.showOnboarding, actions]);

  // Toast auto-hide
  useEffect(() => {
    if (!state.toast) return;
    const timeout = setTimeout(() => actions.setToast(null), TOAST_DURATION_MS);
    return () => clearTimeout(timeout);
  }, [state.toast, actions]);

  const handleShare = useCallback(async () => {
    const shareState: ShareableState = {
      spiralType: state.spiralType,
      spinRate: state.spinRate,
      tightness: state.tightness,
      stepSize: state.stepSize,
      numSteps: state.numSteps,
      colorPreset: state.colorPreset,
      lineStyle: state.lineStyle,
      backgroundStyle: state.backgroundStyle,
      performanceMode: state.performanceMode,
      lineThicknessVariation: state.lineThicknessVariation,
      zoom: state.zoom,
      panX: state.panX,
      panY: state.panY,
    };
    const success = await copyShareURL(shareState);
    if (success) {
      actions.setToast('Link copied to clipboard!');
    }
  }, [state, actions]);

  const handleExport = useCallback(() => {
    const canvas = document.querySelector('canvas');
    if (!canvas) return;

    const link = document.createElement('a');
    link.download = `uzumaki-${state.spiralType}-${Date.now()}.png`;
    link.href = canvas.toDataURL('image/png');
    link.click();
  }, [state.spiralType]);

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

  // Keyboard shortcuts
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      // Ignore if user is typing in an input
      if (e.target instanceof HTMLInputElement) return;

      switch (e.key.toLowerCase()) {
        case ' ':
          e.preventDefault();
          actions.togglePause();
          break;
        case 'r':
          actions.reset();
          break;
        case 'f':
          handleFullscreen();
          break;
        case 'e':
          handleExport();
          break;
        case '?':
          actions.toggleShowShortcuts();
          break;
        case 'escape':
          actions.setShowShortcuts(false);
          break;
        case 'arrowleft':
          actions.adjustSpinRate(-SPIN_RATE_KEYBOARD_STEP);
          break;
        case 'arrowright':
          actions.adjustSpinRate(SPIN_RATE_KEYBOARD_STEP);
          break;
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [handleExport, handleFullscreen, actions]);

  return (
    <div
      className="app"
      ref={appRef}
      role="application"
      aria-label="Uzumaki Spiral Visualizer"
      data-bg={state.backgroundStyle}
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
        <span>Zoom: <span className="zoom-value">{state.zoom.toFixed(1)}x</span></span>
        {(state.panX !== 0 || state.panY !== 0) && (
          <span>Pan: {Math.round(state.panX)}, {Math.round(state.panY)}</span>
        )}
      </div>

      <SpiralCanvas
        params={params}
        onZoomChange={actions.setZoom}
        onPanChange={actions.setPan}
      />

      <Controls
        spiralType={state.spiralType}
        spinRate={state.spinRate}
        tightness={state.tightness}
        stepSize={state.stepSize}
        numSteps={state.numSteps}
        isPaused={state.isPaused}
        colorPreset={state.colorPreset}
        lineStyle={state.lineStyle}
        backgroundStyle={state.backgroundStyle}
        performanceMode={state.performanceMode}
        lineThicknessVariation={state.lineThicknessVariation}
        onTypeChange={actions.setSpiralType}
        onSpinRateChange={actions.setSpinRate}
        onTightnessChange={actions.setTightness}
        onStepSizeChange={actions.setStepSize}
        onNumStepsChange={actions.setNumSteps}
        onPauseToggle={actions.togglePause}
        onReset={actions.reset}
        onColorChange={actions.setColorPreset}
        onPresetLoad={actions.loadPreset}
        onExport={handleExport}
        onFullscreen={handleFullscreen}
        onShare={handleShare}
        onLineStyleChange={actions.setLineStyle}
        onBackgroundStyleChange={actions.setBackgroundStyle}
        onPerformanceModeChange={actions.setPerformanceMode}
        onLineThicknessVariationChange={actions.setLineThicknessVariation}
        onShowShortcuts={() => actions.setShowShortcuts(true)}
      />

      {/* Onboarding hint for first-time users */}
      {state.showOnboarding && (
        <div className={`onboarding-hint ${hasInteracted.current ? 'hiding' : ''}`}>
          <span className="hint-icon"><MouseIcon size={24} /></span>
          <span className="hint-text">Scroll to zoom - Drag to pan</span>
          <span className="hint-subtext">Click anywhere to dismiss</span>
        </div>
      )}

      {/* Toast notifications */}
      {state.toast && (
        <div className="toast" role="status" aria-live="polite" aria-atomic="true">
          {state.toast}
        </div>
      )}

      {/* Keyboard shortcuts modal */}
      {state.showShortcuts && (
        <>
          <div className="shortcuts-backdrop" onClick={() => actions.setShowShortcuts(false)} />
          <div className="shortcuts-panel">
            <h2 className="shortcuts-title">Keyboard Shortcuts</h2>
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
              <span className="shortcut-key">left/right</span>
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

// Wrap with provider
function App() {
  return (
    <SpiralProvider>
      <AppContent />
    </SpiralProvider>
  );
}

export default App;

