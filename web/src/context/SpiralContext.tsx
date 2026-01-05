import { createContext, useContext, ReactNode, useMemo } from 'react';
import { useSpiralState, SpiralState, SpiralActions } from '../hooks/useSpiralState';
import { SpiralParams, COLOR_PRESETS } from '../utils/spirals';
import { NUM_STEPS_PERFORMANCE_MAX } from '../utils/constants';

interface SpiralContextValue {
  state: SpiralState;
  actions: SpiralActions;
  params: SpiralParams;
}

const SpiralContext = createContext<SpiralContextValue | null>(null);

interface SpiralProviderProps {
  children: ReactNode;
}

export function SpiralProvider({ children }: SpiralProviderProps) {
  const [state, actions] = useSpiralState();

  // Memoize params to prevent unnecessary object recreation on every render.
  // This is critical for performance as params is passed to canvas and worker.
  const params = useMemo<SpiralParams>(() => ({
    type: state.spiralType,
    tightness: state.tightness,
    spinRate: state.spinRate,
    stepSize: state.stepSize,
    numSteps: state.performanceMode
      ? Math.min(state.numSteps, NUM_STEPS_PERFORMANCE_MAX)
      : state.numSteps,
    time: state.time,
    viewportScale: state.viewportScale,
    isPaused: state.isPaused,
    colorPreset: state.colorPreset,
    zoom: state.zoom,
    panX: state.panX,
    panY: state.panY,
    lineStyle: state.lineStyle,
    backgroundStyle: state.backgroundStyle,
    performanceMode: state.performanceMode,
    lineThicknessVariation: state.lineThicknessVariation,
  }), [
    state.spiralType,
    state.tightness,
    state.spinRate,
    state.stepSize,
    state.numSteps,
    state.performanceMode,
    state.time,
    state.viewportScale,
    state.isPaused,
    state.colorPreset,
    state.zoom,
    state.panX,
    state.panY,
    state.lineStyle,
    state.backgroundStyle,
    state.lineThicknessVariation,
  ]);

  return (
    <SpiralContext.Provider value={{ state, actions, params }}>
      {children}
    </SpiralContext.Provider>
  );
}

export function useSpiralContext(): SpiralContextValue {
  const context = useContext(SpiralContext);
  if (!context) {
    throw new Error('useSpiralContext must be used within a SpiralProvider');
  }
  return context;
}

// Helper hook for getting the background style
export function useBackgroundStyle(): string | undefined {
  const { state } = useSpiralContext();
  
  if (state.backgroundStyle === 'matching') {
    const colorInfo = COLOR_PRESETS.find(c => c.id === state.colorPreset);
    if (colorInfo) {
      return `radial-gradient(circle at center, ${colorInfo.colors[0]}22 0%, #0a0a0f 100%)`;
    }
  }
  return undefined;
}

