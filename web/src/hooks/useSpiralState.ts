import { useReducer, useCallback, useRef } from 'react';
import {
  SpiralType,
  ColorPreset,
  LineStyle,
  BackgroundStyle,
  DEFAULT_ZOOM,
  SpiralPreset,
} from '../utils/spirals';
import { decodeStateFromURL, ShareableState } from '../utils/urlState';
import { SPIN_RATE_MIN, SPIN_RATE_MAX } from '../utils/constants';

// Default values for reset
export const DEFAULTS = {
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

export interface SpiralState {
  // Spiral parameters
  spiralType: SpiralType;
  spinRate: number;
  tightness: number;
  stepSize: number;
  numSteps: number;
  // Appearance
  colorPreset: ColorPreset;
  lineStyle: LineStyle;
  backgroundStyle: BackgroundStyle;
  // Options
  performanceMode: boolean;
  lineThicknessVariation: boolean;
  // Viewport
  zoom: number;
  panX: number;
  panY: number;
  // Animation
  time: number;
  isPaused: boolean;
  viewportScale: number;
  // UI state
  showOnboarding: boolean;
  showShortcuts: boolean;
  toast: string | null;
}

type SpiralAction =
  | { type: 'SET_SPIRAL_TYPE'; payload: SpiralType }
  | { type: 'SET_SPIN_RATE'; payload: number }
  | { type: 'SET_TIGHTNESS'; payload: number }
  | { type: 'SET_STEP_SIZE'; payload: number }
  | { type: 'SET_NUM_STEPS'; payload: number }
  | { type: 'SET_COLOR_PRESET'; payload: ColorPreset }
  | { type: 'SET_LINE_STYLE'; payload: LineStyle }
  | { type: 'SET_BACKGROUND_STYLE'; payload: BackgroundStyle }
  | { type: 'SET_PERFORMANCE_MODE'; payload: boolean }
  | { type: 'SET_LINE_THICKNESS_VARIATION'; payload: boolean }
  | { type: 'SET_ZOOM'; payload: number }
  | { type: 'SET_PAN'; payload: { panX: number; panY: number } }
  | { type: 'SET_TIME'; payload: number }
  | { type: 'INCREMENT_TIME'; payload: number }
  | { type: 'TOGGLE_PAUSE' }
  | { type: 'SET_VIEWPORT_SCALE'; payload: number }
  | { type: 'SET_SHOW_ONBOARDING'; payload: boolean }
  | { type: 'SET_SHOW_SHORTCUTS'; payload: boolean }
  | { type: 'TOGGLE_SHOW_SHORTCUTS' }
  | { type: 'SET_TOAST'; payload: string | null }
  | { type: 'LOAD_PRESET'; payload: SpiralPreset }
  | { type: 'RESET' }
  | { type: 'ADJUST_SPIN_RATE'; payload: number };

function spiralReducer(state: SpiralState, action: SpiralAction): SpiralState {
  switch (action.type) {
    case 'SET_SPIRAL_TYPE':
      return {
        ...state,
        spiralType: action.payload,
        zoom: DEFAULT_ZOOM[action.payload],
        panX: 0,
        panY: 0,
      };
    case 'SET_SPIN_RATE':
      return { ...state, spinRate: action.payload };
    case 'SET_TIGHTNESS':
      return { ...state, tightness: action.payload };
    case 'SET_STEP_SIZE':
      return { ...state, stepSize: action.payload };
    case 'SET_NUM_STEPS':
      return { ...state, numSteps: action.payload };
    case 'SET_COLOR_PRESET':
      return { ...state, colorPreset: action.payload };
    case 'SET_LINE_STYLE':
      return { ...state, lineStyle: action.payload };
    case 'SET_BACKGROUND_STYLE':
      return { ...state, backgroundStyle: action.payload };
    case 'SET_PERFORMANCE_MODE':
      return { ...state, performanceMode: action.payload };
    case 'SET_LINE_THICKNESS_VARIATION':
      return { ...state, lineThicknessVariation: action.payload };
    case 'SET_ZOOM':
      return { ...state, zoom: action.payload };
    case 'SET_PAN':
      return { ...state, panX: action.payload.panX, panY: action.payload.panY };
    case 'SET_TIME':
      return { ...state, time: action.payload };
    case 'INCREMENT_TIME':
      return { ...state, time: state.time + action.payload };
    case 'TOGGLE_PAUSE':
      return { ...state, isPaused: !state.isPaused };
    case 'SET_VIEWPORT_SCALE':
      return { ...state, viewportScale: action.payload };
    case 'SET_SHOW_ONBOARDING':
      return { ...state, showOnboarding: action.payload };
    case 'SET_SHOW_SHORTCUTS':
      return { ...state, showShortcuts: action.payload };
    case 'TOGGLE_SHOW_SHORTCUTS':
      return { ...state, showShortcuts: !state.showShortcuts };
    case 'SET_TOAST':
      return { ...state, toast: action.payload };
    case 'ADJUST_SPIN_RATE':
      return {
        ...state,
        spinRate: Math.max(SPIN_RATE_MIN, Math.min(SPIN_RATE_MAX, state.spinRate + action.payload)),
      };
    case 'LOAD_PRESET': {
      const preset = action.payload;
      const newType = preset.params.type ?? state.spiralType;
      return {
        ...state,
        spiralType: newType,
        spinRate: preset.params.spinRate ?? state.spinRate,
        tightness: preset.params.tightness ?? state.tightness,
        stepSize: preset.params.stepSize ?? state.stepSize,
        numSteps: preset.params.numSteps ?? state.numSteps,
        colorPreset: preset.params.colorPreset ?? state.colorPreset,
        lineStyle: preset.params.lineStyle ?? state.lineStyle,
        zoom: preset.params.zoom ?? DEFAULT_ZOOM[newType],
        panX: 0,
        panY: 0,
      };
    }
    case 'RESET':
      return {
        ...state,
        ...DEFAULTS,
        zoom: DEFAULT_ZOOM[DEFAULTS.spiralType],
        panX: 0,
        panY: 0,
        time: 0,
        isPaused: false,
      };
    default:
      return state;
  }
}

function createInitialState(urlState: Partial<ShareableState> | null): SpiralState {
  const initialSpiralType = urlState?.spiralType ?? DEFAULTS.spiralType;
  return {
    spiralType: initialSpiralType,
    spinRate: urlState?.spinRate ?? DEFAULTS.spinRate,
    tightness: urlState?.tightness ?? DEFAULTS.tightness,
    stepSize: urlState?.stepSize ?? DEFAULTS.stepSize,
    numSteps: urlState?.numSteps ?? DEFAULTS.numSteps,
    colorPreset: urlState?.colorPreset ?? DEFAULTS.colorPreset,
    lineStyle: urlState?.lineStyle ?? DEFAULTS.lineStyle,
    backgroundStyle: urlState?.backgroundStyle ?? DEFAULTS.backgroundStyle,
    performanceMode: urlState?.performanceMode ?? DEFAULTS.performanceMode,
    lineThicknessVariation: urlState?.lineThicknessVariation ?? DEFAULTS.lineThicknessVariation,
    zoom: urlState?.zoom ?? DEFAULT_ZOOM[initialSpiralType],
    panX: urlState?.panX ?? 0,
    panY: urlState?.panY ?? 0,
    time: 0,
    isPaused: false,
    viewportScale: 1,
    showOnboarding: !urlState,
    showShortcuts: false,
    toast: null,
  };
}

export interface SpiralActions {
  setSpiralType: (type: SpiralType) => void;
  setSpinRate: (rate: number) => void;
  setTightness: (value: number) => void;
  setStepSize: (value: number) => void;
  setNumSteps: (value: number) => void;
  setColorPreset: (preset: ColorPreset) => void;
  setLineStyle: (style: LineStyle) => void;
  setBackgroundStyle: (style: BackgroundStyle) => void;
  setPerformanceMode: (enabled: boolean) => void;
  setLineThicknessVariation: (enabled: boolean) => void;
  setZoom: (zoom: number) => void;
  setPan: (panX: number, panY: number) => void;
  incrementTime: (delta: number) => void;
  togglePause: () => void;
  setViewportScale: (scale: number) => void;
  setShowOnboarding: (show: boolean) => void;
  setShowShortcuts: (show: boolean) => void;
  toggleShowShortcuts: () => void;
  setToast: (message: string | null) => void;
  loadPreset: (preset: SpiralPreset) => void;
  reset: () => void;
  adjustSpinRate: (delta: number) => void;
}

export function useSpiralState(): [SpiralState, SpiralActions] {
  const urlState = useRef(decodeStateFromURL());
  const [state, dispatch] = useReducer(spiralReducer, urlState.current, createInitialState);

  const actions: SpiralActions = {
    setSpiralType: useCallback((type: SpiralType) => {
      dispatch({ type: 'SET_SPIRAL_TYPE', payload: type });
    }, []),
    setSpinRate: useCallback((rate: number) => {
      dispatch({ type: 'SET_SPIN_RATE', payload: rate });
    }, []),
    setTightness: useCallback((value: number) => {
      dispatch({ type: 'SET_TIGHTNESS', payload: value });
    }, []),
    setStepSize: useCallback((value: number) => {
      dispatch({ type: 'SET_STEP_SIZE', payload: value });
    }, []),
    setNumSteps: useCallback((value: number) => {
      dispatch({ type: 'SET_NUM_STEPS', payload: value });
    }, []),
    setColorPreset: useCallback((preset: ColorPreset) => {
      dispatch({ type: 'SET_COLOR_PRESET', payload: preset });
    }, []),
    setLineStyle: useCallback((style: LineStyle) => {
      dispatch({ type: 'SET_LINE_STYLE', payload: style });
    }, []),
    setBackgroundStyle: useCallback((style: BackgroundStyle) => {
      dispatch({ type: 'SET_BACKGROUND_STYLE', payload: style });
    }, []),
    setPerformanceMode: useCallback((enabled: boolean) => {
      dispatch({ type: 'SET_PERFORMANCE_MODE', payload: enabled });
    }, []),
    setLineThicknessVariation: useCallback((enabled: boolean) => {
      dispatch({ type: 'SET_LINE_THICKNESS_VARIATION', payload: enabled });
    }, []),
    setZoom: useCallback((zoom: number) => {
      dispatch({ type: 'SET_ZOOM', payload: zoom });
    }, []),
    setPan: useCallback((panX: number, panY: number) => {
      dispatch({ type: 'SET_PAN', payload: { panX, panY } });
    }, []),
    incrementTime: useCallback((delta: number) => {
      dispatch({ type: 'INCREMENT_TIME', payload: delta });
    }, []),
    togglePause: useCallback(() => {
      dispatch({ type: 'TOGGLE_PAUSE' });
    }, []),
    setViewportScale: useCallback((scale: number) => {
      dispatch({ type: 'SET_VIEWPORT_SCALE', payload: scale });
    }, []),
    setShowOnboarding: useCallback((show: boolean) => {
      dispatch({ type: 'SET_SHOW_ONBOARDING', payload: show });
    }, []),
    setShowShortcuts: useCallback((show: boolean) => {
      dispatch({ type: 'SET_SHOW_SHORTCUTS', payload: show });
    }, []),
    toggleShowShortcuts: useCallback(() => {
      dispatch({ type: 'TOGGLE_SHOW_SHORTCUTS' });
    }, []),
    setToast: useCallback((message: string | null) => {
      dispatch({ type: 'SET_TOAST', payload: message });
    }, []),
    loadPreset: useCallback((preset: SpiralPreset) => {
      dispatch({ type: 'LOAD_PRESET', payload: preset });
    }, []),
    reset: useCallback(() => {
      dispatch({ type: 'RESET' });
      window.history.replaceState({}, '', window.location.pathname);
    }, []),
    adjustSpinRate: useCallback((delta: number) => {
      dispatch({ type: 'ADJUST_SPIN_RATE', payload: delta });
    }, []),
  };

  return [state, actions];
}

