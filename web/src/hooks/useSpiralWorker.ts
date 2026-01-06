/**
 * Hook for managing spiral generation Web Worker with OffscreenCanvas support.
 * Provides automatic fallback for browsers without OffscreenCanvas support.
 * Includes retry mechanism and error recovery.
 */

import { useEffect, useRef, useCallback, useState } from 'react';
import { SpiralParams } from '../utils/spirals';
import { supportsOffscreenCanvas } from '../utils/spiralTypedArrays';
import type { WorkerMessage, WorkerResponse } from '../workers/spiralWorker';

/** Maximum number of retry attempts for worker creation */
const MAX_RETRY_ATTEMPTS = 3;
/** Delay between retry attempts in milliseconds */
const RETRY_DELAY_MS = 1000;

export interface UseSpiralWorkerOptions {
  /** Enable OffscreenCanvas rendering (worker handles all rendering) */
  useOffscreenCanvas?: boolean;
  /** Callback when worker completes a render (OffscreenCanvas mode) */
  onRenderComplete?: () => void;
  /** Callback when worker encounters an error (for user notification) */
  onError?: (message: string) => void;
}

export interface UseSpiralWorkerResult {
  /** Whether OffscreenCanvas is being used */
  isOffscreenMode: boolean;
  /** Whether the worker is ready */
  isReady: boolean;
  /** Whether the worker has been created (but may not be ready yet) */
  isWorkerCreated: boolean;
  /** Request the worker to render (OffscreenCanvas mode) */
  requestRender: (params: SpiralParams, width: number, height: number) => void;
  /** Initialize with an OffscreenCanvas. Returns true if transfer succeeded. */
  initOffscreenCanvas: (canvas: HTMLCanvasElement) => boolean;
  /** Check if worker is supported */
  isSupported: boolean;
  /** Whether canvas control was transferred (even if worker setup failed after) */
  isCanvasTransferred: boolean;
  /** Synchronous check if canvas has been transferred (for use before state updates) */
  checkCanvasTransferred: () => boolean;
  /** Whether the worker has failed and fallen back to main thread */
  hasFallback: boolean;
  /** Number of retry attempts made */
  retryCount: number;
}

/**
 * Hook to use Web Worker for spiral generation/rendering
 */
export function useSpiralWorker(
  options: UseSpiralWorkerOptions = {}
): UseSpiralWorkerResult {
  const { useOffscreenCanvas = true, onRenderComplete, onError } = options;

  const workerRef = useRef<Worker | null>(null);
  const [isReady, setIsReady] = useState(false);
  const [isWorkerCreated, setIsWorkerCreated] = useState(false);
  const [isOffscreenMode, setIsOffscreenMode] = useState(false);
  const [isCanvasTransferred, setIsCanvasTransferred] = useState(false);
  const [hasFallback, setHasFallback] = useState(false);
  const [retryCount, setRetryCount] = useState(0);
  // Sync ref to track transfer immediately (state updates are async)
  const isCanvasTransferredRef = useRef(false);
  const pendingRenderRef = useRef<{ params: SpiralParams; width: number; height: number } | null>(null);
  const isRenderingRef = useRef(false);
  const retryTimeoutRef = useRef<number | null>(null);
  const onErrorRef = useRef(onError);

  // Keep onError ref updated
  onErrorRef.current = onError;

  // Check browser support
  const isSupported = typeof Worker !== 'undefined';
  const canUseOffscreen = useOffscreenCanvas && supportsOffscreenCanvas();

  // Create worker with retry logic
  const createWorker = useCallback((attempt: number = 0): boolean => {
    try {
      workerRef.current = new Worker(
        new URL('../workers/spiralWorker.ts', import.meta.url),
        { type: 'module' }
      );
      setIsWorkerCreated(true);
      setRetryCount(attempt);

      workerRef.current.onmessage = (e: MessageEvent<WorkerResponse>) => {
        const { type } = e.data;

        switch (type) {
          case 'ready':
            setIsReady(true);
            setIsOffscreenMode(true);
            // Process any pending render
            if (pendingRenderRef.current) {
              const { params, width, height } = pendingRenderRef.current;
              pendingRenderRef.current = null;
              requestRenderInternal(params, width, height);
            }
            break;

          case 'rendered':
            isRenderingRef.current = false;
            onRenderComplete?.();
            // Check if there's a pending render request
            if (pendingRenderRef.current) {
              const { params, width, height } = pendingRenderRef.current;
              pendingRenderRef.current = null;
              requestRenderInternal(params, width, height);
            }
            break;
        }
      };

      workerRef.current.onerror = (error) => {
        console.warn(`Spiral worker error (attempt ${attempt + 1}/${MAX_RETRY_ATTEMPTS}):`, error);

        // Terminate the failed worker
        workerRef.current?.terminate();
        workerRef.current = null;

        // Attempt retry if under limit and canvas not yet transferred
        if (attempt < MAX_RETRY_ATTEMPTS - 1 && !isCanvasTransferredRef.current) {
          setRetryCount(attempt + 1);
          retryTimeoutRef.current = window.setTimeout(() => {
            createWorker(attempt + 1);
          }, RETRY_DELAY_MS);
        } else {
          // Max retries reached, fall back to main thread
          setIsReady(false);
          setIsWorkerCreated(false);
          setIsOffscreenMode(false);
          setHasFallback(true);

          // Notify user via callback
          onErrorRef.current?.('Rendering switched to main thread for better compatibility');
        }
      };

      return true;
    } catch (error) {
      console.warn(`Failed to create spiral worker (attempt ${attempt + 1}):`, error);

      if (attempt < MAX_RETRY_ATTEMPTS - 1) {
        setRetryCount(attempt + 1);
        retryTimeoutRef.current = window.setTimeout(() => {
          createWorker(attempt + 1);
        }, RETRY_DELAY_MS);
      } else {
        setIsWorkerCreated(false);
        setHasFallback(true);
        onErrorRef.current?.('Using fallback rendering mode');
      }
      return false;
    }
  }, [onRenderComplete]);

  // Initialize worker
  useEffect(() => {
    if (!isSupported) {
      setHasFallback(true);
      return;
    }

    createWorker(0);

    return () => {
      // Clean up retry timeout
      if (retryTimeoutRef.current !== null) {
        clearTimeout(retryTimeoutRef.current);
        retryTimeoutRef.current = null;
      }
      workerRef.current?.terminate();
      workerRef.current = null;
    };
  }, [isSupported, createWorker]);

  // Internal render request (doesn't check pending)
  const requestRenderInternal = useCallback((
    params: SpiralParams,
    width: number,
    height: number
  ) => {
    if (!workerRef.current || !isOffscreenMode) return;

    isRenderingRef.current = true;
    const message: WorkerMessage = {
      type: 'render',
      params,
      width,
      height,
    };
    workerRef.current.postMessage(message);
  }, [isOffscreenMode]);

  // Request render with backpressure handling
  const requestRender = useCallback((
    params: SpiralParams,
    width: number,
    height: number
  ) => {
    if (!workerRef.current) return;

    // If currently rendering, queue this request (replacing any previous pending)
    if (isRenderingRef.current) {
      pendingRenderRef.current = { params, width, height };
      return;
    }

    requestRenderInternal(params, width, height);
  }, [requestRenderInternal]);

  // Initialize OffscreenCanvas
  const initOffscreenCanvas = useCallback((canvas: HTMLCanvasElement): boolean => {
    if (!workerRef.current || !canUseOffscreen) return false;

    try {
      const offscreen = canvas.transferControlToOffscreen();
      // CRITICAL: Mark as transferred immediately after the transfer call succeeds
      // This is irreversible - once transferred, getContext() will always fail
      // Use ref for synchronous check (state updates are async and can cause race conditions)
      isCanvasTransferredRef.current = true;
      setIsCanvasTransferred(true);

      const message: WorkerMessage = {
        type: 'init',
        canvas: offscreen,
      };
      workerRef.current.postMessage(message, [offscreen]);
      return true;
    } catch (error) {
      console.warn('Failed to transfer canvas to worker:', error);
      return false;
    }
  }, [canUseOffscreen]);

  // Synchronous check for canvas transfer (for use in effects before state updates)
  const checkCanvasTransferred = useCallback(() => isCanvasTransferredRef.current, []);

  return {
    isOffscreenMode,
    isReady,
    isWorkerCreated,
    requestRender,
    initOffscreenCanvas,
    isSupported,
    isCanvasTransferred,
    checkCanvasTransferred,
    hasFallback,
    retryCount,
  };
}

