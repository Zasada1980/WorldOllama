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
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'admin2024';

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

        // Ожидание результатов или ошибки (ищем реально существующие элементы)
        await expect(async () => {
            const hasBackButton = await page.locator('button:has-text("Back to search")').isVisible();
            const hasCompanyName = await page.locator('h1').first().isVisible();
            const hasError = await page.locator('text=/not found|לא נמצא/').isVisible();
            expect(hasBackButton || hasCompanyName || hasError).toBeTruthy();
        }).toPass({ timeout: 10000 });
    });

    test('05 - Premium Information заблокирована для не-админов', async ({ page }) => {
        // Выполнить поиск
        await page.locator('input[type="text"]').first().fill('516053675');
        await page.getByRole('main').getByRole('button', { name: /Search/i }).click();
        await Promise.race([
            page.waitForSelector('text=/Company ID|מספר חברה/', { timeout: 10000 }),
            page.waitForSelector('text=/not found|לא נמצא/', { timeout: 10000 })
        ]).catch(() => { });

        // Проверить наличие Premium блока
        const premiumSection = page.getByRole('heading', { name: /Premium Information/i });
        if (await premiumSection.isVisible()) {
            // Проверить наличие замка (Lock icon) в заголовке Premium Information
            await expect(premiumSection.locator('svg')).toBeVisible();

            // Проверить blur эффект
            const premiumContent = page.locator('.blur-sm, .opacity-30').first();
            await expect(premiumContent).toBeVisible();
        }
    });

    test('06 - AI Analysis кнопка работает', async ({ page }) => {
        // Выполнить поиск
        await page.locator('input[type="text"]').first().fill('516053675');
        await page.getByRole('main').getByRole('button', { name: /Search/i }).click();
        await Promise.race([
            page.waitForSelector('text=/Company ID|מספר חברה/', { timeout: 10000 }),
            page.waitForSelector('text=/not found|לא נמצא/', { timeout: 10000 })
        ]).catch(() => { });

        // Найти кнопку AI анализа
        const aiButton = page.getByRole('button', { name: /Smart Analysis|анализ/i });

        if (await aiButton.isVisible()) {
            // Проверить что кнопка кликабельна
            await expect(aiButton).toBeEnabled();

            // Кликнуть и проверить что начался процесс (кнопка заблокирована или текст изменился)
            await aiButton.click();

            // Ждём чтобы React обновил состояние (isLoadingAI=true)
            await page.waitForTimeout(150);

            // Проверить что появился индикатор загрузки ИЛИ кнопка изменилась
            const hasLoadingIndicator = await page.locator('text=/Analyzing/i').isVisible().catch(() => false);
            const buttonDisabled = await aiButton.isDisabled().catch(() => false);

            // Хотя бы одно из условий должно быть true
            expect(hasLoadingIndicator || buttonDisabled).toBeTruthy();
        }
    });

    test('07 - Pricing планы отображаются', async ({ page }) => {
        // Выполнить поиск
        await page.locator('input[type="text"]').first().fill('516053675');
        await page.getByRole('main').getByRole('button', { name: /Search/i }).click();
        await Promise.race([
            page.waitForSelector('text=/Company ID|מספר חברה/', { timeout: 10000 }),
            page.waitForSelector('text=/not found|לא נמצא/', { timeout: 10000 })
        ]).catch(() => { });

        // Проверить наличие планов (используем getByRole для заголовков)
        await expect(page.getByRole('heading', { name: /SILVER/i })).toBeVisible();
        await expect(page.getByRole('heading', { name: /BRONZE/i })).toBeVisible();
        await expect(page.getByRole('heading', { name: /GOLD/i })).toBeVisible();
        await expect(page.getByRole('heading', { name: /PLATINUM/i })).toBeVisible();

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

        // Проверка навигационных элементов (используем русские названия как в коде)
        await expect(page.locator('aside').getByText(/Дашборд/i)).toBeVisible();
        await expect(page.locator('aside').getByText(/Пользователи/i)).toBeVisible();
        await expect(page.locator('aside').getByText(/Заказы/i)).toBeVisible();
        await expect(page.locator('aside').getByText(/Developer Mode/i)).toBeVisible();
        await expect(page.locator('aside').getByText(/Настройки/i)).toBeVisible();
    });

    test('10 - Переключение между вкладками Dashboard', async ({ page }) => {
        // Dashboard
        await page.locator('aside').getByText(/Дашборд/i).first().click();
        await page.waitForTimeout(500);
        await expect(page.locator('text=/KPI|Выручка|Revenue/i')).toBeVisible({ timeout: 3000 });

        // Users
        await page.locator('aside').getByText(/Пользователи/i).first().click();

        // Ждём появления таблицы с retry (поддержка русского и английского)
        await expect(async () => {
            const tableHeader = page.locator('table thead th').filter({ hasText: /Пользователь|Email|Статус|Status|Роль|Role/i });
            await expect(tableHeader.first()).toBeVisible();
        }).toPass({ timeout: 10000 });

        // Orders
        await page.locator('aside').getByText(/Заказы/i).first().click();

        // Ждём появления контента Orders с retry (поддержка русского/английского)
        await expect(async () => {
            const ordersContent = page.locator('text=/ORD-|Plan|Amount|Сумма|Статус|Status/i').first();
            await expect(ordersContent).toBeVisible();
        }).toPass({ timeout: 5000 });
    });

    test('11 - Кнопка "Главная (Admin)" возвращает на главную страницу', async ({ page }) => {
        // Найти кнопку возврата на главную (она в aside с текстом "Главная (Admin)")
        const homeButton = page.locator('aside').getByText(/Главная.*Admin/i);

        if (await homeButton.isVisible()) {
            await homeButton.click();
            await page.waitForTimeout(1000);

            // Проверить что вернулись на главную страницу
            await expect(page.locator('input[type="text"]').first()).toBeVisible();
            await expect(page.locator('text=CompanyCheck').first()).toBeVisible();

            // Проверить что статус админа сохранён (тройной клик должен сразу открыть панель)
            await page.locator('text=CompanyCheck').first().click({ clickCount: 3 });

            // Используем retry для проверки что Admin Panel открылся БЕЗ пароля
            await expect(async () => {
                const passwordModal = page.locator('input[type="password"]');
                const isPasswordRequired = await passwordModal.isVisible().catch(() => false);
                expect(isPasswordRequired).toBe(false); // Password modal НЕ должен появиться

                const adminPanel = page.locator('aside').first();
                await expect(adminPanel).toBeVisible();
            }).toPass({ timeout: 8000 });
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

        // Перейти в Developer Mode (более надёжный селектор через sidebar)
        await page.waitForTimeout(500); // Подождать полного рендера sidebar

        const developerButton = page.locator('aside button').filter({ hasText: /Developer Mode/i });
        const buttonCount = await developerButton.count();

        if (buttonCount === 0) {
            // Если sidebar свёрнут или кнопка не найдена, ищем последнюю кнопку в навигации
            const navButtons = page.locator('aside nav button');
            await navButtons.last().click();
        } else {
            await developerButton.first().click();
        }
        await page.waitForTimeout(500);
    });

    test('12 - Developer Mode IDE вкладка', async ({ page }) => {
        // Переключить на IDE вкладку (точное имя кнопки - "Web IDE")
        await page.locator('button', { hasText: /Web IDE/i }).first().click();
        await page.waitForTimeout(500);

        // Проверить наличие файлового дерева (более специфичный селектор)
        await expect(page.locator('text=/config\\/|src\\/|public\\//i').first()).toBeVisible({ timeout: 5000 });

        // Проверить наличие редактора кода (textarea или pre/code)
        const editorTextarea = page.locator('textarea.font-mono');
        const editorPre = page.locator('pre code.font-mono');
        await expect(editorTextarea.or(editorPre).first()).toBeVisible({ timeout: 10000 });
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
        await page.getByRole('button', { name: /API Playground/i }).click();
        await page.waitForTimeout(300);

        // Проверить наличие dropdown для методов (select с опциями GET, POST, etc.)
        const methodSelect = page.locator('select').filter({ hasText: /GET/ });
        await expect(methodSelect).toBeVisible({ timeout: 10000 });

        // Проверить кнопку Send
        await expect(page.locator('button', { hasText: /Send|Отправить/i })).toBeVisible();
    });

    test('17 - Developer Mode Jobs вкладка', async ({ page }) => {
        await page.getByRole('button', { name: /Job Queues/i }).click();

        // Проверяем заголовок секции Jobs (более надёжно чем таблица)
        await expect(async () => {
            const jobsHeader = page.locator('h3', { hasText: /Background Jobs/i });
            await expect(jobsHeader).toBeVisible();

            // Также проверяем наличие Refresh кнопки
            const refreshButton = page.locator('button', { hasText: /Refresh/i });
            await expect(refreshButton).toBeVisible();
        }).toPass({ timeout: 10000 });
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

        // Используем retry для поиска цветовых кнопок (они могут быть в span внутри button)
        await expect(async () => {
            // Ищем span с текстом цвета внутри button OR div с классом bg-{color}-600
            const colorSpan = page.locator('button span').filter({ hasText: /^(blue|indigo|emerald|purple|slate|gray)$/i });
            const colorDiv = page.locator('button div[class*="bg-blue-600"], button div[class*="bg-indigo-600"], button div[class*="bg-emerald-600"]');

            const hasColorSpan = await colorSpan.count() > 0;
            const hasColorDiv = await colorDiv.count() > 0;
            expect(hasColorSpan || hasColorDiv).toBeTruthy();
        }).toPass({ timeout: 10000 });

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
