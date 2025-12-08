import { defineConfig, devices } from '@playwright/test';

/**
 * Playwright конфигурация для E2E тестов CompanyCheck
 * Тестирует production сервер: http://46.224.36.109
 */

export default defineConfig({
    testDir: './e2e',

    // Максимальное время выполнения одного теста
    timeout: 30 * 1000,

    // Ожидание элементов
    expect: {
        timeout: 5000,
    },

    // Полный отчёт в CI, краткий локально
    fullyParallel: true,

    // Не падать при первом упавшем тесте
    forbidOnly: !!process.env.CI,

    // Повтор упавших тестов
    retries: process.env.CI ? 2 : 0,

    // Количество параллельных воркеров
    workers: process.env.CI ? 1 : undefined,

    // Репортер
    reporter: [
        ['html', { outputFolder: 'playwright-report' }],
        ['list'],
    ],

    // Общие настройки для всех проектов
    use: {
        // Базовый URL (production сервер)
        baseURL: 'http://46.224.36.109',

        // Скриншоты при падении тестов
        screenshot: 'only-on-failure',

        // Видео при падении тестов
        video: 'retain-on-failure',

        // Трейс при падении
        trace: 'on-first-retry',
    },

    // Конфигурация для разных браузеров и устройств
    projects: [
        {
            name: 'chromium',
            use: { ...devices['Desktop Chrome'] },
        },

        {
            name: 'firefox',
            use: { ...devices['Desktop Firefox'] },
        },

        {
            name: 'webkit',
            use: { ...devices['Desktop Safari'] },
        },

        // Мобильные устройства
        {
            name: 'Mobile Chrome',
            use: { ...devices['Pixel 5'] },
        },
        {
            name: 'Mobile Safari',
            use: { ...devices['iPhone 12'] },
        },

        // Планшеты
        {
            name: 'iPad',
            use: { ...devices['iPad Pro'] },
        },
    ],

    // Веб-сервер не нужен (тестируем production)
    // webServer: undefined,
});
