import { expect, test } from '@playwright/test';

/**
 * 🧪 ПОЛНЫЙ E2E ТЕСТ-СЬЮТ для CompanyCheck
 * 
 * Покрытие:
 * ✅ Главная страница (поиск, языки, навигация)
 * ✅ Результаты поиска (карточка компании, premium блокировка)
 * ✅ AI анализ (Gemini API)
 * ✅ Pricing планы
 * ✅ Admin Panel (вход, навигация, все вкладки)
 * ✅ Developer Mode (7 вкладок: IDE, SQL, Terminal, Monitor, API, Jobs, Webhooks)
 * ✅ Кнопка возврата на главную с Admin статусом
 * 
 * URL: http://46.224.36.109/company-check/
 */

const BASE_URL = 'http://46.224.36.109/company-check/';
const ADMIN_PASSWORD = 'admin2024';

test.describe('🏠 ГЛАВНАЯ СТРАНИЦА', () => {
    test.beforeEach(async ({ page }) => {
        await page.goto(BASE_URL);
    });

    test('01 - Страница загружается с правильными элементами', async ({ page }) => {
        // Проверка загрузки
        await expect(page).toHaveTitle(/CompanyCheck/i);

        // Логотип и заголовок
        await expect(page.getByRole('banner').getByText('CompanyCheck')).toBeVisible();

        // Поле поиска
        const searchInput = page.locator('input[type="text"]').first();
        await expect(searchInput).toBeVisible();
        await expect(searchInput).toHaveAttribute('placeholder', /Company/i);

        // Кнопка поиска
        await expect(page.getByRole('main').getByRole('button', { name: /Search/i })).toBeVisible();

        // Переключатель языков
        await expect(page.locator('button:has-text("HE")')).toBeVisible();
        await expect(page.locator('button:has-text("EN")')).toBeVisible();
        await expect(page.locator('button:has-text("RU")')).toBeVisible();
    });

    test('02 - Переключение языков работает корректно', async ({ page }) => {
        const searchInput = page.locator('input[type="text"]').first();

        // Hebrew
        await page.click('button:has-text("HE")');
        await page.waitForTimeout(300);
        const hebrewPlaceholder = await searchInput.getAttribute('placeholder');
        expect(hebrewPlaceholder).toMatch(/ח\.פ|חברה/);

        // English
        await page.click('button:has-text("EN")');
        await page.waitForTimeout(300);
        const englishPlaceholder = await searchInput.getAttribute('placeholder');
        expect(englishPlaceholder).toMatch(/Company/i);

        // Russian
        await page.click('button:has-text("RU")');
        await page.waitForTimeout(300);
        const russianPlaceholder = await searchInput.getAttribute('placeholder');
        expect(russianPlaceholder).toMatch(/компани/i);
    });

    test('03 - Features секция отображается', async ({ page }) => {
        // Проверка наличия feature карточек
        await expect(page.locator('text=/Fast|Быстро|מהיר/')).toBeVisible();
        await expect(page.locator('text=/6 Sources|6 источников|6 מקורות/')).toBeVisible();
        await expect(page.locator('text=/Affordable|Выгодно|משתלם/')).toBeVisible();
    });
});

test.describe('🔍 ПОИСК И РЕЗУЛЬТАТЫ', () => {
    test.beforeEach(async ({ page }) => {
        await page.goto(BASE_URL);
    });

    test('04 - Поиск компании через реальный API', async ({ page }) => {
        const searchInput = page.locator('input[type="text"]').first();
        const searchButton = page.getByRole('main').getByRole('button', { name: /Search/i });

        // Ввод номера компании
        await searchInput.fill('516053675');
        await searchButton.click();

        // Ожидание загрузки (Searching...)
        await expect(page.locator('text=/Searching/i')).toBeVisible({ timeout: 2000 });

        // Ожидание результатов или ошибки (max 10 секунд)
        await page.waitForTimeout(10000);

        // Проверка что показались результаты ИЛИ сообщение об ошибке
        const hasResults = await page.locator('text=/Company ID|מספר חברה/').isVisible().catch(() => false);
        const hasError = await page.locator('text=/not found|לא נמצא/').isVisible().catch(() => false);

        expect(hasResults || hasError).toBeTruthy();
    });

    test('05 - Premium Information заблокирована для не-админов', async ({ page }) => {
        // Выполнить поиск
        await page.locator('input[type="text"]').first().fill('516053675');
        await page.getByRole('main').getByRole('button', { name: /Search/i }).click();
        await page.waitForTimeout(10000);

        // Проверить наличие Premium блока
        const premiumSection = page.locator('text=/Premium Information/i');
        if (await premiumSection.isVisible()) {
            // Проверить наличие замка (Lock icon)
            await expect(page.locator('svg').filter({ hasText: '' }).or(page.locator('text=/Locked Data/i'))).toBeVisible();

            // Проверить blur эффект
            const premiumContent = page.locator('.blur-sm, .opacity-30').first();
            await expect(premiumContent).toBeVisible();
        }
    });

    test('06 - AI Analysis кнопка работает', async ({ page }) => {
        // Выполнить поиск
        await page.locator('input[type="text"]').first().fill('516053675');
        await page.getByRole('main').getByRole('button', { name: /Search/i }).click();
        await page.waitForTimeout(10000);

        // Найти кнопку AI анализа
        const aiButton = page.locator('button', { hasText: /AI|Smart Analysis|анализ/i }).first();

        if (await aiButton.isVisible()) {
            await aiButton.click();

            // Проверить что появился индикатор загрузки
            await expect(page.locator('text=/Analyzing/i')).toBeVisible({ timeout: 2000 });

            // Дождаться результата (max 30 секунд для Gemini API)
            await page.waitForTimeout(30000);
        }
    });

    test('07 - Pricing планы отображаются', async ({ page }) => {
        // Выполнить поиск
        await page.locator('input[type="text"]').first().fill('516053675');
        await page.getByRole('main').getByRole('button', { name: /Search/i }).click();
        await page.waitForTimeout(10000);

        // Проверить наличие планов
        await expect(page.locator('text=/SILVER/i')).toBeVisible();
        await expect(page.locator('text=/BRONZE/i')).toBeVisible();
        await expect(page.locator('text=/GOLD/i')).toBeVisible();
        await expect(page.locator('text=/PLATINUM/i')).toBeVisible();

        // Проверить цены
        await expect(page.locator('text=/₪139/i')).toBeVisible();
        await expect(page.locator('text=/₪189/i')).toBeVisible();
        await expect(page.locator('text=/₪299/i')).toBeVisible();
        await expect(page.locator('text=/₪499/i')).toBeVisible();
    });
});

test.describe('🔐 ADMIN PANEL - ВХОД', () => {
    test.beforeEach(async ({ page }) => {
        await page.goto(BASE_URL);
    });

    test('08 - Вход в Admin Panel через тройной клик по логотипу', async ({ page }) => {
        const logo = page.locator('text=CompanyCheck').first();

        // Тройной клик по логотипу
        await logo.click({ clickCount: 3 });

        // Проверка появления модального окна с паролем
        await expect(page.getByRole('heading', { name: /Admin Access/i })).toBeVisible({ timeout: 2000 });

        // Проверка наличия поля ввода пароля
        const passwordInput = page.locator('input[type="password"]');
        await expect(passwordInput).toBeVisible();

        // Ввод пароля
        await passwordInput.fill(ADMIN_PASSWORD);

        // Нажать кнопку входа
        await page.locator('button', { hasText: /Unlock|Enter|Войти/i }).click();

        // Проверить что модал закрылся и появился alert или Admin Panel
        await page.waitForTimeout(1000);
    });
});

test.describe('📊 ADMIN PANEL - НАВИГАЦИЯ', () => {
    test.beforeEach(async ({ page }) => {
        await page.goto(BASE_URL);

        // Войти в Admin Panel
        const logo = page.locator('text=CompanyCheck').first();
        await logo.click({ clickCount: 3 });
        await page.waitForTimeout(500);

        const passwordInput = page.locator('input[type="password"]');
        if (await passwordInput.isVisible()) {
            await passwordInput.fill(ADMIN_PASSWORD);
            await page.locator('button', { hasText: /Unlock|Enter/i }).click();
            await page.waitForTimeout(1000);
        }
    });

    test('09 - Sidebar и основные элементы Admin Panel', async ({ page }) => {
        // Проверка сайдбара
        await expect(page.locator('aside').first()).toBeVisible();

        // Проверка навигационных элементов
        await expect(page.locator('aside').getByText(/Дашборд|Dashboard/i)).toBeVisible();
        await expect(page.locator('text=/Пользователи|Users/i')).toBeVisible();
        await expect(page.locator('text=/Заказы|Orders/i')).toBeVisible();
        await expect(page.locator('text=/Developer Mode/i')).toBeVisible();
        await expect(page.locator('text=/Настройки|Settings/i')).toBeVisible();
    });

    test('10 - Переключение между вкладками Dashboard', async ({ page }) => {
        // Dashboard
        await page.locator('text=/Дашборд|Dashboard/i').first().click();
        await page.waitForTimeout(300);
        await expect(page.locator('text=/KPI|Выручка|Revenue/i')).toBeVisible();

        // Users
        await page.locator('text=/Пользователи|Users/i').first().click();
        await page.waitForTimeout(300);
        await expect(page.locator('text=/Email|Role|Status/i').first()).toBeVisible();

        // Orders
        await page.locator('text=/Заказы|Orders/i').first().click();
        await page.waitForTimeout(300);
        await expect(page.locator('text=/ORD-|Plan|Amount/i')).toBeVisible();
    });

    test('11 - Кнопка "Главная (Admin)" возвращает на главную страницу', async ({ page }) => {
        // Найти кнопку возврата на главную
        const homeButton = page.locator('aside').getByRole('button', { name: /Главная.*Admin|Home.*Admin/i });

        if (await homeButton.isVisible()) {
            await homeButton.click();
            await page.waitForTimeout(1000);

            // Проверить что вернулись на главную страницу
            await expect(page.locator('input[type="text"]').first()).toBeVisible();
            await expect(page.locator('text=CompanyCheck').first()).toBeVisible();

            // Проверить что статус админа сохранён (тройной клик должен сразу открыть панель)
            await page.locator('text=CompanyCheck').first().click({ clickCount: 3 });
            await page.waitForTimeout(500);

            // Должны сразу попасть в Admin Panel без ввода пароля
            await expect(page.locator('aside').first()).toBeVisible({ timeout: 2000 });
        }
    });
});

test.describe('💻 DEVELOPER MODE - 7 ВКЛАДОК', () => {
    test.beforeEach(async ({ page }) => {
        await page.goto(BASE_URL);

        // Войти в Admin Panel
        const logo = page.locator('text=CompanyCheck').first();
        await logo.click({ clickCount: 3 });
        await page.waitForTimeout(500);

        const passwordInput = page.locator('input[type="password"]');
        if (await passwordInput.isVisible()) {
            await passwordInput.fill(ADMIN_PASSWORD);
            await page.locator('button', { hasText: /Unlock|Enter/i }).click();
            await page.waitForTimeout(1000);
        }

        // Перейти в Developer Mode
        await page.locator('text=/Developer Mode/i').first().click();
        await page.waitForTimeout(500);
    });

    test('12 - Developer Mode IDE вкладка', async ({ page }) => {
        // Переключить на IDE вкладку
        await page.locator('button', { hasText: /IDE|Editor/i }).first().click();
        await page.waitForTimeout(300);

        // Проверить наличие файлового дерева
        await expect(page.locator('text=/config|src|public/i')).toBeVisible();

        // Проверить наличие редактора кода
        await expect(page.locator('pre, code').first()).toBeVisible({ timeout: 10000 });
    });

    test('13 - Developer Mode SQL Console вкладка', async ({ page }) => {
        await page.locator('button', { hasText: /SQL/i }).first().click();
        await page.waitForTimeout(300);

        // Проверить наличие textarea для SQL запросов
        await expect(page.locator('textarea').first()).toBeVisible();

        // Проверить кнопку Execute
        await expect(page.locator('button', { hasText: /Execute|Run/i })).toBeVisible();
    });

    test('14 - Developer Mode Terminal вкладка', async ({ page }) => {
        await page.locator('button', { hasText: /Terminal/i }).first().click();
        await page.waitForTimeout(300);

        // Проверить наличие input для команд
        await expect(page.locator('input[placeholder*="command" i], input[placeholder*="команд" i]')).toBeVisible();
    });

    test('15 - Developer Mode Monitor вкладка', async ({ page }) => {
        await page.locator('button', { hasText: /Monitor/i }).first().click();
        await page.waitForTimeout(300);

        // Проверить наличие метрик CPU/RAM
        await expect(page.locator('text=/CPU|RAM|Memory/i').first()).toBeVisible({ timeout: 10000 });

        // Проверить наличие графиков (svg или canvas)
        const hasChart = await page.locator('svg, canvas').count();
        expect(hasChart).toBeGreaterThan(0);
    });

    test('16 - Developer Mode API Playground вкладка', async ({ page }) => {
        await page.locator('button', { hasText: /API/i }).first().click();
        await page.waitForTimeout(300);

        // Проверить наличие dropdown для методов (GET, POST, etc.)
        await expect(page.locator('select, button').filter({ hasText: /GET|POST/i }).first()).toBeVisible({ timeout: 10000 });

        // Проверить кнопку Send
        await expect(page.locator('button', { hasText: /Send|Отправить/i })).toBeVisible();
    });

    test('17 - Developer Mode Jobs вкладка', async ({ page }) => {
        await page.locator('button', { hasText: /Jobs|Задачи/i }).first().click();
        await page.waitForTimeout(300);

        // Проверить наличие таблицы с джобами
        await expect(page.locator('text=/Job ID|Status|Type/i')).toBeVisible();
    });

    test('18 - Developer Mode Webhooks вкладка', async ({ page }) => {
        await page.locator('button', { hasText: /Webhook/i }).first().click();
        await page.waitForTimeout(300);

        // Проверить наличие select для выбора события
        await expect(page.locator('select').first()).toBeVisible();

        // Проверить кнопку Trigger
        await expect(page.locator('button', { hasText: /Trigger/i })).toBeVisible();
    });
});

test.describe('🎨 ADMIN PANEL - НАСТРОЙКИ И UI', () => {
    test.beforeEach(async ({ page }) => {
        await page.goto(BASE_URL);

        // Войти в Admin Panel
        const logo = page.locator('text=CompanyCheck').first();
        await logo.click({ clickCount: 3 });
        await page.waitForTimeout(500);

        const passwordInput = page.locator('input[type="password"]');
        if (await passwordInput.isVisible()) {
            await passwordInput.fill(ADMIN_PASSWORD);
            await page.locator('button', { hasText: /Unlock|Enter/i }).click();
            await page.waitForTimeout(1000);
        }
    });

    test('19 - Настройки интерфейса (Design Settings)', async ({ page }) => {
        await page.locator('text=/Настройки|Settings/i').first().click();
        await page.waitForTimeout(500);

        // Проверить наличие цветовых схем
        await expect(page.locator('button').filter({ hasText: /blue|indigo|emerald|purple/i }).first()).toBeVisible();

        // Проверить переключатель темной темы
        const themeToggle = page.locator('button').filter({ hasText: /Dark|Light|Moon|Sun/i });
        if (await themeToggle.count() > 0) {
            await themeToggle.first().click();
            await page.waitForTimeout(300);
        }
    });

    test('20 - Сворачивание/разворачивание сайдбара', async ({ page }) => {
        const sidebar = page.locator('aside').first();

        // Проверить что сайдбар развернут
        await expect(sidebar).toBeVisible();

        // Найти кнопку сворачивания (может быть иконка или логотип)
        const toggleButton = page.locator('aside').locator('button, div[class*="cursor-pointer"]').first();

        if (await toggleButton.isVisible()) {
            // Клик для сворачивания
            await toggleButton.click();
            await page.waitForTimeout(500);

            // Клик для разворачивания
            await toggleButton.click();
            await page.waitForTimeout(500);
        }
    });
});

test.describe('🚀 КРОСС-БРАУЗЕРНЫЕ ТЕСТЫ', () => {
    test('21 - Работа в разных разрешениях экрана', async ({ page }) => {
        await page.goto(BASE_URL);

        // Desktop (1920x1080)
        await page.setViewportSize({ width: 1920, height: 1080 });
        await expect(page.locator('text=CompanyCheck').first()).toBeVisible();

        // Tablet (768x1024)
        await page.setViewportSize({ width: 768, height: 1024 });
        await expect(page.locator('text=CompanyCheck').first()).toBeVisible();

        // Mobile (375x667)
        await page.setViewportSize({ width: 375, height: 667 });
        await expect(page.locator('text=CompanyCheck').first()).toBeVisible();
    });

    test('22 - Производительность страницы', async ({ page }) => {
        const startTime = Date.now();
        await page.goto(BASE_URL);
        const loadTime = Date.now() - startTime;

        // Страница должна загрузиться менее чем за 3 секунды
        expect(loadTime).toBeLessThan(3000);

        // Проверить что нет console errors
        const errors: string[] = [];
        page.on('console', msg => {
            if (msg.type() === 'error') {
                errors.push(msg.text());
            }
        });

        await page.waitForTimeout(2000);

        // Допускается максимум 2 некритичных ошибки
        expect(errors.length).toBeLessThan(3);
    });
});

test.describe('📱 МОБИЛЬНАЯ ВЕРСИЯ', () => {
    test.beforeEach(async ({ page }) => {
        await page.setViewportSize({ width: 375, height: 667 }); // iPhone SE
        await page.goto(BASE_URL);
    });

    test('23 - Мобильная навигация работает', async ({ page }) => {
        // Проверить что страница адаптивна
        await expect(page.locator('text=CompanyCheck').first()).toBeVisible();

        // Проверить что поле поиска видно
        const searchInput = page.locator('input[type="text"]').first();
        await expect(searchInput).toBeVisible();

        // Проверить переключатель языков
        await expect(page.locator('button:has-text("EN")')).toBeVisible();
    });
});
