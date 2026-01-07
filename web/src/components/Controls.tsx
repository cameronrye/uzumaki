import { useState, useCallback, useEffect, useRef, useMemo } from 'react';
import { Link } from 'react-router-dom';
import {
  SpiralType,
  SPIRAL_TYPES,
  ColorPreset,
  COLOR_PRESETS,
  SPIRAL_PRESETS,
  SpiralPreset,
  LineStyle,
  LINE_STYLES,
  BackgroundStyle,
  BACKGROUND_STYLES
} from '../utils/spirals';
import {
  PlayIcon,
  PauseIcon,
  ResetIcon,
  DownloadIcon,
  FullscreenIcon,
  ShareIcon,
  ChevronDownIcon,
  ChevronUpIcon,
  SparklesIcon,
  KeyboardIcon,
  AppleIcon
} from './Icons';
import './Controls.css';

interface ControlsProps {
  spiralType: SpiralType;
  spinRate: number;
  tightness: number;
  stepSize: number;
  numSteps: number;
  isPaused: boolean;
  colorPreset: ColorPreset;
  lineStyle: LineStyle;
  backgroundStyle: BackgroundStyle;
  performanceMode: boolean;
  lineThicknessVariation: boolean;
  onTypeChange: (type: SpiralType) => void;
  onSpinRateChange: (value: number) => void;
  onTightnessChange: (value: number) => void;
  onStepSizeChange: (value: number) => void;
  onNumStepsChange: (value: number) => void;
  onPauseToggle: () => void;
  onReset: () => void;
  onColorChange: (preset: ColorPreset) => void;
  onPresetLoad: (preset: SpiralPreset) => void;
  onExport: () => void;
  onFullscreen: () => void;
  onShare: () => void;
  onLineStyleChange: (style: LineStyle) => void;
  onBackgroundStyleChange: (style: BackgroundStyle) => void;
  onPerformanceModeChange: (enabled: boolean) => void;
  onLineThicknessVariationChange: (enabled: boolean) => void;
  onShowShortcuts: () => void;
}

export function Controls({
  spiralType,
  spinRate,
  tightness,
  stepSize,
  numSteps,
  isPaused,
  colorPreset,
  lineStyle,
  backgroundStyle,
  performanceMode,
  lineThicknessVariation,
  onTypeChange,
  onSpinRateChange,
  onTightnessChange,
  onStepSizeChange,
  onNumStepsChange,
  onPauseToggle,
  onReset,
  onColorChange,
  onPresetLoad,
  onExport,
  onFullscreen,
  onShare,
  onLineStyleChange,
  onBackgroundStyleChange,
  onPerformanceModeChange,
  onLineThicknessVariationChange,
  onShowShortcuts,
}: ControlsProps) {
  const [showTypeSelector, setShowTypeSelector] = useState(false);
  const [showPresets, setShowPresets] = useState(false);
  const [showColors, setShowColors] = useState(false);
  const [showLineStyles, setShowLineStyles] = useState(false);
  const [showBackgrounds, setShowBackgrounds] = useState(false);
  const [isExpanded, setIsExpanded] = useState(true);

  // Refs for dropdown containers (Fix #3: click-outside)
  const typeSelectorRef = useRef<HTMLDivElement>(null);
  const colorSelectorRef = useRef<HTMLDivElement>(null);
  const lineStyleSelectorRef = useRef<HTMLDivElement>(null);
  const backgroundSelectorRef = useRef<HTMLDivElement>(null);
  const presetSelectorRef = useRef<HTMLDivElement>(null);

  // Fix #3: Close dropdowns when clicking outside
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      const target = event.target as Node;

      if (showTypeSelector && typeSelectorRef.current && !typeSelectorRef.current.contains(target)) {
        setShowTypeSelector(false);
      }
      if (showColors && colorSelectorRef.current && !colorSelectorRef.current.contains(target)) {
        setShowColors(false);
      }
      if (showLineStyles && lineStyleSelectorRef.current && !lineStyleSelectorRef.current.contains(target)) {
        setShowLineStyles(false);
      }
      if (showBackgrounds && backgroundSelectorRef.current && !backgroundSelectorRef.current.contains(target)) {
        setShowBackgrounds(false);
      }
      if (showPresets && presetSelectorRef.current && !presetSelectorRef.current.contains(target)) {
        setShowPresets(false);
      }
    };

    // Close dropdowns on Escape key
    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        setShowTypeSelector(false);
        setShowColors(false);
        setShowLineStyles(false);
        setShowBackgrounds(false);
        setShowPresets(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    document.addEventListener('keydown', handleKeyDown);

    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
      document.removeEventListener('keydown', handleKeyDown);
    };
  }, [showTypeSelector, showColors, showLineStyles, showBackgrounds, showPresets]);

  // Fix #8: Memoize lookups (with fallback to first item, guaranteed to exist)
  const currentTypeInfo = useMemo(() => {
    const found = SPIRAL_TYPES.find(t => t.type === spiralType);
    const fallback = SPIRAL_TYPES[0];
    return found ?? fallback ?? { type: 'archimedean' as const, name: 'Archimedean', description: '' };
  }, [spiralType]);
  const currentColorInfo = useMemo(() => {
    const found = COLOR_PRESETS.find(c => c.id === colorPreset);
    const fallback = COLOR_PRESETS[0];
    return found ?? fallback ?? { id: 'rainbow' as const, name: 'Rainbow', colors: ['#ffffff'] };
  }, [colorPreset]);
  const currentLineStyleInfo = useMemo(() => {
    const found = LINE_STYLES.find(l => l.id === lineStyle);
    const fallback = LINE_STYLES[0];
    return found ?? fallback ?? { id: 'solid' as const, name: 'Solid' };
  }, [lineStyle]);
  const currentBackgroundInfo = useMemo(() => {
    const found = BACKGROUND_STYLES.find(b => b.id === backgroundStyle);
    const fallback = BACKGROUND_STYLES[0];
    return found ?? fallback ?? { id: 'dark' as const, name: 'Dark', color: '#000000' };
  }, [backgroundStyle]);

  const handleTypeSelect = useCallback((type: SpiralType) => {
    onTypeChange(type);
    setShowTypeSelector(false);
  }, [onTypeChange]);

  const handlePresetSelect = useCallback((preset: SpiralPreset) => {
    onPresetLoad(preset);
    setShowPresets(false);
  }, [onPresetLoad]);

  const handleColorSelect = useCallback((color: ColorPreset) => {
    onColorChange(color);
    setShowColors(false);
  }, [onColorChange]);

  const handleLineStyleSelect = useCallback((style: LineStyle) => {
    onLineStyleChange(style);
    setShowLineStyles(false);
  }, [onLineStyleChange]);

  const handleBackgroundSelect = useCallback((style: BackgroundStyle) => {
    onBackgroundStyleChange(style);
    setShowBackgrounds(false);
  }, [onBackgroundStyleChange]);

  // Calculate slider fill percentages
  const getSliderFill = (value: number, min: number, max: number) => {
    return ((value - min) / (max - min)) * 100;
  };

  return (
    <div className={`controls ${isExpanded ? 'expanded' : 'collapsed'}`}>
      {/* Always visible: Minimal controls bar */}
      <div className="controls-header">
        <div className="controls-row actions-row">
          <button
            className="action-btn"
            onClick={onPauseToggle}
            aria-label={isPaused ? 'Play animation (Space)' : 'Pause animation (Space)'}
            data-tooltip={isPaused ? 'Play (Space)' : 'Pause (Space)'}
          >
            {isPaused ? <PlayIcon size={18} /> : <PauseIcon size={18} />}
          </button>
          <button
            className="action-btn"
            onClick={onReset}
            aria-label="Reset to defaults (R)"
            data-tooltip="Reset (R)"
          >
            <ResetIcon size={18} />
          </button>

          <span className="action-divider" />

          <button
            className="action-btn"
            onClick={onExport}
            aria-label="Export as PNG (E)"
            data-tooltip="Export (E)"
          >
            <DownloadIcon size={18} />
          </button>
          <button
            className="action-btn"
            onClick={onShare}
            aria-label="Copy share link"
            data-tooltip="Share"
          >
            <ShareIcon size={18} />
          </button>
          <button
            className="action-btn"
            onClick={onFullscreen}
            aria-label="Toggle fullscreen (F)"
            data-tooltip="Fullscreen (F)"
          >
            <FullscreenIcon size={18} />
          </button>

          <span className="action-divider" />

          <button
            className="action-btn"
            onClick={onShowShortcuts}
            aria-label="Keyboard shortcuts"
            data-tooltip="Shortcuts"
          >
            <KeyboardIcon size={18} />
          </button>

          <span className="action-divider" />

          <Link
            to="/app"
            className="action-btn"
            aria-label="Get the app"
            data-tooltip="Get App"
          >
            <AppleIcon size={18} />
          </Link>

          {/* Expand/Collapse toggle */}
          <button
            className={`action-btn expand-toggle ${isExpanded ? 'expanded' : ''}`}
            onClick={() => setIsExpanded(!isExpanded)}
            aria-label={isExpanded ? 'Collapse controls' : 'Expand controls'}
            aria-expanded={isExpanded}
            data-tooltip={isExpanded ? 'Collapse' : 'Expand'}
          >
            {isExpanded ? <ChevronDownIcon size={18} /> : <ChevronUpIcon size={18} />}
          </button>
        </div>
      </div>

      {/* Expandable content */}
      {isExpanded && (
        <>
          <div className="section-divider" />

          {/* Section 2: Spiral Type & Appearance */}
          <div className="control-section">
            <div className="controls-row config-row">
              {/* Spiral Type */}
              <div className="control-group type-selector" ref={typeSelectorRef}>
                <button
                  className="config-button"
                  onClick={() => setShowTypeSelector(!showTypeSelector)}
                  aria-haspopup="listbox"
                  aria-expanded={showTypeSelector}
                >
                  <div className="config-button-content">
                    <span className="config-label">Spiral</span>
                    <span className="config-value">{currentTypeInfo.name}</span>
                  </div>
                  <ChevronDownIcon size={12} />
                </button>

                {showTypeSelector && (
                  <div className="dropdown-menu" role="listbox">
                    {SPIRAL_TYPES.map((type) => (
                      <button
                        key={type.type}
                        className={`dropdown-item ${type.type === spiralType ? 'active' : ''}`}
                        onClick={() => handleTypeSelect(type.type)}
                        role="option"
                        aria-selected={type.type === spiralType}
                      >
                        <span className="item-name">{type.name}</span>
                        <span className="item-desc">{type.description}</span>
                      </button>
                    ))}
                  </div>
                )}
              </div>

              {/* Color selector */}
              <div className="control-group color-selector" ref={colorSelectorRef}>
                <button
                  className="config-button"
                  onClick={() => setShowColors(!showColors)}
                  aria-haspopup="listbox"
                  aria-expanded={showColors}
                >
                  <span
                    className="color-preview"
                    style={{
                      background: `linear-gradient(90deg, ${currentColorInfo.colors.join(', ')})`
                    }}
                  />
                  <span className="config-value">{currentColorInfo.name}</span>
                  <ChevronDownIcon size={12} />
                </button>

                {showColors && (
                  <div className="dropdown-menu color-menu" role="listbox">
                    {COLOR_PRESETS.map((color) => (
                      <button
                        key={color.id}
                        className={`dropdown-item color-item ${color.id === colorPreset ? 'active' : ''}`}
                        onClick={() => handleColorSelect(color.id)}
                        role="option"
                        aria-selected={color.id === colorPreset}
                      >
                        <span
                          className="color-preview"
                          style={{
                            background: `linear-gradient(90deg, ${color.colors.join(', ')})`
                          }}
                        />
                        <span>{color.name}</span>
                      </button>
                    ))}
                  </div>
                )}
              </div>

              {/* Style dropdown (combines Line Style + Background) */}
              <div className="control-group style-selector" ref={lineStyleSelectorRef}>
                <button
                  className="config-button"
                  onClick={() => setShowLineStyles(!showLineStyles)}
                  aria-haspopup="listbox"
                  aria-expanded={showLineStyles}
                >
                  <div className="config-button-content">
                    <span className="config-label">Style</span>
                    <span className="config-value">{currentLineStyleInfo.name}</span>
                  </div>
                  <ChevronDownIcon size={12} />
                </button>

                {showLineStyles && (
                  <div className="dropdown-menu" role="listbox">
                    {LINE_STYLES.map((style) => (
                      <button
                        key={style.id}
                        className={`dropdown-item ${style.id === lineStyle ? 'active' : ''}`}
                        onClick={() => handleLineStyleSelect(style.id)}
                        role="option"
                        aria-selected={style.id === lineStyle}
                      >
                        {style.name}
                      </button>
                    ))}
                  </div>
                )}
              </div>

              {/* Background Style */}
              <div className="control-group bg-selector" ref={backgroundSelectorRef}>
                <button
                  className="config-button"
                  onClick={() => setShowBackgrounds(!showBackgrounds)}
                  aria-haspopup="listbox"
                  aria-expanded={showBackgrounds}
                >
                  <div className="config-button-content">
                    <span className="config-label">Theme</span>
                    <span className="config-value">{currentBackgroundInfo.name}</span>
                  </div>
                  <ChevronDownIcon size={12} />
                </button>

                {showBackgrounds && (
                  <div className="dropdown-menu" role="listbox">
                    {BACKGROUND_STYLES.map((style) => (
                      <button
                        key={style.id}
                        className={`dropdown-item ${style.id === backgroundStyle ? 'active' : ''}`}
                        onClick={() => handleBackgroundSelect(style.id)}
                        role="option"
                        aria-selected={style.id === backgroundStyle}
                      >
                        {style.name}
                      </button>
                    ))}
                  </div>
                )}
              </div>

              {/* Presets */}
              <div className="control-group preset-selector" ref={presetSelectorRef}>
                <button
                  className="config-button preset-button"
                  onClick={() => setShowPresets(!showPresets)}
                  aria-haspopup="listbox"
                  aria-expanded={showPresets}
                >
                  <SparklesIcon size={14} />
                  <span>Presets</span>
                  <ChevronDownIcon size={12} />
                </button>

                {showPresets && (
                  <div className="dropdown-menu preset-menu" role="listbox">
                    {SPIRAL_PRESETS.map((preset, i) => (
                      <button
                        key={i}
                        className="dropdown-item"
                        onClick={() => handlePresetSelect(preset)}
                        role="option"
                      >
                        {preset.name}
                      </button>
                    ))}
                  </div>
                )}
              </div>
            </div>
          </div>

          <div className="section-divider" />

          {/* Section 3: Parameters (2x2 grid) */}
          <div className="control-section">
            <div className="sliders-grid">
              <div className="control-group slider-group">
                <label htmlFor="spinRate">
                  <span className="label-text">Speed</span>
                  <span className="label-value">{spinRate.toFixed(2)}</span>
                </label>
                <div className="slider-container">
                  <input
                    id="spinRate"
                    type="range"
                    min="0"
                    max="2"
                    step="0.01"
                    value={spinRate}
                    onChange={(e) => onSpinRateChange(parseFloat(e.target.value))}
                    aria-label={`Spin rate: ${spinRate.toFixed(2)}`}
                  />
                  <div className="slider-track">
                    <div className="slider-fill" style={{ width: `${getSliderFill(spinRate, 0, 2)}%` }} />
                  </div>
                </div>
              </div>

              <div className="control-group slider-group">
                <label htmlFor="tightness">
                  <span className="label-text">Tightness</span>
                  <span className="label-value">{tightness.toFixed(1)}</span>
                </label>
                <div className="slider-container">
                  <input
                    id="tightness"
                    type="range"
                    min="0.5"
                    max="10"
                    step="0.1"
                    value={tightness}
                    onChange={(e) => onTightnessChange(parseFloat(e.target.value))}
                    aria-label={`Tightness: ${tightness.toFixed(1)}`}
                  />
                  <div className="slider-track">
                    <div className="slider-fill" style={{ width: `${getSliderFill(tightness, 0.5, 10)}%` }} />
                  </div>
                </div>
              </div>

              <div className="control-group slider-group">
                <label htmlFor="stepSize">
                  <span className="label-text">Detail</span>
                  <span className="label-value">{stepSize.toFixed(2)}</span>
                </label>
                <div className="slider-container">
                  <input
                    id="stepSize"
                    type="range"
                    min="0.01"
                    max="0.5"
                    step="0.01"
                    value={stepSize}
                    onChange={(e) => onStepSizeChange(parseFloat(e.target.value))}
                    aria-label={`Step size: ${stepSize.toFixed(2)}`}
                  />
                  <div className="slider-track">
                    <div className="slider-fill" style={{ width: `${getSliderFill(stepSize, 0.01, 0.5)}%` }} />
                  </div>
                </div>
              </div>

              <div className="control-group slider-group">
                <label htmlFor="numSteps">
                  <span className="label-text">Points</span>
                  <span className="label-value">{numSteps}</span>
                </label>
                <div className="slider-container">
                  <input
                    id="numSteps"
                    type="range"
                    min="50"
                    max="2000"
                    step="10"
                    value={numSteps}
                    onChange={(e) => onNumStepsChange(parseInt(e.target.value))}
                    aria-label={`Number of points: ${numSteps}`}
                  />
                  <div className="slider-track">
                    <div className="slider-fill" style={{ width: `${getSliderFill(numSteps, 50, 2000)}%` }} />
                  </div>
                </div>
              </div>
            </div>

            {/* Toggles integrated below sliders */}
            <div className="controls-row toggles-row">
              <button
                className={`toggle-chip ${lineThicknessVariation ? 'active' : ''}`}
                onClick={() => onLineThicknessVariationChange(!lineThicknessVariation)}
                aria-pressed={lineThicknessVariation}
              >
                <span className="toggle-indicator" />
                Variable Thickness
              </button>
              <button
                className={`toggle-chip ${performanceMode ? 'active' : ''}`}
                onClick={() => onPerformanceModeChange(!performanceMode)}
                aria-pressed={performanceMode}
              >
                <span className="toggle-indicator" />
                Performance Mode
              </button>
            </div>
          </div>

          {/* Footer hint */}
          <div className="controls-footer">
            <span className="footer-hint">Scroll to zoom • Drag to pan</span>
            <span className="footer-divider" />
            <span className="footer-credit">
              Made with <span className="heart">❤️</span> by{' '}
              <a href="https://rye.dev" target="_blank" rel="noopener noreferrer">
                Cameron Rye
              </a>
            </span>
          </div>
        </>
      )}
    </div>
  );
}

