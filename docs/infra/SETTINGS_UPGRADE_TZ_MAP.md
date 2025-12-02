# SETTINGS UPGRADE TECHNICAL SPEC (ТЗ КАРТА)
**Version:** 1.0  
**Date:** 02.12.2025  
**Source Audit:** `AGENT_WORKSPACE_AUDIT_REPORT.md` (12 weaknesses, 6 research blocks)  
**Goal:** Повысить автономность агента (65% → 95%), надежность (B+ → A), переносимость и устойчивость MCP.

---
## 1. Область (Scope)
Охватывает: конфигурацию MCP сервера (`server.ts`), workspace settings (`.vscode/settings.json`), timeout policy (`config/terminal_timeout_policy.json`), механизмы fallback, retry, мониторинг и тестовое покрытие отказов.

Не охватывает: UI визуальные панели, GPU оптимизации, модельные пайплайны, безопасность API ключей.

---
## 2. Цели (Objectives)
1. Устранить критичные препятствия переносимости (hardcoded paths).
2. Внедрить устойчивость к сбоям MCP (Circuit Breaker + health check + graceful fallback).
3. Завершить реализацию timeout policy (использовать все параметры).
4. Добавить управляемый retry для быстрых/средних команд.
5. Верифицировать поведение под параллельными нагрузками (concurrency tests).
6. Покрыть edge cases Base64 encoding (line endings, Unicode, null bytes).

---
## 3. Столпы апгрейта (Upgrade Pillars)
| ID | Pillar | Описание | Основные артефакты | Priority | Indicator |
|----|--------|----------|--------------------|----------|-----------|
| P1 | Path Portability | Динамическое разрешение корня вместо hardcoded `E:/WORLD_OLLAMA` | Updated settings.json logic (guideline), wrapper, env validation | HIGH | 🟥 |
| P2 | MCP Failure Handling | Circuit Breaker, health_check tool, fallback MCP→Terminal | server.ts расширение + лог событий | HIGH | 🟥 |
| P3 | Timeout Policy Completion | Реализация всех параметров: no_output, soft/hard kill, global timeout | server.ts watchdog + policy validator | MEDIUM | 🟧 |
| P4 | Retry Logic | Экспоненциальный backoff, idempotency heuristic | retry wrapper в execute_command | MEDIUM | 🟨 |
| P5 | Concurrency Safety | Лимит процессов, тесты параллелизма, event logging | stress test script + rate limiter | MEDIUM | 🟨 |
| P6 | Encoding Edge Cases | Дополнительные тесты: CRLF, Unicode, null bytes | test_edge_cases_encoding.ps1 | LOW | 🟩 |
| P7 | Pre-Flight & Post-Action Checks | Автоматические проверки перед работой и после критических операций | preflight module + hooks | HIGH | 🟥 |
| P8 | Structured UX Errors | JSON schema сообщений + преобразование технических исключений | error mapping layer | MEDIUM | 🟧 |
| P9 | Logging & Observability | Единый лог: `logs/mcp/mcp-events.log` + метрики p95 | логгер + metrics collector | MEDIUM | 🟧 |
| P10 | Test Coverage Expansion | Отказоустойчивость, timeout, concurrency, fallback | new test suite (PowerShell) | HIGH | 🟥 |

Legend: 🟥 Critical / 🟧 High / 🟨 Medium / 🟩 Low

---
## 4. Требования (Functional / Non-Functional)
### P2 MCP Failure Handling (пример полного блока)
- Functional:
  - F2.1: Инструмент `health_check` возвращает `{status:"ok", ts:<epoch_ms>}`.
  - F2.2: Circuit Breaker состояния: `CLOSED`, `OPEN`, `HALF_OPEN`.
  - F2.3: 3 последовательных ошибки → переход в `OPEN` и включение fallback.
  - F2.4: Успешный health_check в `HALF_OPEN` → возврат в `CLOSED`.
  - F2.5: meta поле в ответе: `{breakerState, retryAttempt, classification}`.
- Non-Functional:
  - NF2.1: Переключение в fallback ≤ 150мс после 3-й ошибки.
  - NF2.2: Логирование всех переходов состояния (state change) ≥ 99% надежности.
  - NF2.3: Zero extra user prompts (автоматическое решение).
- Acceptance:
  - A2.1: Интеграционный тест имитирует 3 timeouts → fallback активен.
  - A2.2: После успешного probe через backoff → breaker возвращается в CLOSED.
  - A2.3: Логи содержат минимум 1 запись перехода OPEN→HALF_OPEN→CLOSED.

(Аналогично применимо к P1–P10; детализировать при реализации.)

---
## 5. Метрики и KPI
| Метрика | Базовое | Цель | Pillars |
|---------|---------|------|---------|
| Автономность (без ручных запросов) | 65% | 95% | P2, P7, P10 |
| Среднее время реакции на сбой MCP | >3s (ручное) | <0.2s | P2 |
| Использование timeout параметров | ~40% | 100% | P3 |
| Успешные автоматические retries (fast cmds) | 0% | ≥70% | P4 |
| Максимум параллельных безопасных процессов | Неизвестно | 5 (лимит) | P5 |
| Edge case encoding coverage | 99% | 99.9% | P6 |
| Pre-flight детекций критичных проблем | 0 | ≥5 типов | P7 |
| UX errors преобразованы (coverage) | 0% | ≥80% | P8 |
| Логи state changes MCP | 0 | ≥1 на цикл отказа | P9 |
| Новые тесты (ошибка/отказ/параллель) | 0 | ≥15 | P10 |

---
## 6. Риск-Аудит и Узкие Места
| Weakness ID | Pillar | Описание | Risk | Indicator | Mitigation |
|-------------|--------|----------|------|-----------|------------|
| W1 | P1 | Hardcoded paths в settings.json | HIGH | 🟥 | Dynamic path wrapper + env validation |
| W2 | P2 | Нет MCP fallback гибридно | HIGH | 🟥 | Circuit Breaker + Terminal fallback |
| W3 | P3 | 4 timeout параметра не реализованы | MEDIUM | 🟧 | Полная интеграция watchdog |
| W4 | P4 | Нет retry/backoff | MEDIUM | 🟨 | Retry wrapper + idempotency heuristic |
| W5 | P5 | Неизвестна concurrency устойчивость | MEDIUM | 🟨 | Stress tests + process limiter |
| W6 | P6 | Не тестированы CRLF/Unicode/null bytes | LOW | 🟩 | Edge case test script |
| W7 | P7 | Нет pre-flight барьеров | HIGH | 🟥 | PreFlightCheck module |
| W8 | P8 | UX сообщения сырье stderr | MEDIUM | 🟧 | Message mapping layer |
| W9 | P9 | Нет централизованного лога состояния | MEDIUM | 🟧 | mcp-events.log + rotate |
| W10 | P10 | Отсутствуют тесты отказов MCP | HIGH | 🟥 | Failure simulation tests |
| W11 | P3 | Нет version validation для policy | MEDIUM | 🟧 | Schema validation + version pin |
| W12 | P2 | Нет классификации протокольных ошибок | MEDIUM | 🟧 | Error taxonomy + mapping |

---
## 7. Приоритетная Карта (Roadmap)
### Легенда: 🟥 Critical / 🟧 High / 🟨 Medium / 🟩 Low / ◻ Pending / ✅ Done

| Phase | Sprint Target | Pillars | Status |
|-------|---------------|---------|--------|
| PHASE 2.1 (Week 1) | Foundation Stability | P1, P2, P7, P10 | ◻ |
| PHASE 2.2 (Week 2) | Policy & Retry | P3, P4 | ◻ |
| PHASE 2.3 (Week 3) | Concurrency & Logging | P5, P9 | ◻ |
| PHASE 2.4 (Week 4) | Edge + UX Polish | P6, P8 | ◻ |

### Критические Gate Criteria
| Gate | Требование | Связанные Pillars |
|------|------------|--------------------|
| G1 "Stability" | Circuit Breaker + health_check + dynamic root | P1, P2 |
| G2 "Resilience" | Timeout полный + retry | P3, P4 |
| G3 "Scalability" | Concurrency tests pass + logs | P5, P9 |
| G4 "Quality" | Edge encoding + UX errors ≥80% | P6, P8 |

---
## 8. Acceptance Checklist (Интеграционный финальный)
- [ ] Dynamic path resolution проверен (перемещение проекта на другой диск).
- [ ] 3 последовательных отказа → fallback (лог содержит OPEN state).
- [ ] no-output watchdog завершает зависшие процессы (>30s без вывода).
- [ ] retry fast commands достигает ≥70% успешных повторов.
- [ ] параллельный запуск 5 команд → без interleaving ошибок, лимит >5 блокирует.
- [ ] Unicode путь в команде не ломает EncodedCommand.
- [ ] Pre-flight чек подавляет начало работы при критических проблемах.
- [ ] UX error mapping преобразует ≥80% stderr в человеко-понятные статусы.
- [ ] Логи содержат p95 время выполнения за сутки.
- [ ] 15 новых тестов (отказ/timeout/concurrency/fallback) зелёные.

---
## 9. KPI Tracking Schema (JSON Proposal)
```json
{
  "version": "1.0",
  "kpi": {
    "autonomy_percent": 95,
    "mcp_failure_recovery_ms": 180,
    "timeouts_policy_usage_percent": 100,
    "retry_success_rate_fast": 72,
    "max_safe_concurrency": 5,
    "encoding_edge_coverage": 99.9,
    "ux_error_mapping_coverage": 82,
    "preflight_issue_detection_count": 6,
    "test_suite_new_cases_passed": 15
  }
}
```

---
## 10. Риски После Внедрения (Residual Risk)
| Risk | Остаток | План смягчения |
|------|---------|----------------|
| Падение терминала VS Code | LOW | Авто-повтор health_check + уведомление |
| Ошибка JSON policy parsing | LOW | Schema validator + fallback defaults |
| Ложные timeouts при долгом IO | MEDIUM | Adaptive no-output (динамический порог) |
| Высокая нагрузка CPU при множестве процессов | MEDIUM | Rate limiter + очереди |
| Ошибки интерпретации stderr в UX | LOW | Регулярное обновление словаря классификатора |

---
## 11. План Мониторинга
| Metric | Источник | Частота | Alert Threshold |
|--------|----------|---------|-----------------|
| breaker OPEN events | mcp-events.log | 1m scan | >5/час |
| avg execution time | aggregated meta | 5m | p95 > baseline*2 |
| retry attempts | meta.retryAttempt | 5m | fail ratio >40% |
| no-output terminations | watchdog counter | 10m | >3/час |
| concurrency blocks | limiter stats | 10m | >10/день |

---
## 12. Следующие Шаги (Next Steps)
1. Утвердить карту ТЗ (этот документ).
2. Создать задачи в трекере: P1–P10 (с указанием Gate критериев).
3. Начать PHASE 2.1 (реализация P1, P2, P7, P10).
4. В конце недели: промежуточный отчёт "PHASE_2_1_STATUS.md".
5. Пересмотреть метрики после первой реализации (обновить KPI JSON).

---
## 13. Резюме
Документ формализует апгрейд настроек агента на основе проведённого аудита: устранение переносимости, повышения отказоустойчивости MCP, завершение политик тайм-аутов, улучшение UX ошибок и расширение тестирования. Переход по фазам гарантирует контролируемое повышение надежности без разрывов текущего рабочего процесса.

---
**End of Spec**
