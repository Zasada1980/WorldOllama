# План замещения основного агента на `mistral-small:latest`

Дата: 03.12.2025  
Статус: Проектирование изменений (без фактической замены)

---

## Резюме
- Новый основной агент: `mistral-small:latest` (22B, ~14 GB)
- Цель: использовать его по умолчанию для пользовательского чата и CORTEX (LightRAG) генерации ответов, не затрагивая пайплайн эмбеддингов и тренировок без отдельного решения.
- Важно: эмбеддинги остаются `nomic-embed-text:latest`. Тренировки (LLaMA Factory) остаются на текущем whitelisted наборе базовых моделей до отдельного согласования.

---

## Файлы и места, требующие обновления
(Сгруппировано по подсистемам; замены пока НЕ выполнены — только перечень)

### 1) CORTEX (LightRAG)
- `services/lightrag/lightrag_server.py`
  - LLM_MODEL: "qwen2.5:14b" → "mistral-small"
  - RERANK_MODEL: "qwen2.5:14b" → (оставить без изменений или выключено; rerank сейчас off)
  - Комментарии-«ФИКСИРОВАННЫЙ» в `llm_model_func` — обновить описание под `mistral-small`
  - Производительность: оставить `LLM_MAX_ASYNC=1` (16GB VRAM)

Риски/заметки:
- Проверить, что контекст/температура/макс. токены не жестко зашиты (LightRAG передает без ограничений, ок).
- При первом запуске `mistral-small` займёт ~14 GB VRAM/host RAM; убедиться, что параллельные операции не перегружают GPU.

### 2) Desktop Client (Svelte UI)
- `client/src/lib/components/Settings.svelte`
  - Списки и значения по умолчанию: 'qwen2.5:14b-instruct-q4_k_m' → 'mistral-small'
- `client/src/lib/components/SettingsPanel.svelte`
  - `ollama_model` и список пресетов: заменить на 'mistral-small'
- `client/src/lib/components/Chat.svelte`
  - В параметрах вызова модели: 'qwen2.5:14b' → 'mistral-small'
- `client/src/lib/components/SystemStatusPanel.svelte`
  - Текстовые подсказки: «загружена ли нужная модель (qwen2.5:14b)» → «(mistral-small)»

### 3) Desktop Client (Rust, Tauri bridge)
- `client/src-tauri/src/settings.rs`
  - Значение по умолчанию: `ollama_model: "qwen2.5:14b"` → `"mistral-small"`
- Тесты/скрипты
  - `client/run_auto_tests.ps1`: `model = "qwen2.5:14b"` → `"mistral-small"`
  - `client/README_CLIENT.md`: примеры вызовов и troubleshooting по qwen → обновить на `mistral-small`

### 4) Training (Лимиты и совместимость)
- `client/src-tauri/src/training_manager.rs`
  - Встречаются `base_model: "qwen2.5:14b-instruct-q4_k_m"` (несколько мест) — НЕ менять в рамках этой задачи.
  - Причина: пайплайн обучения (LLaMA Factory) и whitelist профилей заточены под текущие базовые модели. Перевод на Mistral требует отдельной валидации конфигов (`services/llama_factory/config/*.yaml`).

### 5) Документация
- `docs/project/RUNTIME_LOGS_JOURNAL_INDEX.md`
  - ✅ Добавлена строка: Основной агент — `mistral-small:latest`.
- `client/README_CLIENT.md`, `docs/models/*`, `docs/qa/*`
  - В разделах, где ссылаются на `qwen2.5:14b` как «по умолчанию», заменить формулировки на `mistral-small` (после внесения кода).

---

## Аудит рисков и возможных сбоев
- **VRAM/память:** `mistral-small` ~14 GB — на 16 GB VRAM остаётся небольшой запас. `LLM_MAX_ASYNC=1` обязателен.
- **Производительность:** Время отклика выше, чем у 7B/8B; учесть в e2e тестах ожидание/таймауты.
- **Совместимость LightRAG:** API совместимо (Ollama), но качество и длина ответов изменится — обновить тестовые эталоны при необходимости.
- **UI автотесты:** Если зашиты ожидания по тексту/модели — обновить селекторы/строки ожидаемых значений.
- **Тренировки:** НЕ переключать базовую модель обучения без отдельной проработки; иначе риск несовместимости конфигов и потери репродьюсабельности.

---

## Анализ внедрения и границы замещения
- **Внедряем прямо сейчас:** только генерация ответов (CORTEX + UI Chat) и значения по умолчанию в настройках.
- **НЕ внедряем:** пайплайн эмбеддингов (остаётся `nomic-embed-text`), пайплайн обучения моделей.
- **Документация:** обновляем user-facing примеры и подсказки.

---

## Предлагаемый план (3 шага)
1) Конфигурация + переключение по умолчанию
   - Lightrag: `LLM_MODEL = "mistral-small"`
   - UI: заменить дефолт в Settings/SettingsPanel/Chat, обновить подсказки
   - Rust (settings.rs): дефолтную `ollama_model` на `"mistral-small"`

2) Регрессия и стабилизация
   - Прогон `scripts/HEALTH_CHECK_ALL.ps1` (Ollama, CORTEX)
   - UI e2e: `client/test_stage2_e2e.ps1` (увеличить таймауты при необходимости)
   - Нагрузочный смоук: 5-10 последовательных запросов в CORTEX (смотреть GPU память `nvidia-smi`)

3) Документация и развёртывание
   - Обновить `client/README_CLIENT.md` и QA-отчёты с новой моделью по умолчанию
   - Записать результаты тестов в `docs/qa/` (новая дата, новая модель)
   - Зафиксировать изменения в CHANGELOG (v0.3.1 post-fix)

---

## Rollback (план отката)
- Вернуть `LLM_MODEL` на `qwen2.5:14b`
- Вернуть дефолты в UI/Settings и `settings.rs`
- Очистить артефакты кэша LightRAG при необходимости (`services/lightrag/data/*`)

---

## Проверочные команды (после внедрения)
```powershell
# Проверка доступности моделей
ollama list | Select-String "mistral-small|qwen2.5|nomic-embed-text"

# Health CORTEX
Invoke-RestMethod http://localhost:8004/health

# Быстрый прогрев модели
curl http://localhost:11434/api/generate -d '{
  "model": "mistral-small",
  "prompt": "Say hello"
}'
```

---

Примечание: этот файл — план и перечень правок. Фактическая замена в коде не выполнена в рамках этой задачи — применим после подтверждения.