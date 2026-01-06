import { useCallback, useRef } from 'react';

/**
 * Returns a throttled version of the callback that only fires once per delay period.
 * Uses leading-edge throttling: callback fires immediately, then ignores subsequent calls
 * until the delay has passed.
 * 
 * @param callback The function to throttle
 * @param delay Minimum time between invocations in milliseconds
 * @returns Throttled callback function
 */
export function useThrottledCallback<T extends (...args: Parameters<T>) => void>(
  callback: T,
  delay: number
): T {
  const lastCallRef = useRef<number>(0);
  const callbackRef = useRef(callback);
  
  // Keep callback ref updated
  callbackRef.current = callback;

  return useCallback((...args: Parameters<T>) => {
    const now = Date.now();
    if (now - lastCallRef.current >= delay) {
      lastCallRef.current = now;
      callbackRef.current(...args);
    }
  }, [delay]) as T;
}

/**
 * Returns a debounced version of the callback that only fires after the delay
 * has passed since the last call.
 * 
 * @param callback The function to debounce
 * @param delay Time to wait after last call before firing in milliseconds
 * @returns Debounced callback function
 */
export function useDebouncedCallback<T extends (...args: Parameters<T>) => void>(
  callback: T,
  delay: number
): T {
  const timeoutRef = useRef<number | null>(null);
  const callbackRef = useRef(callback);
  
  // Keep callback ref updated
  callbackRef.current = callback;

  return useCallback((...args: Parameters<T>) => {
    if (timeoutRef.current !== null) {
      clearTimeout(timeoutRef.current);
    }
    timeoutRef.current = window.setTimeout(() => {
      callbackRef.current(...args);
    }, delay);
  }, [delay]) as T;
}

/** Default throttle delay for slider inputs (16ms ~ 60fps) */
export const SLIDER_THROTTLE_MS = 16;

/** Default debounce delay for URL state updates */
export const URL_UPDATE_DEBOUNCE_MS = 300;

