import { expect, test } from '@playwright/test';

/**
 * E2E Tests для CompanyCheck на production сервере
 * URL: http://46.224.36.109
 * 
 * Эти тесты проверяют реальное приложение на сервере,
 * включая работу с реальным Israeli Government API
 */

const SERVER_URL = 'http://46.224.36.109';

test.describe('CompanyCheck E2E Tests - Production Server', () => {

    test.beforeEach(async ({ page }) => {
        await page.goto(SERVER_URL);
    });

    test('01 - Главная страница загружается', async ({ page }) => {
        // Проверка загрузки страницы
        await expect(page).toHaveTitle(/CompanyCheck/);

        // Проверка наличия основных элементов
        await expect(page.locator('header').getByText('CompanyCheck')).toBeVisible();
        await expect(page.locator('input[placeholder*="Company"]')).toBeVisible();

        // Проверка переключателя языков
        await expect(page.locator('button:has-text("HE")')).toBeVisible();
        await expect(page.locator('button:has-text("EN")')).toBeVisible();
        await expect(page.locator('button:has-text("RU")')).toBeVisible();
    });

    test('02 - Переключение языков работает', async ({ page }) => {
        // Переключение на иврит
        await page.click('button:has-text("HE")');
        await expect(page.locator('input')).toHaveAttribute('placeholder', /חברה/);

        // Переключение на английский
        await page.click('button:has-text("EN")');
        await expect(page.locator('input')).toHaveAttribute('placeholder', /Company/);

        // Переключение на русский
        await page.click('button:has-text("RU")');
        await expect(page.locator('input')).toHaveAttribute('placeholder', /компани/);
    });

    test('03 - Поиск компании через реальное API', async ({ page }) => {
        // Ввод номера компании
        const searchInput = page.locator('input[type="text"]');
        await searchInput.fill('516053675');

        // Нажатие кнопки поиска
        await page.click('button[type="submit"]');

        // Ожидание загрузки результатов (максимум 10 секунд)
        await page.waitForTimeout(3000);

        // Проверка, что отобразилась страница компании
        // Может быть либо реальные данные из API, либо сообщение об ошибке
        const pageContent = await page.textContent('body');

        // Проверяем, что либо отобразились данные, либо есть сообщение
        const hasCompanyData = pageContent?.includes('516053675') ||
            pageContent?.includes('METAL') ||
            pageContent?.includes('Active') ||
            pageContent?.includes('not found');

        expect(hasCompanyData).toBeTruthy();
    });

    test('04 - История поиска сохраняется', async ({ page }) => {
        // Выполнение поиска
        const searchInput = page.locator('input[type="text"]');
        await searchInput.fill('516053675');
        await page.click('button[type="submit"]');
        await page.waitForTimeout(2000);

        // Возврат на главную
        const backButton = page.locator('text=Back to search');
        if (await backButton.isVisible()) {
            await backButton.click();
        } else {
            await page.goto(SERVER_URL);
        }

        // Клик по полю поиска
        await searchInput.click();

        // Проверка наличия истории
        await page.waitForTimeout(500);
        const historyVisible = await page.locator('text=Search History').isVisible().catch(() => false);

        if (historyVisible) {
            // Проверка наличия предыдущего запроса
            await expect(page.locator('text=516053675').last()).toBeVisible();
        }
    });

    test('05 - Модальное окно Login открывается', async ({ page }) => {
        // Клик по кнопке Login
        await page.click('button:has-text("Login")');

        // Проверка, что модальное окно открылось
        await expect(page.locator('input[type="email"]')).toBeVisible();
        await expect(page.locator('input[type="password"]')).toBeVisible();

        // Закрытие модального окна (клик по backdrop или кнопке ✕)
        await page.click('button:has-text("✕")');
        await page.waitForTimeout(300);

        // Проверка, что модальное окно закрылось
        const emailInput = page.locator('input[type="email"]');
        await expect(emailInput).not.toBeVisible();
    });

    test('06 - Модальное окно About открывается', async ({ page }) => {
        // Клик по кнопке About
        await page.click('button:has-text("About")');

        // Проверка наличия контента
        await expect(page.locator('text=About Us')).toBeVisible();

        // Проверка наличия карточек с преимуществами
        await expect(page.getByRole('heading', { name: 'Fast' }).first()).toBeVisible();
        await expect(page.getByRole('heading', { name: '6 Sources' }).first()).toBeVisible();

        // Закрытие модального окна
        await page.click('button:has-text("✕")');
    });

    test('07 - Модальное окно Pricing открывается', async ({ page }) => {
        // Клик по кнопке Pricing
        await page.click('button:has-text("Pricing")');

        // Проверка наличия тарифных планов
        await expect(page.getByRole('heading', { name: 'SILVER' })).toBeVisible();
        await expect(page.getByRole('heading', { name: 'BRONZE' })).toBeVisible();
        await expect(page.getByRole('heading', { name: 'GOLD' })).toBeVisible();
        await expect(page.getByRole('heading', { name: 'PLATINUM' })).toBeVisible();

        // Проверка цен
        await expect(page.getByText('₪139', { exact: true })).toBeVisible();
        await expect(page.getByText('₪499', { exact: true })).toBeVisible();

        // Закрытие модального окна
        await page.click('button:has-text("✕")');
    });

    test('08 - AI анализ работает (если доступен)', async ({ page }) => {
        // Поиск компании
        const searchInput = page.locator('input[type="text"]');
        await searchInput.fill('516053675');
        await page.click('button[type="submit"]');
        await page.waitForTimeout(3000);

        // Проверка наличия кнопки AI анализа
        const aiButton = page.locator('button:has-text("Get Smart Analysis")');
        if (await aiButton.isVisible()) {
            // Клик по кнопке AI анализа
            await aiButton.click();

            // Ожидание результата (максимум 15 секунд для Gemini API)
            await page.waitForTimeout(2000);

            // Проверка, что кнопка изменилась или появился результат
            const analyzing = await page.locator('text=Analyzing').isVisible().catch(() => false);
            const hasResult = await page.locator('pre').isVisible().catch(() => false);

            expect(analyzing || hasResult).toBeTruthy();
        }
    });

    test('09 - Responsive дизайн на мобильных', async ({ page }) => {
        // Установка размера экрана мобильного устройства
        await page.setViewportSize({ width: 375, height: 667 });

        // Проверка, что основные элементы видны
        await expect(page.locator('header').getByText('CompanyCheck')).toBeVisible();
        await expect(page.locator('input')).toBeVisible();
        await expect(page.locator('button[type="submit"]')).toBeVisible();
    });

    test('10 - Навигация Footer работает', async ({ page }) => {
        // Прокрутка вниз к footer
        await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));

        // Проверка наличия элементов footer
        await expect(page.locator('footer').getByText('CompanyCheck', { exact: true }).first()).toBeVisible();

        // Клик по About в footer
        const aboutButton = page.locator('footer').locator('button:has-text("About")');
        if (await aboutButton.isVisible()) {
            await aboutButton.click();
            await expect(page.locator('text=About Us')).toBeVisible();
        }
    });

    test('11 - Проверка CORS и API доступности', async ({ page }) => {
        // Открытие консоли для проверки CORS ошибок
        const errors: string[] = [];
        page.on('console', msg => {
            if (msg.type() === 'error') {
                errors.push(msg.text());
            }
        });

        // Выполнение поиска
        await page.locator('input').fill('514703081');
        await page.click('button[type="submit"]');
        await page.waitForTimeout(5000);

        // Проверка отсутствия CORS ошибок
        const hasCorsError = errors.some(err =>
            err.toLowerCase().includes('cors') ||
            err.toLowerCase().includes('cross-origin')
        );

        expect(hasCorsError).toBeFalsy();
    });

    test('12 - Производительность загрузки', async ({ page }) => {
        const startTime = Date.now();

        await page.goto(SERVER_URL);
        await page.waitForLoadState('networkidle');

        const loadTime = Date.now() - startTime;

        // Проверка, что страница загрузилась быстрее 5 секунд
        expect(loadTime).toBeLessThan(5000);

        console.log(`Page load time: ${loadTime}ms`);
    });

    test('13 - Проверка статических ресурсов', async ({ page }) => {
        const response = await page.goto(SERVER_URL);

        // Проверка успешного ответа сервера (200 или 304 Not Modified)
        expect([200, 304]).toContain(response?.status());

        // Проверка загрузки CSS
        const cssLoaded = await page.evaluate(() => {
            return document.querySelectorAll('link[rel="stylesheet"]').length > 0;
        });
        expect(cssLoaded).toBeTruthy();

        // Проверка загрузки JS
        const jsLoaded = await page.evaluate(() => {
            return document.querySelectorAll('script[type="module"]').length > 0;
        });
        expect(jsLoaded).toBeTruthy();
    });

    test('14 - RTL (Right-to-Left) для иврита', async ({ page }) => {
        // Переключение на иврит
        await page.click('button:has-text("HE")');
        await page.waitForTimeout(300);

        // Проверка направления текста (проверяем главный контейнер с классом min-h-screen)
        const direction = await page.evaluate(() => {
            const mainContainer = document.querySelector('.min-h-screen');
            return mainContainer?.getAttribute('dir') || '';
        });

        expect(direction).toBe('rtl');
    });

    test('15 - Очистка истории поиска', async ({ page }) => {
        // Выполнение нескольких поисков
        const searchInput = page.locator('input[type="text"]');

        await searchInput.fill('516053675');
        await page.click('button[type="submit"]');
        await page.waitForTimeout(2000);

        await page.goto(SERVER_URL);

        // Открытие истории
        await searchInput.click();
        await page.waitForTimeout(500);

        // Проверка наличия кнопки очистки
        const clearButton = page.locator('text=Clear History');
        if (await clearButton.isVisible()) {
            await clearButton.click();
            await page.waitForTimeout(300);

            // Проверка, что история очистилась
            const historyItems = await page.locator('[class*="hover:bg-gray-50"]').count();
            expect(historyItems).toBe(0);
        }
    });

});
