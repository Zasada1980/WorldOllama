---
description: Критические правила для работы с LightRAG индексацией
applyTo: 'E:/AI_Librarian_Core/**'
---

# LightRAG Troubleshooting Guidelines

## КРИТИЧЕСКОЕ ПРАВИЛО #1: Состояние хранится на диске

**ВСЕГДА помнить:**
- `kv_store_doc_status.json` **НЕ удаляется** при перезапуске сервера
- LightRAG при старте **читает прогресс с диска**
- Перезапуск сервера **НЕ сбрасывает** обработанные чанки
- 410 processed чанков остаются processed после перезапуска

**Перед любым решением о "перезапуске с нуля" ОБЯЗАТЕЛЬНО:**
1. Проверить существование `E:\AI_Librarian_Core\lightrag_cache\kv_store_doc_status.json`
2. Прочитать статус обработанных чанков
3. Объяснить пользователю, что прогресс сохранён
4. Предложить продолжение, а НЕ полный перезапуск

## КРИТИЧЕСКОЕ ПРАВИЛО #2: Диагностика ошибок 500

**Ошибка 500 от LightRAG НЕ означает:**
- ❌ Потерю данных
- ❌ Необходимость перезапуска с нуля
- ❌ Проблемы с кешем

**Ошибка 500 ОЗНАЧАЕТ:**
- ✅ Перегрузка HTTP-очереди FastAPI
- ✅ Слишком быстрая отправка чанков
- ✅ Нужна задержка в `ingest_library.py`

**Правильная последовательность действий:**
1. Остановить `ingest_library.py` (не сервер!)
2. Проверить `kv_store_doc_status.json` - сколько processed/pending
3. Добавить/увеличить `time.sleep()` между запросами в скрипте
4. Перезапустить только ingestion скрипт
5. (Опционально) Перезапустить сервер если очередь зависла

## КРИТИЧЕСКОЕ ПРАВИЛО #2.1: Docker Ollama vs Локальный Ollama

**СИМПТОМЫ конфликта Docker Ollama:**
- Логи показывают: `msg="starting runner" cmd="/usr/bin/ollama runner --ollama-engine --port XXXXX"`
- Множество runner процессов на разных портах (44659, 36269, 39455...)
- Ошибка: `failure during GPU discovery`
- Ошибка: `unable to refresh free memory, using old values`
- GPU утилизация <10%, но VRAM загружена
- Медленная обработка или зависания

**ПРИЧИНА:**
- Docker контейнер Ollama (Linux путь `/usr/bin/ollama`) не видит GPU корректно
- Конфликтует с локальным Ollama на Windows (порт 11434)
- LightRAG пытается использовать Docker Ollama → запросы падают

**РЕШЕНИЕ:**
```powershell
# 1. ВСЕГДА остановить Docker Ollama
docker stop ollama
docker rm ollama

# 2. Проверить локальный Ollama работает
curl http://localhost:11434/api/tags
# Должны увидеть: llama3.1:8b, nomic-embed-text

# 3. Убедиться в конфигурации LightRAG
# E:\AI_Librarian_Core\lightrag_server.py:
# OLLAMA_BASE_URL = "http://localhost:11434"  ← ПРАВИЛЬНО для AI_Librarian_Core!
# ВАЖНО: AGENTS проекты используют 11435, AI_Librarian_Core использует 11434 (дефолтный)

# 4. Перезапустить LightRAG сервер
Get-Process python | Stop-Process -Force
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd E:\AI_Librarian_Core; python lightrag_server.py"

# 5. Перезапустить ingestion
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd E:\AI_Librarian_Core; python ingest_library.py"
```

**ПРАВИЛО:** Для LightRAG использовать ТОЛЬКО локальный Ollama на Windows (порт 11434). Docker Ollama не поддерживает GPU discovery в этой конфигурации.

## КРИТИЧЕСКОЕ ПРАВИЛО #3: Архитектура ingest_library.py

**Как работает скрипт:**
```python
# Отправляет ВСЕ чанки всех файлов
for file in files:
    for chunk in chunks:
        requests.post("/insert", chunk)  # Сервер сам проверяет статус!
```

**Сервер на стороне LightRAG:**
```python
# При получении чанка
if chunk_id in kv_store_doc_status and status == "processed":
    return  # Пропустить, уже обработан
else:
    process(chunk)  # Обработать
```

**Это значит:**
- ✅ `ingest_library.py` **всегда** отправляет все чанки
- ✅ LightRAG **сам** пропускает обработанные
- ✅ НЕ нужно модифицировать скрипт для "пропуска обработанных"
- ✅ Нужно только контролировать **скорость отправки**

## КРИТИЧЕСКОЕ ПРАВИЛО #4: Оптимальная скорость индексации

**Параметры для llama3.1:8b + 4KB чанков:**
- Entity extraction: ~15-30 секунд на чанк
- Рекомендуемая задержка: `time.sleep(15)`
- Скорость: 4 чанка/минуту
- Для 680 чанков: ~170 минут (2ч 50мин)

**Признаки перегрузки:**
- Ошибки 500 от сервера
- GPU утилизация <10% (очередь пустая)
- VRAM загружена, но нет активности

**Решение:** Увеличить задержку, НЕ перезапускать с нуля

## Чеклист перед перезапуском сервера

**ВСЕГДА выполнять ДО любого перезапуска:**

```powershell
# 1. Проверить прогресс
$json = Get-Content "E:\AI_Librarian_Core\lightrag_cache\kv_store_doc_status.json" | ConvertFrom-Json
$st = $json.PSObject.Properties.Value | ForEach-Object { $_.status }
$g = $st | Group-Object
$g | Format-Table

# 2. Проверить размер графа
Get-Item "E:\AI_Librarian_Core\lightrag_cache\graph_chunk_entity_relation.graphml" | Select-Object Length, LastWriteTime

# 3. Проверить здоровье сервера
curl http://localhost:8003/health

# 4. Проверить Ollama
curl http://localhost:11434/api/tags
```

**Только ПОСЛЕ этих проверок принимать решение о перезапуске!**

## Примеры ошибочных решений (НЕ повторять)

### ❌ НЕПРАВИЛЬНО:
```
Пользователь: Ошибки 500
Агент: Перезапущу сервер и ingestion с нуля
Результат: Потеря времени, но НЕ потеря данных (kv_store сохранён)
```

### ✅ ПРАВИЛЬНО:
```
Пользователь: Ошибки 500
Агент: 
  1. Проверяю kv_store_doc_status.json → 410 processed сохранены
  2. Останавливаю ingestion
  3. Добавляю time.sleep(15) в скрипт
  4. Перезапускаю только ingestion
  5. Объясняю: "Прогресс сохранён, продолжаем с 411-го чанка"
```

## Файлы состояния LightRAG (НЕ удалять!)

**Хранят прогресс:**
- `kv_store_doc_status.json` - статус обработки чанков
- `graph_chunk_entity_relation.graphml` - граф знаний
- `kv_store_llm_response_cache.json` - кеш LLM ответов
- `vdb_*.pkl` - векторные индексы

**Удаление этих файлов = потеря ВСЕГО прогресса!**

## Команды для проверки состояния

```powershell
# Быстрый статус
$p = "E:\AI_Librarian_Core\lightrag_cache\kv_store_doc_status.json"
$json = Get-Content $p -Encoding UTF8 | ConvertFrom-Json
$st = $json.PSObject.Properties.Value | ForEach-Object { $_.status }
$g = $st | Group-Object
$proc = ($g | Where-Object Name -eq 'processed').Count
$pend = ($g | Where-Object Name -eq 'pending').Count
"Обработано: $proc | Ожидают: $pend"

# Проверка последнего обновления графа
$gf = Get-Item "E:\AI_Librarian_Core\lightrag_cache\graph_chunk_entity_relation.graphml"
"Размер: $([math]::Round($gf.Length/1MB,2)) MB | Обновлен: $([math]::Round(((Get-Date)-$gf.LastWriteTime).TotalMinutes,1)) мин назад"
```

## Когда МОЖНО полностью сбросить прогресс

**Только в этих случаях:**
1. Пользователь явно просит "начать заново"
2. Изменилась конфигурация модели (llama → qwen)
3. Изменился размер чанков (4000 → 2000 символов)
4. Файлы кеша повреждены (JSON parse error)

**Команда полного сброса:**
```powershell
Remove-Item "E:\AI_Librarian_Core\lightrag_cache\*" -Recurse -Force
# ТОЛЬКО после явного согласия пользователя!
```

---

**Дата создания:** 23 ноября 2025  
**Причина:** Предотвращение повторения ошибки "перезапуск вместо продолжения"  
**Применимость:** Все операции с LightRAG индексацией
