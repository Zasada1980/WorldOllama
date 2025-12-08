# 🔒 GitHub Branch Protection Setup Guide

## 📋 ЦЕЛЬ

Настроить автоматическую блокировку merge при падении E2E тестов в GitHub Actions.

---

## 🚀 ШАГИ НАСТРОЙКИ

### Шаг 1: Включить GitHub Actions (если ещё не включено)

1. Перейти в GitHub репозиторий: https://github.com/Zasada1980/WorldOllama
2. Settings → Actions → General
3. **Actions permissions:**
   - ✅ Allow all actions and reusable workflows
4. **Workflow permissions:**
   - ✅ Read and write permissions
   - ✅ Allow GitHub Actions to create and approve pull requests
5. Click **Save**

---

### Шаг 2: Настроить Branch Protection Rules

1. **Перейти в Settings → Branches**

   - URL: https://github.com/Zasada1980/WorldOllama/settings/branches

2. **Click "Add branch protection rule"**

3. **Branch name pattern:**

   ```
   main
   ```

4. **Protect matching branches — включить:**

   ✅ **Require a pull request before merging**

   - ✅ Require approvals: 1
   - ✅ Dismiss stale pull request approvals when new commits are pushed

   ✅ **Require status checks to pass before merging**

   - ✅ Require branches to be up to date before merging

   **Status checks that are required:**

   - ✅ `E2E Tests (chromium)`
   - ✅ `E2E Tests (firefox)`
   - ✅ `E2E Tests (webkit)`

   ✅ **Require conversation resolution before merging**

   ✅ **Do not allow bypassing the above settings**

   - ⚠️ **ВАЖНО:** Даже администраторы не могут пропустить проверки

5. **Click "Create"**

---

## ✅ РЕЗУЛЬТАТ

После настройки:

### ✅ Merge РАЗРЕШЁН только если:

```
Pull Request #42: "Add new feature"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ E2E Tests (chromium)  - 38/38 tests passed
✅ E2E Tests (firefox)   - 38/38 tests passed
✅ E2E Tests (webkit)    - 38/38 tests passed
✅ 1 approval required   - @reviewer approved

[Merge Pull Request]  ← Кнопка АКТИВНА
```

### ❌ Merge ЗАБЛОКИРОВАН если:

```
Pull Request #43: "Breaking change"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ E2E Tests (chromium)  - 24/38 tests passed (14 failed)
✅ E2E Tests (firefox)   - 38/38 tests passed
✅ E2E Tests (webkit)    - 38/38 tests passed
⚠️  Required checks must pass

[Merge Pull Request]  ← Кнопка ЗАБЛОКИРОВАНА (серая)

📋 Details:
  - strict mode violation in 01 - Страница загружается
  - strict mode violation in 04 - Поиск компании
  - [View full report] → Artifacts
```

---

## 🔔 УВЕДОМЛЕНИЯ (Опционально)

### Вариант 1: Email уведомления

GitHub автоматически отправляет email при:

- ❌ Failed check на вашем PR
- ✅ All checks passed
- 💬 Code review запрошен

**Настройка:** Settings → Notifications → Actions

### Вариант 2: Slack Integration

1. Install GitHub App в Slack workspace:

   - https://slack.github.com/

2. В Slack канале:

   ```
   /github subscribe Zasada1980/WorldOllama workflows:{name:"E2E Tests"}
   ```

3. Уведомления приходят автоматически:

   ```
   🤖 GitHub Bot
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ❌ E2E Tests Failed

   Repository: WorldOllama
   Branch: feature/new-pricing
   Commit: abc1234
   Failed: 14/38 tests

   [View Report] → https://github.com/.../actions/123
   ```

---

## 📊 ПРОВЕРКА НАСТРОЙКИ

### Тест 1: Create Test PR

```bash
# 1. Создать новую ветку
git checkout -b test/branch-protection

# 2. Внести изменения (например, добавить комментарий)
echo "// Test comment" >> temp/company-check-local/src/App.tsx

# 3. Commit + Push
git add .
git commit -m "test: branch protection"
git push origin test/branch-protection

# 4. Создать PR через GitHub UI
# 5. Проверить что E2E Tests запустились автоматически
# 6. Проверить что кнопка Merge заблокирована до прохождения тестов
```

### Тест 2: Verify Status Checks

1. Открыть любой PR
2. Scroll вниз до "Merge Pull Request"
3. Должен быть блок:

   ```
   ⚠️ Required status checks

   ✅ E2E Tests (chromium)
   ✅ E2E Tests (firefox)
   ✅ E2E Tests (webkit)

   This branch has not been deployed
   ```

4. Если тесты не прошли → кнопка Merge DISABLED

---

## 🐛 TROUBLESHOOTING

### Проблема 1: Status checks не появляются

**Причина:** GitHub не видит workflow

**Решение:**

1. Проверить что файл `.github/workflows/e2e-tests.yml` в main ветке
2. Проверить syntax: https://github.com/Zasada1980/WorldOllama/actions
3. Сделать test commit в main (запустит workflow)

### Проблема 2: Кнопка Merge всё равно активна

**Причина:** "Do not allow bypassing" не включено

**Решение:**

1. Settings → Branches → main rule → Edit
2. Scroll вниз
3. ✅ Do not allow bypassing the above settings
4. Save

### Проблема 3: Тесты не запускаются на PR

**Причина:** `on.pull_request` не настроен

**Решение:**
Проверить `.github/workflows/e2e-tests.yml`:

```yaml
on:
  pull_request:
    branches: [main] # Должно быть указано
```

---

## 📈 МЕТРИКИ (После настройки)

**Ожидаемые результаты через 1 месяц:**

| Метрика                   | До CI/CD           | После CI/CD         |
| ------------------------- | ------------------ | ------------------- |
| **Баги в production**     | 3-5/месяц          | 0-1/месяц           |
| **Время поиска проблемы** | 2-4 часа           | 2 минуты            |
| **Failed merges**         | 0 (всё пропускали) | 2-3 (заблокированы) |
| **Confidence level**      | 60%                | 95%                 |

---

## ✅ CHECKLIST

- [ ] GitHub Actions включены
- [ ] Workflow файл `.github/workflows/e2e-tests.yml` в main
- [ ] Branch Protection Rule создан для `main`
- [ ] Required status checks: chromium, firefox, webkit
- [ ] "Do not allow bypassing" включено
- [ ] Test PR создан и проверен
- [ ] Slack notifications настроены (опционально)

---

**Дата создания:** 08.12.2025  
**Репозиторий:** https://github.com/Zasada1980/WorldOllama  
**Статус:** ✅ READY TO CONFIGURE
