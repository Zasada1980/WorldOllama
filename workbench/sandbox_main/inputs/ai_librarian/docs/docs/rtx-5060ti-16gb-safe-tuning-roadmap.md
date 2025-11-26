# Карта безопасного разгона RTX 5060 Ti 16 GB (Blackwell)

**Цель:** Максимальная стабильность + долговечность (24/7 режим)  
**Критерии приёма:** 0 крашей, температура <75°C, напряжение <1.0В

---

## Фаза 0: Подготовка (15 минут)

### Установка ПО

```powershell
# Проверка версии Afterburner (нужна 4.6.6+)
$afterburner = Get-ItemProperty "C:\Program Files (x86)\MSI Afterburner\MSIAfterburner.exe" | Select-Object -ExpandProperty VersionInfo
$afterburner.ProductVersion

# Если < 4.6.6 → скачать с https://www.msi.com/Landing/afterburner/graphics-cards
```

**Чек-лист:**
- ✅ MSI Afterburner 4.6.6+
- ✅ NVIDIA Driver 570.xx+
- ✅ HWiNFO64 для мониторинга Hotspot/Memory Junction
- ✅ 3DMark Steel Nomad (или Unigine Superposition)

### Разблокировка Afterburner

1. Settings (⚙️) → General
2. ✅ **Unlock voltage control** → режим "Standard MSI"
3. ✅ **Unlock voltage monitoring**
4. ✅ **Extend official overclocking limits** (если есть)
5. OK → перезапустить Afterburner

---

## Фаза 1: Настройка кривой вентиляторов (10 минут)

**Проблема RTX 50:** Минимум 30% = ~1200 RPM = избыточный шум + циклы вкл/выкл.

### Оптимальная кривая для 16 GB версии

Settings → Fan → ✅ Enable user defined software automatic fan control

| Температура | Fan Speed | Примечание |
|-------------|-----------|------------|
| 0-50°C      | 0%        | Пассивный режим (0 RPM) |
| 55°C        | 35%       | Гарантированный старт |
| 60°C        | 45%       | Умеренная нагрузка |
| 70°C        | 65%       | LLM-задачи (длительные) |
| 75°C        | 80%       | Агрессивное охлаждение |
| 80°C        | 100%      | Аварийный режим |

**Гистерезис:** 5-7°C (вентилятор включился при 60°C → выключится при 55°C)

**Тест:**
```powershell
# Запустить нагрузку, проверить температуру через 5 минут
curl -X POST http://localhost:8003/query -H "Content-Type: application/json" -d '{\"query\":\"test load\",\"mode\":\"naive\"}' --max-time 300
nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader
```

**Цель:** <70°C под нагрузкой, вентилятор не циклится.

---

## Фаза 2: Базовый андервольтинг (30 минут)

**Почему андервольтинг, а не оверклок?**
- RTX 5060 Ti упирается в Power Limit (180W) раньше, чем в предел частоты
- Снижение напряжения → меньше нагрев → нет троттлинга → **выше средняя частота**

### Шаг 2.1: Поиск "Sweet Spot" (0.925-0.975V)

**Алгоритм:**

1. **Сброс:** Reset в Afterburner
2. **Ctrl+F:** Открыть Curve Editor
3. **Базовая линия:** Посмотреть заводские точки:
   - 1.05V → ~2700 MHz (типичное)
   - 0.950V → ~2500 MHz

4. **Целевая точка:** Выбрать **0.950V**
   - Кликнуть на точку 950 mV
   - Потянуть вверх до **2700 MHz** (как у 1.05V!)

5. **Flattening (критично!):**
   - Выделить все точки **ПРАВЕЕ** 950 mV
   - Опустить их на уровень 2700 MHz или ниже
   - Это запрещает GPU использовать напряжения >0.950V

6. **Apply** (галочка)

### Шаг 2.2: Первичный тест (10 минут)

```powershell
# Запустить LightRAG query loop
1..10 | ForEach-Object {
    curl -X POST http://localhost:8003/query -H "Content-Type: application/json" -d '{\"query\":\"test $_\",\"mode\":\"naive\"}' --max-time 60
    Start-Sleep 5
}

# Мониторинг
nvidia-smi --query-gpu=clocks.gr,clocks.mem,temperature.gpu,power.draw --format=csv --loop=5
```

**Критерии успеха:**
- ✅ Частота держится ~2700 MHz
- ✅ Температура <70°C
- ✅ Power Draw <160W (было 180W!)
- ✅ 0 крашей

**Если нестабильно:**
- Снизить частоту точки 950 mV до 2650 MHz
- Повторить тест

**Если стабильно:**
- Поднять до 2750 MHz
- Тест 20 минут

### Шаг 2.3: Итерация до предела

Продолжать +25 MHz каждые 20 минут, пока:
- Не появится краш → откатить -50 MHz
- ИЛИ частота не перестанет расти (упёрлись в другие лимиты)

**Ожидаемый результат для RTX 5060 Ti 16GB:**
- **2700-2850 MHz @ 0.950V** (консервативный)
- **2850-2900 MHz @ 0.975V** (агрессивный, но безопасный)

---

## Фаза 3: Оптимизация памяти GDDR7 (60 минут)

**КРИТИЧНО:** GDDR7 имеет ECC → карта **не крашится** при переразгоне, но **тормозит**!

### Проблема "ложной стабильности"

```
+500 MHz → +5% FPS ✅
+1000 MHz → +8% FPS ✅
+1500 MHz → +9% FPS ⚠️ (прирост замедлился)
+2000 MHz → +7% FPS ❌ (производительность УПАЛА!)
```

**Причина:** ECC исправляет ошибки, тратя такты на повторную передачу.

### Шаг 3.1: Пошаговый поиск предела (по FPS)

**Инструмент:** Unigine Superposition 4K Optimized (фиксированная нагрузка)

```powershell
# Скачать: https://benchmark.unigine.com/superposition
# Настройки: 4K Optimized, Fullscreen, VSync OFF
```

**Методика:**

| Memory Clock | Тест             | Баллы | Комментарий |
|--------------|------------------|-------|-------------|
| 0 MHz        | Superposition    | XXXX  | Baseline    |
| +300 MHz     | Superposition    | XXXX  | Должен вырасти |
| +600 MHz     | Superposition    | XXXX  | Продолжаем  |
| +900 MHz     | Superposition    | XXXX  | Проверяем рост |
| +1200 MHz    | Superposition    | XXXX  | Если рост <2% от +900 → СТОП |
| +1500 MHz    | Superposition    | XXXX  | Только если +1200 дал прирост >3% |

**Правило:** Как только прирост FPS **<2% на шаге +300 MHz** → это предел ECC.

### Шаг 3.2: Откат на безопасный запас

Найденный предел **минус 200 MHz** = финальное значение.

**Пример:**
- +1500 MHz показал пик производительности
- Финал: **+1300 MHz** (откат для 24/7 стабильности)

**Ожидаемый диапазон для RTX 5060 Ti 16GB:**
- **+1000 - +1300 MHz** (типично для 16 GB версии из-за двойной плотности чипов)
- Версия 8 GB может давать +1500-+1800 MHz (меньше емкостная нагрузка)

### Шаг 3.3: Проверка температуры памяти

```powershell
# HWiNFO64 → GPU Memory Junction Temperature
# Должно быть <90°C под нагрузкой

# Если >90°C:
# 1. Увеличить Fan Curve до 70% при 70°C GPU
# 2. Снизить Memory Clock на -200 MHz
```

---

## Фаза 4: Финальная валидация (120 минут)

### Тест 4.1: Синтетика (30 мин)

```powershell
# 3DMark Steel Nomad Stress Test (20 циклов)
# Критерий: >97% успешность

# Если <97%:
# - Core Clock: -25 MHz
# - Memory Clock: -100 MHz
# Повторить
```

### Тест 4.2: Реальная нагрузка LLM (60 мин)

```powershell
# Запустить LightRAG индексацию небольшого набора (100 файлов)
cd E:\AI_Librarian_Core
python ingest_library.py --max-files 100

# Параллельно мониторить
nvidia-smi --query-gpu=clocks.gr,temperature.gpu,power.draw,clocks_throttle_reasons.active --format=csv --loop=10 > gpu_stability_log.csv

# Через час проверить:
Get-Content gpu_stability_log.csv | Select-String "Active" | Measure-Object
# Если >0 строк с "Active" throttling → проблема!
```

**Throttling Reasons:**
- `Sw Power` → упёрлись в 180W лимит (это норма для RTX 5060 Ti)
- `Sw Thermal` → перегрев! Улучшить кривую вентиляторов
- `Sw Voltage Reliability` → напряжение нестабильно, снизить Core Clock

### Тест 4.3: Длительная стабильность (опционально, 8+ часов)

Для критичных задач (серверное использование):

```powershell
# Ночной тест
pwsh -File E:\AI_Librarian_Core\test_gpu_stability.ps1 -DurationMinutes 480
```

---

## Финальная конфигурация (Золотая середина)

### Консервативный профиль (рекомендуется для 24/7)

**MSI Afterburner:**
```
Power Limit: 100% (180W max — аппаратный лимит)
Core Voltage: Curve @ 0.950V → 2750 MHz
Memory Clock: +1100 MHz
Fan Curve: Custom (см. Фазу 1)
```

**Ожидаемые показатели:**
- Частота ядра: **2750 MHz** стабильно (было 2700 MHz с плаванием)
- Энергопотребление: **~160W** (экономия 20W)
- Температура: **62-68°C** (было 70-75°C)
- FPS прирост: **+6-8%** от стока

### Агрессивный профиль (для бенчмарков)

**MSI Afterburner:**
```
Power Limit: 100%
Core Voltage: Curve @ 0.975V → 2850 MHz
Memory Clock: +1300 MHz
Fan Curve: 75% при 70°C
```

**Ожидаемые показатели:**
- Частота ядра: **2850 MHz**
- Энергопотребление: **~175W** (близко к лимиту)
- Температура: **70-73°C**
- FPS прирост: **+10-12%** от стока

---

## Критерии безопасности (НЕ ПРЕВЫШАТЬ!)

| Параметр                  | Максимум (24/7) | Аварийный лимит |
|---------------------------|-----------------|-----------------|
| Core Voltage              | 1.000V          | 1.050V          |
| GPU Temperature           | 75°C            | 83°C (троттлинг)|
| Hotspot Temperature       | 85°C            | 95°C            |
| Memory Junction Temp      | 90°C            | 95°C            |
| Power Draw                | 180W            | 180W (лимит)    |
| Memory Clock (эффективный)| +1300 MHz       | +2000 MHz*      |

\* +2000 MHz физически возможен, но ECC съедает производительность

---

## Сохранение профиля

После успешных тестов:

1. **MSI Afterburner:** Save icon (дискета) → **Profile 1**
2. ✅ **Apply overclocking at system startup**
3. Settings → Profiles → **Synchronize settings for similar graphics processors**
4. **Backup профиля:**

```powershell
Copy-Item "C:\Program Files (x86)\MSI Afterburner\Profiles\*" "E:\AI_Librarian_Core\backups\afterburner_$(Get-Date -Format 'yyyyMMdd')\" -Recurse
```

---

## Чек-лист готовности

- [ ] Fan Curve настроена (гистерезис 5-7°C)
- [ ] Андервольтинг протестирован 30+ минут без крашей
- [ ] Memory Clock найден методом FPS-бенчмарка
- [ ] Температура Memory Junction <90°C
- [ ] Нет активных Throttle Reasons (кроме Sw Power)
- [ ] 3DMark Stress Test >97%
- [ ] LLM-нагрузка 60 минут без ошибок
- [ ] Профиль сохранён + backup создан

---

## Диагностика проблем

### Проблема: Краш через 10-15 минут

**Причина:** Ядро нестабильно  
**Решение:** Core Clock -25 MHz → повторить тест

### Проблема: FPS ниже чем на стоке

**Причина:** Memory Clock переразогнана, ECC тормозит  
**Решение:** Memory Clock -300 MHz → повторить Superposition

### Проблема: Температура >80°C

**Причина:** Кривая вентиляторов слабая  
**Решение:** Увеличить Fan Speed на 10-15% на всех точках

### Проблема: "Sw Thermal Slowdown" в логе

**Причина:** Перегрев → троттлинг  
**Решение:**
1. Улучшить кривую вентиляторов
2. Снизить Core Voltage до 0.925V
3. Проверить пыль в кулере

### Проблема: Артефакты в браузере (шахматный паттерн)

**Причина:** Известный баг драйверов RTX 50 + Chromium  
**Решение:** НЕ связано с разгоном! Обновить драйвер до 575.xx+

---

## Источники и ссылки

- NVIDIA RTX Blackwell Architecture (PDF)
- MSI Official Guide: RTX 5070/5060 Ti Overclocking
- Reddit: r/overclocking RTX 5000 series threads
- TechPowerUp GPU Database: RTX 5060 Ti specs
