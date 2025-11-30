// WORLD_OLLAMA Display Preferences Store
// Manages user preferences for window size, theme, and background
// with localStorage persistence

import { writable } from 'svelte/store';

export type WindowSizePreset = 'small' | 'medium' | 'large' | 'fullscreen';
export type Theme = 'light' | 'dark' | 'system';
export type Background = 'default' | 'solid' | 'grid' | 'gradient';

export interface DisplayPreferences {
    windowSize: WindowSizePreset;
    theme: Theme;
    background: Background;
}

const STORAGE_KEY = 'world_ollama_display';

const defaultPreferences: DisplayPreferences = {
    windowSize: 'medium',
    theme: 'system',
    background: 'default',
};

function getInitialPreferences(): DisplayPreferences {
    if (typeof window === 'undefined') return defaultPreferences;

    try {
        const stored = localStorage.getItem(STORAGE_KEY);
        if (stored) {
            return { ...defaultPreferences, ...JSON.parse(stored) };
        }
    } catch (e) {
        console.warn('[DisplayPreferences] Failed to load from localStorage:', e);
    }

    return defaultPreferences;
}

function createDisplayPreferencesStore() {
    const { subscribe, set, update } = writable<DisplayPreferences>(getInitialPreferences());

    // Subscribe to changes and persist to localStorage
    subscribe((value) => {
        if (typeof window !== 'undefined') {
            try {
                localStorage.setItem(STORAGE_KEY, JSON.stringify(value));
            } catch (e) {
                console.error('[DisplayPreferences] Failed to save to localStorage:', e);
            }
        }
    });

    return {
        subscribe,
        set,
        update,
        reset: () => set(defaultPreferences),
    };
}

export const displayPreferences = createDisplayPreferencesStore();
