import { useState, useRef, useEffect, useCallback, ReactNode } from 'react';
import { ChevronDownIcon } from './Icons';

export interface DropdownOption<T extends string> {
  id: T;
  name: string;
  description?: string;
  colors?: string[];
}

interface DropdownProps<T extends string> {
  options: DropdownOption<T>[];
  value: T;
  onChange: (value: T) => void;
  label?: string;
  renderTrigger?: (option: DropdownOption<T>, isOpen: boolean) => ReactNode;
  renderOption?: (option: DropdownOption<T>, isSelected: boolean) => ReactNode;
  className?: string;
  menuClassName?: string;
}

export function Dropdown<T extends string>({
  options,
  value,
  onChange,
  label,
  renderTrigger,
  renderOption,
  className = '',
  menuClassName = '',
}: DropdownProps<T>) {
  const [isOpen, setIsOpen] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);

  const foundOption = options.find(o => o.id === value);
  const fallbackOption = options[0];
  const currentOption: DropdownOption<T> = foundOption ?? fallbackOption ?? { id: value, name: value };

  // Handle click outside to close
  useEffect(() => {
    if (!isOpen) return;

    const handleClickOutside = (event: MouseEvent) => {
      if (containerRef.current && !containerRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    };

    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        setIsOpen(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    document.addEventListener('keydown', handleKeyDown);

    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
      document.removeEventListener('keydown', handleKeyDown);
    };
  }, [isOpen]);

  const handleSelect = useCallback((optionId: T) => {
    onChange(optionId);
    setIsOpen(false);
  }, [onChange]);

  const handleToggle = useCallback(() => {
    setIsOpen(prev => !prev);
  }, []);

  const defaultTrigger = (option: DropdownOption<T>, _isOpen: boolean) => (
    <div className="config-button-content">
      {label && <span className="config-label">{label}</span>}
      <span className="config-value">{option.name}</span>
    </div>
  );

  const defaultOption = (option: DropdownOption<T>, isSelected: boolean) => (
    <button
      key={option.id}
      className={`dropdown-item ${isSelected ? 'active' : ''}`}
      onClick={() => handleSelect(option.id)}
      role="option"
      aria-selected={isSelected}
    >
      <span className="item-name">{option.name}</span>
      {option.description && <span className="item-desc">{option.description}</span>}
    </button>
  );

  return (
    <div className={`control-group ${className}`} ref={containerRef}>
      <button
        className="config-button"
        onClick={handleToggle}
        aria-haspopup="listbox"
        aria-expanded={isOpen}
      >
        {(renderTrigger ?? defaultTrigger)(currentOption, isOpen)}
        <ChevronDownIcon size={12} />
      </button>

      {isOpen && (
        <div className={`dropdown-menu ${menuClassName}`} role="listbox">
          {options.map(option => 
            (renderOption ?? defaultOption)(option, option.id === value)
          )}
        </div>
      )}
    </div>
  );
}

// Specialized color dropdown component
interface ColorDropdownProps {
  options: { id: string; name: string; colors: string[] }[];
  value: string;
  onChange: (value: string) => void;
}

export function ColorDropdown({ options, value, onChange }: ColorDropdownProps) {
  return (
    <Dropdown
      options={options}
      value={value}
      onChange={onChange}
      className="color-selector"
      menuClassName="color-menu"
      renderTrigger={(option) => (
        <>
          <span
            className="color-preview"
            style={{
              background: `linear-gradient(90deg, ${option.colors?.join(', ')})`
            }}
          />
          <span className="config-value">{option.name}</span>
        </>
      )}
      renderOption={(option, isSelected) => (
        <button
          key={option.id}
          className={`dropdown-item color-item ${isSelected ? 'active' : ''}`}
          onClick={() => onChange(option.id)}
          role="option"
          aria-selected={isSelected}
        >
          <span
            className="color-preview"
            style={{
              background: `linear-gradient(90deg, ${option.colors?.join(', ')})`
            }}
          />
          <span>{option.name}</span>
        </button>
      )}
    />
  );
}

