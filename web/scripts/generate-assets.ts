/**
 * Asset Generation Script
 *
 * Generates screenshots and animated GIFs for README documentation.
 * Uses Playwright to capture the spiral visualizations.
 *
 * Usage: npx tsx scripts/generate-assets.ts
 *
 * Requirements:
 * - npm install --save-dev playwright
 * - npx playwright install chromium
 * - For GIF generation: gifski (brew install gifski) or ffmpeg
 */

import { chromium, type Browser, type Page } from 'playwright';
import { spawn, type ChildProcess } from 'child_process';
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Configuration
const BASE_URL = 'http://localhost:5173';
const OUTPUT_DIR = '../../assets/screenshots'; // Repo root assets folder
const ASSETS_ROOT = '../../assets';
const SCREENSHOT_DELAY = 1500; // ms to wait for animation to settle

// Viewport configurations for different aspect ratios
const VIEWPORTS = {
  landscape: { width: 1920, height: 1080 },
  standard: { width: 1280, height: 720 },
  square: { width: 1080, height: 1080 },
  portrait: { width: 1080, height: 1920 },
  thumbnail: { width: 640, height: 360 },
};

const VIEWPORT = VIEWPORTS.standard; // Default viewport

// Spiral-specific optimal configurations for screenshots
// Each spiral type has parameters tuned for best visual representation
interface SpiralConfig {
  type: string;
  line?: string;
  tight?: string;
  pts?: string;
  step?: string;
  color?: string;
  bg?: string;
}

const SPIRAL_CONFIGS: SpiralConfig[] = [
  { type: 'archimedean', color: 'rainbow', bg: 'dark' },
  { type: 'fibonacci', color: 'aurora', bg: 'gradient' },
  { type: 'fermat', color: 'sunset', bg: 'dark' },
  { type: 'logarithmic', pts: '300', color: 'ocean', bg: 'black' },
  { type: 'hyperbolic', tight: '5', color: 'fire', bg: 'gradient' },
  { type: 'lituus', tight: '4', color: 'neon', bg: 'dark' },
  { type: 'theodorus', line: 'triangles', pts: '50', tight: '5', color: 'candy', bg: 'matching' },
  { type: 'vogel', line: 'points', pts: '800', tight: '2', color: 'sunset', bg: 'black' },
  { type: 'curlicue', pts: '1000', tight: '1', color: 'matrix', bg: 'dark' },
  { type: 'uzumaki', tight: '5', pts: '600', color: 'retro', bg: 'gradient' },
];

// Color presets to capture
const COLOR_PRESETS = [
  'rainbow', 'fire', 'ocean', 'neon', 'monochrome',
  'sunset', 'aurora', 'candy', 'matrix', 'retro'
];

// Line styles to capture (excluding special modes like 'points' and 'triangles')
const LINE_STYLES = ['solid', 'dashed', 'dotted', 'glow'];

// Background styles to capture
const BACKGROUND_STYLES = ['dark', 'black', 'gradient', 'matching'];

// Parameter ranges for variation screenshots
const PARAMETER_RANGES = {
  tight: ['1', '3', '5', '8', '12'],
  pts: ['100', '300', '500', '800', '1200'],
};

// Combination matrix for diverse screenshots
const COMBO_MATRIX = {
  spirals: ['fibonacci', 'vogel', 'uzumaki', 'logarithmic', 'fermat', 'archimedean'],
  colors: ['aurora', 'sunset', 'neon', 'ocean', 'fire', 'rainbow'],
  lines: ['glow', 'solid', 'dashed', 'dotted'],
  bgs: ['dark', 'black', 'gradient', 'matching'],
};

// Featured presets for hero images - expanded for more variety
const FEATURED_CONFIGS = [
  { name: 'hero', type: 'fibonacci', color: 'aurora', line: 'glow', bg: 'dark' },
  { name: 'sunflower', type: 'vogel', color: 'sunset', line: 'points', bg: 'black', pts: '1000', tight: '2' },
  { name: 'chaos', type: 'uzumaki', color: 'neon', line: 'glow', bg: 'gradient', tight: '5', pts: '600' },
  { name: 'ocean-log', type: 'logarithmic', color: 'ocean', line: 'solid', bg: 'gradient', pts: '400' },
  { name: 'fire-fermat', type: 'fermat', color: 'fire', line: 'glow', bg: 'black' },
  { name: 'matrix-curlicue', type: 'curlicue', color: 'matrix', line: 'solid', bg: 'dark', pts: '1200', tight: '1' },
  { name: 'retro-theodorus', type: 'theodorus', color: 'retro', line: 'triangles', bg: 'matching', pts: '50', tight: '5' },
  { name: 'candy-lituus', type: 'lituus', color: 'candy', line: 'dashed', bg: 'dark', tight: '3' },
  { name: 'rainbow-archimedean', type: 'archimedean', color: 'rainbow', line: 'glow', bg: 'gradient' },
  { name: 'monochrome-hyperbolic', type: 'hyperbolic', color: 'monochrome', line: 'solid', bg: 'black', tight: '6' },
];

// Seeded random for reproducible "random" selections
function seededRandom(seed: number): () => number {
  return function() {
    seed = (seed * 1103515245 + 12345) & 0x7fffffff;
    return seed / 0x7fffffff;
  };
}

// Get a random element from array using seeded random
function randomChoice<T>(arr: T[], random: () => number): T {
  return arr[Math.floor(random() * arr.length)];
}

let devServer: ChildProcess | null = null;

async function startDevServer(): Promise<void> {
  return new Promise((resolve, reject) => {
    console.log('Starting dev server...');
    devServer = spawn('npm', ['run', 'dev'], {
      cwd: path.join(__dirname, '..'),
      stdio: ['ignore', 'pipe', 'pipe'],
      shell: true,
    });

    devServer.stdout?.on('data', (data: Buffer) => {
      const output = data.toString();
      if (output.includes('Local:') || output.includes('localhost:5173')) {
        console.log('Dev server started');
        setTimeout(resolve, 1000); // Give it a moment to fully initialize
      }
    });

    devServer.stderr?.on('data', (data: Buffer) => {
      console.error('Dev server error:', data.toString());
    });

    devServer.on('error', reject);

    // Timeout after 30 seconds
    setTimeout(() => reject(new Error('Dev server start timeout')), 30000);
  });
}

function stopDevServer(): void {
  if (devServer) {
    console.log('Stopping dev server...');
    devServer.kill('SIGTERM');
    devServer = null;
  }
}

function ensureDir(dir: string): void {
  const fullPath = path.join(__dirname, dir);
  if (!fs.existsSync(fullPath)) {
    fs.mkdirSync(fullPath, { recursive: true });
  }
}

function buildURL(params: Record<string, string>): string {
  const searchParams = new URLSearchParams();
  if (params.type) searchParams.set('type', params.type);
  if (params.color) searchParams.set('color', params.color);
  if (params.line) searchParams.set('line', params.line);
  if (params.bg) searchParams.set('bg', params.bg);
  if (params.tight) searchParams.set('tight', params.tight);
  if (params.pts) searchParams.set('pts', params.pts);
  if (params.step) searchParams.set('step', params.step);
  if (params.spin) searchParams.set('spin', params.spin);
  return `${BASE_URL}?${searchParams.toString()}`;
}

async function captureScreenshot(
  page: Page,
  params: Record<string, string>,
  outputPath: string
): Promise<void> {
  const url = buildURL(params);
  await page.goto(url);
  await page.waitForTimeout(SCREENSHOT_DELAY);

  // Pause animation for consistent screenshots by pressing Space
  await page.keyboard.press('Space');
  await page.waitForTimeout(100);

  // Hide UI elements for clean screenshot
  await page.evaluate(() => {
    const controls = document.querySelector('.controls') as HTMLElement;
    const header = document.querySelector('.header') as HTMLElement;
    if (controls) controls.style.display = 'none';
    if (header) header.style.display = 'none';
  });

  await page.screenshot({ path: outputPath, type: 'png' });
  console.log(`  Captured: ${outputPath}`);
}

async function captureGifFrames(
  page: Page,
  params: Record<string, string>,
  outputDir: string,
  frameCount: number = 60,
  frameDelay: number = 50
): Promise<string[]> {
  const url = buildURL(params);
  await page.goto(url);
  await page.waitForTimeout(1000);

  // Hide UI elements
  await page.evaluate(() => {
    const controls = document.querySelector('.controls') as HTMLElement;
    const header = document.querySelector('.header') as HTMLElement;
    if (controls) controls.style.display = 'none';
    if (header) header.style.display = 'none';
  });

  const frames: string[] = [];
  for (let i = 0; i < frameCount; i++) {
    const framePath = path.join(outputDir, `frame_${String(i).padStart(4, '0')}.png`);
    await page.screenshot({ path: framePath, type: 'png' });
    frames.push(framePath);
    await page.waitForTimeout(frameDelay);
  }

  return frames;
}

async function createGif(framesDir: string, outputPath: string): Promise<void> {
  return new Promise((resolve, reject) => {
    const inputPattern = path.join(framesDir, 'frame_*.png');

    // Try ffmpeg first (more commonly available)
    console.log('  Creating GIF with ffmpeg...');
    const ffmpegCmd = `ffmpeg -y -framerate 20 -pattern_type glob -i "${inputPattern}" -vf "scale=640:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" "${outputPath}"`;

    const ffmpeg = spawn('sh', ['-c', ffmpegCmd]);

    ffmpeg.stderr?.on('data', () => {
      // Suppress ffmpeg output
    });

    ffmpeg.on('close', (code) => {
      if (code === 0) {
        console.log(`  Created GIF: ${outputPath}`);
        resolve();
      } else {
        // Fallback to gifski
        console.log('  ffmpeg failed, trying gifski...');
        const gifskiCmd = `gifski --fps 20 --quality 90 --output "${outputPath}" ${inputPattern}`;
        const gifski = spawn('sh', ['-c', gifskiCmd]);

        gifski.on('close', (code2) => {
          if (code2 === 0) {
            console.log(`  Created GIF: ${outputPath}`);
            resolve();
          } else {
            reject(new Error('Failed to create GIF with both ffmpeg and gifski'));
          }
        });
      }
    });
  });
}

function cleanupFrames(dir: string): void {
  if (fs.existsSync(dir)) {
    const files = fs.readdirSync(dir);
    for (const file of files) {
      if (file.startsWith('frame_') && file.endsWith('.png')) {
        fs.unlinkSync(path.join(dir, file));
      }
    }
  }
}

async function generateSpiralScreenshots(browser: Browser): Promise<void> {
  console.log('\nGenerating spiral type screenshots...');
  const page = await browser.newPage();
  await page.setViewportSize(VIEWPORT);

  ensureDir(`${OUTPUT_DIR}/spirals`);

  for (const config of SPIRAL_CONFIGS) {
    const params: Record<string, string> = {
      type: config.type,
      color: config.color || 'aurora',
      line: config.line || 'glow',
      bg: config.bg || 'dark',
    };
    // Add optional parameters
    if (config.tight) params.tight = config.tight;
    if (config.pts) params.pts = config.pts;
    if (config.step) params.step = config.step;

    await captureScreenshot(
      page,
      params,
      path.join(__dirname, OUTPUT_DIR, 'spirals', `${config.type}.png`)
    );
  }

  await page.close();
}

async function generateColorScreenshots(browser: Browser): Promise<void> {
  console.log('\nGenerating color preset screenshots...');
  const page = await browser.newPage();
  await page.setViewportSize(VIEWPORT);

  ensureDir(`${OUTPUT_DIR}/colors`);

  // Use different spiral types for each color to show variety
  const spiralTypes = ['fibonacci', 'logarithmic', 'fermat', 'archimedean', 'vogel',
                       'uzumaki', 'hyperbolic', 'lituus', 'curlicue', 'theodorus'];
  const lineStyles = ['glow', 'solid', 'dashed', 'glow', 'points',
                      'glow', 'solid', 'dashed', 'solid', 'triangles'];

  for (let i = 0; i < COLOR_PRESETS.length; i++) {
    const color = COLOR_PRESETS[i];
    const type = spiralTypes[i % spiralTypes.length];
    const line = lineStyles[i % lineStyles.length];
    await captureScreenshot(
      page,
      { type, color, line, bg: 'dark' },
      path.join(__dirname, OUTPUT_DIR, 'colors', `${color}.png`)
    );
  }

  await page.close();
}

async function generateStyleScreenshots(browser: Browser): Promise<void> {
  console.log('\nGenerating line style screenshots...');
  const page = await browser.newPage();
  await page.setViewportSize(VIEWPORT);

  ensureDir(`${OUTPUT_DIR}/styles`);

  // Use different spiral types and colors for each line style
  const styleConfigs = [
    { line: 'solid', type: 'fibonacci', color: 'sunset' },
    { line: 'dashed', type: 'logarithmic', color: 'ocean' },
    { line: 'dotted', type: 'fermat', color: 'candy' },
    { line: 'glow', type: 'uzumaki', color: 'neon' },
  ];

  for (const config of styleConfigs) {
    await captureScreenshot(
      page,
      { type: config.type, color: config.color, line: config.line, bg: 'dark' },
      path.join(__dirname, OUTPUT_DIR, 'styles', `${config.line}.png`)
    );
  }

  await page.close();
}

async function generateThemeScreenshots(browser: Browser): Promise<void> {
  console.log('\nGenerating theme screenshots...');
  const page = await browser.newPage();
  await page.setViewportSize(VIEWPORT);

  ensureDir(`${OUTPUT_DIR}/themes`);

  // Use different spiral/color combos for each theme
  const themeConfigs = [
    { bg: 'dark', type: 'fibonacci', color: 'aurora', line: 'glow' },
    { bg: 'black', type: 'vogel', color: 'fire', line: 'points' },
    { bg: 'gradient', type: 'uzumaki', color: 'neon', line: 'glow' },
    { bg: 'matching', type: 'theodorus', color: 'ocean', line: 'triangles' },
  ];

  for (const config of themeConfigs) {
    await captureScreenshot(
      page,
      { type: config.type, color: config.color, line: config.line, bg: config.bg },
      path.join(__dirname, OUTPUT_DIR, 'themes', `${config.bg}.png`)
    );
  }

  await page.close();
}

async function generateParameterVariations(browser: Browser): Promise<void> {
  console.log('\nGenerating parameter variation screenshots...');
  const page = await browser.newPage();
  await page.setViewportSize(VIEWPORT);

  ensureDir(`${OUTPUT_DIR}/variations`);

  // Tightness variations for fibonacci
  console.log('  Capturing tightness variations...');
  for (const tight of PARAMETER_RANGES.tight) {
    await captureScreenshot(
      page,
      { type: 'fibonacci', color: 'aurora', line: 'glow', bg: 'dark', tight, pts: '400' },
      path.join(__dirname, OUTPUT_DIR, 'variations', `fibonacci-tight-${tight}.png`)
    );
  }

  // Points variations for vogel
  console.log('  Capturing point count variations...');
  for (const pts of PARAMETER_RANGES.pts) {
    await captureScreenshot(
      page,
      { type: 'vogel', color: 'sunset', line: 'points', bg: 'black', pts, tight: '2' },
      path.join(__dirname, OUTPUT_DIR, 'variations', `vogel-pts-${pts}.png`)
    );
  }

  // Curlicue with different point counts
  console.log('  Capturing curlicue variations...');
  for (const pts of ['500', '1000', '2000']) {
    await captureScreenshot(
      page,
      { type: 'curlicue', color: 'matrix', line: 'solid', bg: 'dark', pts, tight: '1' },
      path.join(__dirname, OUTPUT_DIR, 'variations', `curlicue-pts-${pts}.png`)
    );
  }

  await page.close();
}

async function generateComboScreenshots(browser: Browser): Promise<void> {
  console.log('\nGenerating combination screenshots...');
  const page = await browser.newPage();
  await page.setViewportSize(VIEWPORT);

  ensureDir(`${OUTPUT_DIR}/combos`);

  // Use seeded random for reproducible combinations
  const random = seededRandom(42);

  // Generate diverse combinations
  let comboIndex = 0;
  for (const spiral of COMBO_MATRIX.spirals) {
    // Pick complementary options for each spiral
    const color = randomChoice(COMBO_MATRIX.colors, random);
    const line = randomChoice(COMBO_MATRIX.lines, random);
    const bg = randomChoice(COMBO_MATRIX.bgs, random);

    const params: Record<string, string> = { type: spiral, color, line, bg };

    // Add appropriate parameters based on spiral type
    if (['vogel', 'curlicue'].includes(spiral)) {
      params.pts = randomChoice(['500', '800', '1000'], random);
    }
    if (['hyperbolic', 'lituus', 'uzumaki'].includes(spiral)) {
      params.tight = randomChoice(['3', '5', '8'], random);
    }

    await captureScreenshot(
      page,
      params,
      path.join(__dirname, OUTPUT_DIR, 'combos', `combo-${String(comboIndex).padStart(2, '0')}-${spiral}.png`)
    );
    comboIndex++;
  }

  // Additional curated interesting combinations
  const curatedCombos = [
    { type: 'fibonacci', color: 'fire', line: 'glow', bg: 'black' },
    { type: 'vogel', color: 'aurora', line: 'points', bg: 'gradient', pts: '1200' },
    { type: 'uzumaki', color: 'candy', line: 'dashed', bg: 'matching', tight: '6' },
    { type: 'logarithmic', color: 'monochrome', line: 'solid', bg: 'dark', pts: '500' },
    { type: 'theodorus', color: 'rainbow', line: 'triangles', bg: 'black', pts: '60' },
    { type: 'fermat', color: 'matrix', line: 'dotted', bg: 'gradient' },
  ];

  for (const combo of curatedCombos) {
    const params: Record<string, string> = { ...combo };
    await captureScreenshot(
      page,
      params,
      path.join(__dirname, OUTPUT_DIR, 'combos', `combo-${String(comboIndex).padStart(2, '0')}-${combo.type}-${combo.color}.png`)
    );
    comboIndex++;
  }

  await page.close();
}

async function generateViewportVariations(browser: Browser): Promise<void> {
  console.log('\nGenerating viewport variation screenshots...');

  ensureDir(`${OUTPUT_DIR}/viewports`);

  // Hero config to use for viewport demos
  const heroParams = { type: 'fibonacci', color: 'aurora', line: 'glow', bg: 'dark' };

  for (const [name, viewport] of Object.entries(VIEWPORTS)) {
    const page = await browser.newPage();
    await page.setViewportSize(viewport);

    await captureScreenshot(
      page,
      heroParams,
      path.join(__dirname, OUTPUT_DIR, 'viewports', `${name}-${viewport.width}x${viewport.height}.png`)
    );

    await page.close();
  }
}

async function generateHeroAssets(browser: Browser): Promise<void> {
  console.log('\nGenerating hero images and demo GIFs...');
  const page = await browser.newPage();
  await page.setViewportSize(VIEWPORT);

  ensureDir(OUTPUT_DIR);
  const framesDir = path.join(__dirname, OUTPUT_DIR, 'frames');
  ensureDir('../assets/screenshots/frames');

  // Generate hero screenshots
  for (const config of FEATURED_CONFIGS) {
    const params: Record<string, string> = {
      type: config.type,
      color: config.color,
      line: config.line,
      bg: config.bg,
    };
    // Add optional parameters if present
    if ('tight' in config && config.tight) params.tight = config.tight;
    if ('pts' in config && config.pts) params.pts = config.pts;

    await captureScreenshot(
      page,
      params,
      path.join(__dirname, OUTPUT_DIR, `${config.name}.png`)
    );
  }

  // Generate multiple demo GIFs with different spirals
  const gifConfigs = [
    { name: 'demo', type: 'uzumaki', color: 'rainbow', line: 'dashed', bg: 'gradient', tight: '5', pts: '600', spin: '0.5' },
    { name: 'demo-fibonacci', type: 'fibonacci', color: 'aurora', line: 'glow', bg: 'dark', spin: '0.3' },
    { name: 'demo-vogel', type: 'vogel', color: 'sunset', line: 'points', bg: 'black', pts: '800', tight: '2', spin: '0.2' },
  ];

  for (const gifConfig of gifConfigs) {
    console.log(`\n  Capturing ${gifConfig.name} GIF frames...`);
    const { name, ...params } = gifConfig;

    await captureGifFrames(
      page,
      params as Record<string, string>,
      framesDir,
      80, // 4 seconds at 20fps
      50
    );

    // Create GIF
    try {
      await createGif(framesDir, path.join(__dirname, ASSETS_ROOT, `${name}.gif`));
    } catch (error) {
      console.warn(`  Warning: Could not create ${name}.gif. Install gifski or ffmpeg.`);
    }

    // Cleanup frames
    cleanupFrames(framesDir);
  }

  await page.close();
}

async function main(): Promise<void> {
  console.log('=== Uzumaki Asset Generator ===\n');

  try {
    await startDevServer();

    const browser = await chromium.launch({ headless: true });

    // Core screenshots
    await generateHeroAssets(browser);
    await generateSpiralScreenshots(browser);
    await generateColorScreenshots(browser);
    await generateStyleScreenshots(browser);
    await generateThemeScreenshots(browser);

    // Variation screenshots
    await generateParameterVariations(browser);
    await generateComboScreenshots(browser);
    await generateViewportVariations(browser);

    await browser.close();
    console.log('\n=== Asset generation complete! ===');
    console.log(`\nAssets saved to: ${path.join(__dirname, OUTPUT_DIR)}`);

  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  } finally {
    stopDevServer();
  }
}

main();

