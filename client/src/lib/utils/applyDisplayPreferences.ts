/**
 * WORLD_OLLAMA Display Preferences Tauri Integration
 * 
 * Применяет настройки отображения через Tauri Window API:
 * - Размер окна (window size presets)
 * - Тема (theme switching)
 * - Фон (background styling)
 */

import { getCurrentWindow, LogicalSize } from '@tauri-apps/api/window';
import type { DisplayPreferences, WindowSizePreset } from '$lib/stores/displayPreferences';

const appWindow = getCurrentWindow();

/**
 * Применить размер окна через Tauri API
 */
export async function applyWindowSize(size: WindowSizePreset): Promise<void> {
  try {
    switch (size) {
      case 'small':
        await appWindow.setSize(new LogicalSize(1024, 720));
        console.log('[DisplayPrefs] Window size: small (1024×720)');
        break;

      case 'medium':
        await appWindow.setSize(new LogicalSize(1280, 800));
        console.log('[DisplayPrefs] Window size: medium (1280×800)');
        break;

      case 'large':
        await appWindow.setSize(new LogicalSize(1600, 900));
        console.log('[DisplayPrefs] Window size: large (1600×900)');
        break;

      case 'fullscreen':
        await appWindow.setFullscreen(true);
        console.log('[DisplayPrefs] Window size: fullscreen');
        break;

      default:
        console.warn(`[DisplayPrefs] Unknown window size: ${size}`);
    }
  } catch (error) {
    console.error('[DisplayPrefs] Failed to apply window size:', error);
  }
}

/**
 * Получить CSS класс для фона
 */
export function getBackgroundClass(background: DisplayPreferences['background']): string {
  switch (background) {
    case 'solid':
      return 'bg-neutral-900';
    case 'grid':
      return 'bg-grid-pattern';
    case 'gradient':
      return 'bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900';
    case 'default':
    default:
      return 'bg-base-100';
  }
}

/**
 * Применить тему (через data-theme DaisyUI)
 */
export function applyTheme(theme: DisplayPreferences['theme']): void {
  if (typeof document === 'undefined') return;

  let effectiveTheme: 'light' | 'dark';

  if (theme === 'system') {
    // Определить системную тему через media query
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    effectiveTheme = prefersDark ? 'dark' : 'light';
  } else {
    effectiveTheme = theme;
  }

  document.documentElement.setAttribute('data-theme', effectiveTheme);
  console.log(`[DisplayPrefs] Theme applied: ${theme} (effective: ${effectiveTheme})`);
}

/**
 * Применить все настройки отображения сразу
 */
export async function applyAllDisplayPreferences(prefs: DisplayPreferences): Promise<void> {
  await applyWindowSize(prefs.windowSize);
  applyTheme(prefs.theme);
  // Background применяется через CSS класс в компоненте
}
