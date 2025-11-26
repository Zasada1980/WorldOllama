# Шпаргалка: Локальный ИИ (Llama3 8B Instruct Q4_K_M и окружение)

## 1. Ключевые инструменты
| Инструмент | Тип | API | CPU | GPU | Особенности |
|------------|-----|-----|-----|-----|-------------|
| Ollama | CLI/API | OpenAI‑совместимый (порт 11434) | Да | Да (через backend) | Быстрая загрузка >100 оптимизированных моделей, автокэш |
| LM Studio | GUI + API | OpenAI‑совместимый | Да | Да (Intel/AMD, ранний ROCm) | Удобный выбор квантования, чат история, визуальные параметры |
| llama.cpp | CLI/библиотеки | Собственный / Python / Node | Да (минимум памяти) | Да (CUDA/Metal/ROCm сборки) | Чистый контроль, GGUF нативно |
| KoboldCpp | GUI/Web | Разные (вкл. Ollama/OpenAI) | Да | Да (частичн. оффлоад) | Сохранение персонажей, сцены, удобный UI |
| text-generation-webui | Web UI | Плагины / Расширения | Да | Да | Много бэкендов (GGUF, GPTQ, AWQ), RAG плагины |
| Open WebUI | Web UI | Ollama/OpenAI | Да | Да | Расширяемые плагины, встроенный RAG, управление моделями |
| GPT4All Desktop | GUI | GPT4All API | Да | Частично | Простота, локальный чат |
| LocalAI | Docker/API | OpenAI‑совместимый | Да | Да | Сервисный развёртываемый слой |

## 2. Форматы и квантование
- GGUF — основной формат для llama.cpp и большинства GUIs.
- Квантования: Q4_K_M (баланс скорость/качество), Q5_K_M (чуть лучше качество), Q6/Q8 (больше памяти).
- Выбор: Начни с `Q4_K_M` для 8B на ограниченном железе.

## 3. Быстрый старт (Ollama + Llama3)
```bash
ollama run llama3          # загрузка и запуск модели (8B instruct Q4_K_M по умолчанию)
ollama list                # список установленных моделей
ollama pull llama3:8b-instruct-q4_K_M   # явная загрузка конкретного тега
```
Запрос через curl (OpenAI‑совместимо):
```bash
curl http://localhost:11434/api/generate -d '{"model":"llama3","prompt":"Привет!"}'
```

## 4. Установка Open WebUI (связка с Ollama)
```bash
git clone https://github.com/open-webui/open-webui.git
cd open-webui
cp .env.example .env
npm install
npm run build
cd backend
python -m venv .venv && .venv\Scripts\activate  # Windows
pip install --upgrade -r requirements.txt
# Запуск (Windows): стартовый .bat или python main.py
```
Доступ: браузер `http://localhost:8080`. Модели Ollama автоматически отображаются.

## 5. Выбор инструмента по сценарию
| Сценарий | Рекомендация |
|----------|--------------|
| Быстро протестировать ответ | Ollama (одна команда) |
| Глубокая настройка параметров | LM Studio / text-generation-webui |
| Минимальный footprint / интеграция в код | llama.cpp (CLI + bindings) |
| Веб‑чат + плагины/RAG | Open WebUI / text-generation-webui |
| Ролевой / нарративный чат | KoboldCpp |
| Docker‑микросервис | LocalAI |

## 6. Тонкая настройка (Fine‑Tuning)
- LoRA/QLoRA адаптации: искать на Hugging Face (`lora`, `qlora`, `dpo`).
- Стек: `transformers` + `peft` + `trl` / Axolotl.
- Базовые шаги:
  1. Скачай базовую модель (HF weights) или GGUF конвертируй при необходимости.
  2. Подготовь датасет (инструкции / QA / диалоги).
  3. Запусти QLoRA (4‑битовые веса + LoRA адаптер) для экономии VRAM.
  4. Экспорт адаптера и используйте вместе с базой (merge при деплое).

## 7. Русскоязычные и специализированные модели
- Пример: `Llama-3-8B-GPT-4o-RU1.0` — улучшенный русский корпус (80% RU данных).
- Проверяй бенчмарки: сопоставление с GPT‑3.5, локальные тесты на своих промптах.
- Риск: узкоспециализированные LoRA могут ухудшить универсальность.

## 8. Шаблоны промптов Llama3
- Chat template (HF): маркеры `<|start_header_id|>system`, `<|end_header_id|>` и т.п.
- Использование в Python:
```python
from transformers import AutoTokenizer
 tok = AutoTokenizer.from_pretrained("meta-llama/Meta-Llama-3-8B-Instruct")
 messages = [
   {"role":"system","content":"Ты помощник"},
   {"role":"user","content":"Объясни квантование"}
 ]
 prompt = tok.apply_chat_template(messages, tokenize=False)
```

## 9. Плагины / RAG (Open WebUI / text-generation-webui)
- Документы → Индексация → Встраивание контекста в запрос.
- Подключаемые инструменты: веб‑поиск, функции Python, кастомные действия.
- Храни память: файлы контекста, сохранённые беседы.

## 10. Практические команды (Windows PowerShell примеры)
```powershell
# Просмотр процессов Ollama
Get-Process | Where-Object {$_.ProcessName -like "ollama*"}

# API тест через PowerShell
Invoke-RestMethod -Uri "http://localhost:11434/api/generate" -Method Post -Body '{"model":"llama3","prompt":"Тест"}' -ContentType "application/json"

# Быстрый запуск llama.cpp (пример, если собран)
./main -m .\models\llama3-8b-instruct-q4_K_M.gguf -p "Привет" -n 128
```

## 11. Рекомендации по ресурсам
| Параметр | 8B Q4_K_M ориентир |
|----------|-------------------|
| RAM (CPU) | ~6–8 ГБ |
| VRAM (GPU оффлоад) | >=4–6 ГБ |
| Скорость (CPU) | 5–15 ток/с (зависит от частоты) |
| Скорость (GPU) | 30+ ток/с |

## 12. Диагностика и оптимизация
- Замедление ответов → снизить `num_ctx` / увеличить квантование (Q4). 
- Падение качества → переключиться Q5/Q6, уменьшить температуру.
- Высокая задержка сети (в браузере) → проверь перегрузку localhost, отключи лишние плагины.

## 13. Безопасность и офлайн
- Все данные локальны (если не включён внешний RAG/поиск).
- Проверяй отсутствие фоновых аплоудов (firewall/monitor).

## 14. Минимальный код (Python OpenAI‑совместимо через Ollama)
```python
import requests
resp = requests.post("http://localhost:11434/v1/chat/completions", json={
  "model": "llama3",
  "messages": [
    {"role": "user", "content": "Привет, дай совет по квантованию"}
  ]
})
print(resp.json()["choices"][0]["message"]["content"])  # совместимо с OpenAI схемой
```

## 15. Краткий алгоритм выбора
1. Нужно мгновенно → Ollama.
2. Нужен продвинутый UI / плагины → text-generation-webui / Open WebUI.
3. Тонкая интеграция в код → llama.cpp.
4. Нужен сторибординг / персонажи → KoboldCpp.
5. Планируешь дообучение → HF + PEFT (LoRA/QLoRA) + Axolotl.

---
## 16. Open WebUI доступ
- Текущий используемый порт: `http://localhost:3000/` (вместо стандартного 8080, зафиксируй в своих скриптах).
- Проверяй доступность: открытие страницы / наличие сетевых запросов к `/api/*`.

## 17. Переменные окружения Ollama (из логов)
| Переменная | Назначение | Текущие значения / замечания |
|------------|-----------|------------------------------|
| `OLLAMA_HOST` | Биндинг API сервера | `http://127.0.0.1:11435` (кастомный порт) |
| `OLLAMA_MODELS` | Путь к каталогу моделей | `E:\OllamaModels` (перенос на диск E:) |
| `OLLAMA_CONTEXT_LENGTH` | Макс. контекст при генерации | 4096 (меньше, чем обучающий 8192) |
| `OLLAMA_MAX_QUEUE` | Очередь запросов | 512 |
| `OLLAMA_KEEP_ALIVE` | Время жизни неисп. моделей | 5m0s |
| `OLLAMA_INTEL_GPU` | Использование Intel GPU | false |
| `OLLAMA_NUM_PARALLEL` | Параллельные загрузки/инференсы | 1 |
| GPU переменные | Настройка видимости | `CUDA_VISIBLE_DEVICES`, др. пустые → 1 GPU найден |

## 18. Контекст: train vs runtime
- Модель обучена на контексте 8192 токенов (`llama.context_length`).
- Runtime установлен `n_ctx = 4096` → половина доступного окна.
- Логи предупреждают: `n_ctx_per_seq (4096) < n_ctx_train (8192)` → можно повысить при достаточной памяти (увеличить `OLLAMA_CONTEXT_LENGTH`).
- Предупреждения `truncating input prompt limit=4096` показывают усечение длинных промптов (6618, 8837 и т.д.).
  - Механизм усечения оставляет первые ~25 токенов + хвост до лимита. Планируй стратегию сжатия (резюме) для длинных диалогов.

## 19. Память и offload (из логов)
- VRAM доступно: ~15.9 GiB (NVIDIA GeForce RTX 5060 Ti) — режим "low vram mode" активирован (порог 20 GiB).
- Требуется для полной загрузки: ~5.7 GiB VRAM + ~512 MiB KV cache.
- Offload слоёв: 33/33 слоёв на GPU (полный offload для Q4_K).
- Граф буфера GPU: ~300 MiB; веса повторяющиеся ~3.9 GiB.
- Если появится нехватка памяти → уменьшить контекст или квантование (оставить Q4_K), либо включить частичное offload (уменьшить `GPULayers`).

## 20. Процедура перезапуска Ollama (PowerShell)
```powershell
# 1. Остановить работающие процессы
taskkill /IM ollama.exe /F

# 2. Установить путь и хост (порт 11435 вместо дефолтного 11434)
$env:OLLAMA_MODELS = 'E:\OllamaModels'
$env:OLLAMA_HOST   = 'http://127.0.0.1:11435'

# 3. Запустить сервер (оставить окно открытым)
& "C:\Users\zakon\AppData\Local\Programs\Ollama\ollama.exe" serve

# 4. Проверить список моделей
ollama list
```
Ошибка `bind: Only one usage of each socket address...` → порт занят (закрыть предыдущий процесс или сменить порт).

## 21. Структура хранения моделей
- Каталог: `E:\OllamaModels` (перенос из `%LOCALAPPDATA%\Ollama`).
- Основные файлы:
  - `db.sqlite`, `db.sqlite-shm`, `db.sqlite-wal` — метаданные, состояния.
  - `blobs/sha256-*` — куски весов GGUF.
  - `manifests/` — метаданные сборок (создан после pull).
  - `server.log`, `app.log` — диагностика.
- Резервная копия: `C:\Users\zakon\AppData\Local\Ollama_backup`.
  - Отсутствие `models/` внутри backup → перенос сделан правильно (используется кастомный путь).

## 22. Типичные предупреждения и ошибки
| Лог | Причина | Действие |
|-----|---------|---------|
| `truncating input prompt limit=4096` | Превышен runtime контекст | Сжать историю, увеличить `OLLAMA_CONTEXT_LENGTH` (тестировать) |
| `bind: ... port` | Порт занят | Освободить или выбрать другой порт (например 11436) |
| `failure during GPU discovery` | Таймаут/драйвер/перегрузка | Перезапуск сервера; проверить драйверы CUDA; снизить параллелизм |
| `entering low vram mode` | VRAM ниже порога | Нормально; оптимизация загрузки слоёв, при апгрейде GPU пропадёт |
| `vocab only - skipping tensors` (при первом проходе) | Предварительное чтение метаданных | Не требует действий |

## 23. Мониторинг и латентность
- Время запуска runner: 1.64–2.70s — нормально для Q4_K.
- Время `POST /api/chat`: 6–13s для длинного контекста → оптимизация: уменьшать историю, применять сжатие.
- Сбор метрик: парсить `server.log` (время offload, VRAM, runner ports).
- Возможна интеграция простым скриптом: периодический `GET /api/tags`, `GET /api/ps` для health‑check.

## 24. Рекомендации по увеличению контекста
- Перед поднятием до 8192 токенов: убедиться свободная VRAM ≥ дополнительным требованиям (KV cache удвоится ~1 GiB).
- Тестово: запустить с `OLLAMA_CONTEXT_LENGTH=8192` и проверить отсутствия частых OOM.

## 25. Быстрый чеклист перед задачей через Open WebUI
1. Открыт `http://localhost:3000`.
2. Модель в списке (`ollama list` показывает тег). 
3. Нет активных перезапускающихся runner (много последовательных `starting runner` может говорить о сбоях).
4. Нет новых предупреждений GPU discovery.
5. Размер промпта < 4000 токенов или включено сжатие.

## 26. Лицензия и политика использования Llama
- Коммерческое использование разрешено после принятия лицензии и политики Acceptable Use (Meta Llama 3 License + Use Policy).
- Ссылки (официальные):
  - License: `models/llama3/LICENSE` (репозиторий `meta-llama/llama-models`).
  - Use Policy: `models/llama3/USE_POLICY.md`.
- Требования при загрузке оригинальных весов: принятие условий на сайте Meta, возможна e-mail верификация, ссылки обладают сроком действия.
- Рекомендация: хранить локальную копию лицензии в `AGENTS/docs/reference/licenses/` для аудита.

## 27. Рекомендованные параметры генерации (стартовые пресеты)
| Пресет | temperature | top_p | top_k | repeat_penalty | max_new_tokens | Назначение |
|--------|-------------|-------|-------|----------------|----------------|------------|
| balanced | 0.7 | 0.9 | 40 | 1.1 | 512 | Смешанный стиль, адекватные ответы |
| creative | 0.9 | 0.95 | 60 | 1.05 | 512 | Более вариативные идеи |
| factual | 0.3 | 0.85 | 40 | 1.15 | 512 | Снижение галлюцинаций, сдержанность |
| concise | 0.4 | 0.8 | 30 | 1.2 | 256 | Короткие ответы, меньше повторов |
| long-form | 0.7 | 0.95 | 60 | 1.05 | 1024 | Развёрнутые тексты |

Примечания:
- Повышение `repeat_penalty` > 1.2 может ухудшать связность; понижать при творческих задачах.
- `top_k` > 80 даёт рост вариативности, но возможно снижение фактической точности.
- Для Q4_K_M квантования значения выше подходят, но при переходе на Q5/Q6 можно слегка увеличивать `top_p`.

## 28. Интеграция Modelfile (кастомизация модели)
Минимальный пример с установкой системного промпта и параметров:
```
FROM llama3:8b-instruct-q4_K_M
PARAMETER temperature 0.7
PARAMETER top_p 0.9
PARAMETER num_ctx 4096
SYSTEM "Ты технический ассистент, отвечающий кратко и точно."
```
Создание и запуск:
```powershell
ollama create tech-assistant -f .\Modelfile
ollama run tech-assistant "Объясни разницу Q4_K_M и Q5_K_M"
```

## 29. Инструменты для расширения (наблюдательность и RAG)
| Категория | Инструмент | Назначение |
|-----------|------------|-----------|
| Observability | Langfuse / OpenLIT / Opik | Трассировка, метрики запросов |
| Embeddings Workflow | pgai / chroma / FAISS | Хранение и поиск векторных представлений |
| RAG Engines | RAGFlow / Minima / Nosia | Расширенное извлечение знаний |
| Multi-agent | crewAI / Strands Agents | Координация нескольких агентов |
| Prompt Ops | llama-cookbook / synthetic-data-kit | Рецепты, генерация датасетов |

## 30. План повышения контекста до 8192
1. Тестовый запуск с `PARAMETER num_ctx 8192` в Modelfile.
2. Мониторинг VRAM: потребление KV cache удвоится (~1 GiB вместо 512 MiB).
3. При росте латентности >30% — добавить этап резюмирования каждые N сообщений.
4. Зафиксировать результаты (ток/с, средняя задержка) в `reference/eval/latency.json`.

## 31. Автоматический бэкап Open WebUI
**Расположение бэкапов:** `E:\AGENTS\backups\open-webui\`

### Структура:
- `configs/` — конфигурация контейнера, переменные окружения
- `data/` — копии файлов из контейнера (БД, загрузки, настройки)
- `logs/` — логи бэкапов и мониторинга

### Инструменты:
| Скрипт | Назначение |
|--------|-----------|
| `backup_openwebui.py` | Ручной/авто бэкап; восстановление |
| `watch_openwebui.py` | Мониторинг изменений контейнера (каждые 5 мин) |
| `setup_backup_schedule.ps1` | Установка задачи в Task Scheduler |

### Триггеры бэкапа:
1. Ежедневно в 02:00 (Task Scheduler)
2. При запуске системы (задержка 5 мин)
3. При обнаружении изменений конфигурации/данных (watcher)

### Быстрые команды:
```powershell
# Создать бэкап сейчас
python E:\AGENTS\agents_tools\backup_openwebui.py

# Список бэкапов
Get-ChildItem E:\AGENTS\backups\open-webui\data\ | Sort -Descending

# Восстановить из бэкапа
python E:\AGENTS\agents_tools\backup_openwebui.py restore 20251121_143000

# Установить расписание (от администратора)
E:\AGENTS\agents_tools\setup_backup_schedule.ps1
```

Подробности: `E:\AGENTS\docs\openwebui-backup.instructions.md`

## 32. Мост для прямого доступа к файлам контейнера
**Расположение моста:** `E:\AGENTS\open-webui-bridge\`

### Концепция:
Монтирование локальных путей как volume в контейнер — файлы доступны напрямую через Explorer без `docker cp`.

### Структура:
```
E:\AGENTS\open-webui-bridge\
├── data\     -> /app/backend/data (БД, загрузки)
├── static\   -> /app/backend/static (статика)
└── config\   (локальные конфиги)
```

### Установка моста:
```powershell
# Автоматическая установка (пересоздаёт контейнер с монтированием)
E:\AGENTS\agents_tools\recreate_openwebui_with_bridge.ps1
```

### Использование:
```powershell
# Прямой доступ к БД
explorer E:\AGENTS\open-webui-bridge\data\

# Добавить файл в контейнер
Copy-Item "document.pdf" "E:\AGENTS\open-webui-bridge\static\"

# Статус моста
python E:\AGENTS\agents_tools\bridge_sync.py status

# Мониторинг изменений
python E:\AGENTS\agents_tools\bridge_sync.py watch
```

### Рабочие сценарии:
- **Редактирование БД:** Остановить контейнер → открыть `data\webui.db` в DB Browser → изменить → запустить.
- **Массовая загрузка:** `Copy-Item *.pdf static\uploads\` — файлы сразу в Open WebUI.
- **Бэкап напрямую:** `Copy-Item data\webui.db backups\manual\`.

### Преимущества:
✅ Редактирование без `docker cp`  
✅ Быстрое добавление/удаление файлов  
✅ Интеграция с внешними инструментами (IDE, DB browser)  
✅ Автосинхронизация с системой бэкапов

Подробности: `E:\AGENTS\docs\openwebui-bridge.instructions.md`

---
Обновить при появлении новых стабильных релизов, смене порта, расширении контекста или добавлении LoRA.
Последнее обновление: 2025-11-21 (добавлены лицензия, параметры, Modelfile, инструменты, план контекста, система бэкапа, мост к контейнеру).
