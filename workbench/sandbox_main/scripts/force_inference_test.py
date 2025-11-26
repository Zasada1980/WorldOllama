#!/usr/bin/env python3
"""
ОПЕРАЦИЯ "FORCE INFERENCE" - Диагностический стресс-тест
Цель: Форсировать LLM-генерацию с мониторингом VRAM

Created: 26.11.2025
Author: SESA3002a
Protocol: GPU Diagnostic под нагрузкой
"""

import sys
import time
import subprocess
import threading
from pathlib import Path

# Добавляем путь к SYNAPSE connector
sys.path.insert(0, str(Path(__file__).parent.parent.parent.parent / "services" / "connectors" / "synapse"))

from knowledge_client import lookup_knowledge, check_cortex_health

# ЦВЕТА
GREEN = "\033[92m"
RED = "\033[91m"
YELLOW = "\033[93m"
CYAN = "\033[96m"
MAGENTA = "\033[95m"
BOLD = "\033[1m"
RESET = "\033[0m"

# УНИКАЛЬНЫЙ ДИАГНОСТИЧЕСКИЙ ЗАПРОС (некешируемый)
DIAGNOSTIC_QUERY = """Архитектор, проанализируй Принципы ТРИЗ №9 и №11. В чем разница между 'Предварительным антидействием' (№9) и 'Заблаговременной амортизацией' (№11) в контексте защиты AI агентов от джейлбрейка? Исключи стандартные примеры, фокусируйся на когнитивных аналогиях."""

# Глобальные переменные для мониторинга
vram_samples = []
monitoring_active = False


def get_vram_usage():
    """Получить текущее использование VRAM в МБ"""
    try:
        result = subprocess.run(
            ["nvidia-smi", "--query-gpu=memory.used", "--format=csv,noheader,nounits"],
            capture_output=True,
            text=True,
            timeout=2
        )
        if result.returncode == 0:
            vram_mb = int(result.stdout.strip())
            return vram_mb
        return None
    except Exception:
        return None


def monitor_vram_loop():
    """Фоновый мониторинг VRAM с интервалом 1 секунда"""
    global vram_samples, monitoring_active
    
    while monitoring_active:
        vram = get_vram_usage()
        if vram is not None:
            vram_samples.append(vram)
        time.sleep(1)


def print_header():
    """Печать заголовка операции"""
    print(f"\n{RED}╔════════════════════════════════════════════════════════════════╗{RESET}")
    print(f"{RED}║   🔴 ОПЕРАЦИЯ 'FORCE INFERENCE' - GPU DIAGNOSTIC             ║{RESET}")
    print(f"{RED}╚════════════════════════════════════════════════════════════════╝{RESET}\n")
    
    print(f"{YELLOW}ПРОТОКОЛ:{RESET} Диагностический стресс-тест с мониторингом VRAM")
    print(f"{YELLOW}ЦЕЛЬ:{RESET} Форсировать LLM-генерацию для проверки GPU активности\n")
    print(f"{YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{RESET}\n")


def print_query():
    """Печать диагностического запроса"""
    print(f"{BOLD}{MAGENTA}ДИАГНОСТИЧЕСКИЙ ЗАПРОС (некешируемый):{RESET}\n")
    print(f"{CYAN}{DIAGNOSTIC_QUERY}{RESET}\n")
    print(f"{YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{RESET}\n")


def analyze_vram(vram_samples, response_time):
    """Анализ паттернов VRAM"""
    print(f"\n{YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{RESET}\n")
    print(f"{BOLD}{MAGENTA}АНАЛИЗ VRAM (GPU DIAGNOSTIC):{RESET}\n")
    
    if not vram_samples:
        print(f"{RED}❌ НЕТ ДАННЫХ VRAM{RESET}")
        print(f"{YELLOW}   nvidia-smi недоступен или GPU не обнаружен{RESET}\n")
        return False
    
    baseline = vram_samples[0]
    peak = max(vram_samples)
    avg = sum(vram_samples) / len(vram_samples)
    delta = peak - baseline
    
    print(f"  📊 Статистика VRAM:")
    print(f"     Базовая линия: {baseline} MB")
    print(f"     Пиковое значение: {peak} MB")
    print(f"     Среднее значение: {avg:.1f} MB")
    print(f"     Дельта (пик-база): {delta} MB")
    print(f"     Время генерации: {response_time:.1f} секунд")
    print(f"     Образцов собрано: {len(vram_samples)}\n")
    
    # График VRAM (ASCII)
    print(f"  📈 График VRAM (каждая точка = 1 секунда):\n")
    max_bar_width = 50
    for i, vram in enumerate(vram_samples[:30]):  # Первые 30 секунд
        bar_width = int((vram / peak) * max_bar_width) if peak > 0 else 0
        bar = "█" * bar_width
        print(f"     {i:2d}s: {bar} {vram} MB")
    
    if len(vram_samples) > 30:
        print(f"     ... (ещё {len(vram_samples) - 30} образцов)\n")
    else:
        print()
    
    # Диагностика
    print(f"{YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{RESET}\n")
    print(f"{BOLD}{CYAN}ВЕРДИКТ:{RESET}\n")
    
    if peak > 9000:  # > 9 GB
        print(f"{GREEN}✅ GPU АКТИВЕН: Пиковое потребление {peak} MB (>{9000} MB){RESET}")
        print(f"{GREEN}   LLM генерирует токены на GPU корректно.{RESET}")
        print(f"{GREEN}   Cache Hit маловероятен (наблюдался рост VRAM).{RESET}\n")
        return True
    elif peak > 2000 and delta > 1000:  # Рост > 1 GB
        print(f"{YELLOW}⚠️ GPU ЧАСТИЧНО АКТИВЕН: Пик {peak} MB, дельта {delta} MB{RESET}")
        print(f"{YELLOW}   Модель загружена, но потребление ниже ожидаемого.{RESET}")
        print(f"{YELLOW}   Возможные причины:{RESET}")
        print(f"{YELLOW}   • Частичное кэширование промптов{RESET}")
        print(f"{YELLOW}   • Модель квантизована (q4_k_m использует меньше VRAM){RESET}")
        print(f"{YELLOW}   • Batching отключен (последовательная генерация){RESET}\n")
        return True
    else:
        print(f"{RED}❌ GPU OFFLINE или CACHE HIT: Пик {peak} MB (<2000 MB){RESET}")
        print(f"{RED}   VRAM не рос во время генерации.{RESET}")
        print(f"{YELLOW}   Возможные причины:{RESET}")
        print(f"{YELLOW}   • LLM-кэш сработал (ответ из кэша, без GPU){RESET}")
        print(f"{YELLOW}   • Ollama не использует GPU (проверьте 'ollama ps'){RESET}")
        print(f"{YELLOW}   • Модель не загружена в VRAM{RESET}\n")
        
        print(f"{CYAN}Рекомендации:{RESET}")
        print(f"  1. Проверьте: nvidia-smi")
        print(f"  2. Проверьте: ollama ps")
        print(f"  3. Очистите кэш: curl -X POST http://localhost:11434/api/generate -d '{{\"model\":\"qwen2.5:14b\",\"keep_alive\":0}}'")
        print(f"  4. Перезапустите Ollama\n")
        
        return False


def main():
    """Основная функция стресс-теста"""
    global vram_samples, monitoring_active
    
    print_header()
    
    # Проверка CORTEX
    print(f"{CYAN}Проверка связи с CORTEX...{RESET}")
    try:
        health = check_cortex_health()
        print(f"{GREEN}✓ CORTEX онлайн: {health['status']}{RESET}\n")
    except Exception as e:
        print(f"{RED}✗ Ошибка подключения к CORTEX: {e}{RESET}\n")
        sys.exit(1)
    
    # Начальное состояние VRAM
    baseline_vram = get_vram_usage()
    if baseline_vram is None:
        print(f"{RED}❌ nvidia-smi недоступен. Проверьте установку драйвера GPU.{RESET}\n")
        sys.exit(1)
    
    print(f"{CYAN}Базовое потребление VRAM: {baseline_vram} MB{RESET}\n")
    
    print_query()
    
    # Запуск мониторинга VRAM в фоне
    print(f"{CYAN}🔍 Запуск фонового мониторинга VRAM (интервал 1 секунда)...{RESET}\n")
    monitoring_active = True
    monitor_thread = threading.Thread(target=monitor_vram_loop, daemon=True)
    monitor_thread.start()
    
    # Выполнение диагностического запроса
    print(f"{YELLOW}⏳ Отправка запроса в CORTEX (режим: hybrid)...{RESET}")
    print(f"{YELLOW}   Ожидайте 60-120 секунд для полной генерации...{RESET}\n")
    
    start_time = time.time()
    
    try:
        response = lookup_knowledge(
            query=DIAGNOSTIC_QUERY,
            mode="hybrid",
            timeout=180  # 3 минуты для сложного запроса
        )
        
        elapsed_time = time.time() - start_time
        
        # Остановка мониторинга
        monitoring_active = False
        time.sleep(2)  # Даем время последним образцам
        
        # Вывод ответа
        print(f"\n{BOLD}{GREEN}ОТВЕТ ПОЛУЧЕН{RESET} (за {elapsed_time:.1f} секунд)\n")
        print(f"{YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{RESET}\n")
        print(f"{CYAN}{response[:500]}...{RESET}\n")
        print(f"{YELLOW}(Полная длина ответа: {len(response)} символов){RESET}")
        
        # Анализ VRAM
        gpu_active = analyze_vram(vram_samples, elapsed_time)
        
        # Финальный статус
        if gpu_active:
            print(f"{BOLD}{GREEN}╔════════════════════════════════════════════════════════════════╗{RESET}")
            print(f"{BOLD}{GREEN}║   ✅ ОПЕРАЦИЯ 'FORCE INFERENCE' УСПЕШНА                       ║{RESET}")
            print(f"{BOLD}{GREEN}╚════════════════════════════════════════════════════════════════╝{RESET}\n")
            print(f"{GREEN}GPU активно генерировал токены. Система работает корректно.{RESET}\n")
            sys.exit(0)
        else:
            print(f"{BOLD}{YELLOW}╔════════════════════════════════════════════════════════════════╗{RESET}")
            print(f"{BOLD}{YELLOW}║   ⚠️ ТРЕБУЕТСЯ ДИАГНОСТИКА GPU                                ║{RESET}")
            print(f"{BOLD}{YELLOW}╚════════════════════════════════════════════════════════════════╝{RESET}\n")
            sys.exit(1)
            
    except Exception as e:
        monitoring_active = False
        
        print(f"\n{RED}❌ Ошибка выполнения запроса: {e}{RESET}\n")
        
        if "timeout" in str(e).lower():
            print(f"{YELLOW}⏱️ TIMEOUT: Запрос превысил 180 секунд{RESET}")
            print(f"{YELLOW}   Это может указывать на проблемы с GPU или медленную генерацию.{RESET}\n")
            
            # Анализируем VRAM даже при timeout
            if vram_samples:
                analyze_vram(vram_samples, 180)
        
        sys.exit(1)


if __name__ == "__main__":
    main()
