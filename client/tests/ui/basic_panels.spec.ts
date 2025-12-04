import { test, expect } from '@playwright/test';

// Тест: ChatPanel
// Проверяет открытие панели и отправку сообщения

// ...existing code...
test('ChatPanel: отправка сообщения', async ({ page }) => {
  await page.goto('http://localhost:1420'); // Tauri dev порт
  await page.click('text=Chat');
  await page.fill('textarea[placeholder="Введите сообщение"]', 'Привет, AI!');
  await page.click('button:has-text("Send")');
  await expect(page.locator('.chat-message')).toContainText('Привет');
});

test('SystemStatusPanel: проверка статуса сервисов', async ({ page }) => {
  await page.goto('http://localhost:1420');
  await page.click('text=System Status');
  await expect(page.locator('.status-ollama')).toHaveText(/Running|OK/);
  await expect(page.locator('.status-cortex')).toHaveText(/Running|OK/);
});

test('TrainingPanel: запуск обучения', async ({ page }) => {
  await page.goto('http://localhost:1420');
  await page.click('text=Training');
  await page.selectOption('select[name="profile"]', 'triz_engineer');
  await page.fill('input[name="epochs"]', '3');
  await page.click('button:has-text("Start Training")');
  await expect(page.locator('.training-status')).toHaveText(/running|done/);
});

test('FlowsPanel: запуск quick_status flow', async ({ page }) => {
  await page.goto('http://localhost:1420');
  await page.click('text=Flows');
  await page.click('button:has-text("Run quick_status")');
  await expect(page.locator('.flow-status')).toHaveText(/success|OK/);
});
