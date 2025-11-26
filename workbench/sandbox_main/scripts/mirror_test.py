#!/usr/bin/env python3
"""
MIRROR TEST - Когнитивная Валидация (TD-005)
Проверка способности Агента синтезировать знания из базы ТРИЗ

Created: 26.11.2025
Author: SESA3002a
Protocol: Финальная валидация проекта WORLD_OLLAMA
"""

import sys
import time
from pathlib import Path

# Добавляем путь к SYNAPSE connector
sys.path.insert(0, str(Path(__file__).parent.parent.parent.parent / "services" / "connectors" / "synapse"))

from knowledge_client import lookup_knowledge, check_cortex_health

# ЦВЕТА ДЛЯ КОНСОЛИ
GREEN = "\033[92m"
RED = "\033[91m"
YELLOW = "\033[93m"
CYAN = "\033[96m"
MAGENTA = "\033[95m"
BOLD = "\033[1m"
RESET = "\033[0m"

# ТЕСТОВЫЙ ЗАПРОС
TEST_QUERY = "Как применить принцип дробления для оптимизации архитектуры AI агента?"

def print_header():
    """Печать заголовка теста"""
    print(f"\n{CYAN}╔════════════════════════════════════════════════════════════════╗{RESET}")
    print(f"{CYAN}║        🧪 MIRROR TEST - КОГНИТИВНАЯ ВАЛИДАЦИЯ                 ║{RESET}")
    print(f"{CYAN}╚════════════════════════════════════════════════════════════════╝{RESET}\n")
    
    print(f"{YELLOW}ПРОТОКОЛ:{RESET} TD-005 (Cognitive Synthesis Validation)")
    print(f"{YELLOW}ЦЕЛЬ:{RESET} Подтвердить способность Агента синтезировать знания\n")
    print(f"{YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{RESET}\n")


def print_query():
    """Печать тестового запроса"""
    print(f"{BOLD}{MAGENTA}ТЕСТОВЫЙ ЗАПРОС:{RESET}")
    print(f"{CYAN}\"{TEST_QUERY}\"{RESET}\n")
    print(f"{YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{RESET}\n")


def analyze_response(response: str, elapsed_time: float):
    """
    Анализ ответа по критериям TD-005
    
    Критерии успеха:
    1. Упоминание Принципа ТРИЗ №1 (Дробление)
    2. Конкретные примеры из базы (MoE, микросервисы, CoT)
    3. Синтез решения, а не просто цитирование
    4. Время ответа < 90 секунд
    """
    print(f"{BOLD}{GREEN}ОТВЕТ ПОЛУЧЕН{RESET} (за {elapsed_time:.1f} секунд)\n")
    print(f"{YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{RESET}\n")
    
    # Вывод ответа
    print(f"{CYAN}{response}{RESET}\n")
    print(f"{YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{RESET}\n")
    
    # Анализ по критериям TD-005
    print(f"{BOLD}{MAGENTA}АНАЛИЗ ПО TD-005 (Критерии Когнитивного Синтеза):{RESET}\n")
    
    response_lower = response.lower()
    
    # Критерий 1: Упоминание принципа
    has_principle = any(keyword in response_lower for keyword in [
        "дробление", "принцип 1", "принцип №1", "разделение", "декомпозиция"
    ])
    print(f"  {'✅' if has_principle else '❌'} Критерий 1: Упоминание Принципа №1 (Дробление)")
    
    # Критерий 2: Конкретные примеры
    examples_found = []
    examples = {
        "MoE": ["mixture of experts", "moe", "смесь экспертов"],
        "Микросервисы": ["микросервис", "microservice", "модул"],
        "CoT": ["chain of thought", "cot", "цепочка рассуждений"],
        "Специализация": ["специализ", "специфик", "разделен"],
    }
    
    for example_name, keywords in examples.items():
        if any(kw in response_lower for kw in keywords):
            examples_found.append(example_name)
    
    has_examples = len(examples_found) > 0
    print(f"  {'✅' if has_examples else '❌'} Критерий 2: Конкретные примеры")
    if examples_found:
        print(f"     Найдено: {', '.join(examples_found)}")
    
    # Критерий 3: Синтез (не простое цитирование)
    # Проверяем наличие слов синтеза
    synthesis_words = [
        "применить", "использовать", "можно", "рекомендуется", 
        "следует", "позволяет", "помогает", "оптимизировать"
    ]
    has_synthesis = any(word in response_lower for word in synthesis_words)
    has_long_answer = len(response) > 200  # Синтез обычно требует развернутого ответа
    
    is_synthesis = has_synthesis and has_long_answer
    print(f"  {'✅' if is_synthesis else '❌'} Критерий 3: Синтез решения (не цитирование)")
    
    # Критерий 4: Время ответа
    is_fast = elapsed_time < 90
    print(f"  {'✅' if is_fast else '⚠️'} Критерий 4: Время ответа < 90 сек ({elapsed_time:.1f}s)")
    
    # Финальная оценка
    print(f"\n{YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{RESET}\n")
    
    criteria_passed = sum([has_principle, has_examples, is_synthesis, is_fast])
    total_criteria = 4
    
    if criteria_passed == total_criteria:
        print(f"{BOLD}{GREEN}✅ MIRROR TEST: ПРОЙДЕН ({criteria_passed}/{total_criteria} критериев){RESET}")
        print(f"{GREEN}   Агент успешно синтезирует знания из базы ТРИЗ!{RESET}\n")
        return True
    elif criteria_passed >= 3:
        print(f"{BOLD}{YELLOW}⚠️ MIRROR TEST: ЧАСТИЧНО ПРОЙДЕН ({criteria_passed}/{total_criteria} критериев){RESET}")
        print(f"{YELLOW}   Агент демонстрирует базовый синтез, но есть улучшения.{RESET}\n")
        return True
    else:
        print(f"{BOLD}{RED}❌ MIRROR TEST: НЕ ПРОЙДЕН ({criteria_passed}/{total_criteria} критериев){RESET}")
        print(f"{RED}   Агент требует дополнительной настройки.{RESET}\n")
        return False


def main():
    """Основная функция теста"""
    print_header()
    
    # Проверка здоровья CORTEX
    print(f"{CYAN}Проверка связи с CORTEX...{RESET}")
    try:
        health = check_cortex_health()
        print(f"{GREEN}✓ CORTEX онлайн: {health['status']}{RESET}\n")
    except Exception as e:
        print(f"{RED}✗ Ошибка подключения к CORTEX: {e}{RESET}\n")
        print(f"{YELLOW}Убедитесь что система запущена: E:\\WORLD_OLLAMA\\USER\\START_ALL.ps1{RESET}\n")
        sys.exit(1)
    
    print_query()
    
    # Выполнение запроса
    print(f"{CYAN}Отправка запроса в CORTEX (режим: hybrid)...{RESET}")
    print(f"{YELLOW}Ожидайте 30-90 секунд...{RESET}\n")
    
    start_time = time.time()
    
    try:
        response = lookup_knowledge(
            query=TEST_QUERY,
            mode="hybrid",  # Адаптивный режим для лучшего синтеза
            timeout=120
        )
        
        elapsed_time = time.time() - start_time
        
        # Анализ ответа
        success = analyze_response(response, elapsed_time)
        
        # Финальный статус
        if success:
            print(f"{BOLD}{GREEN}╔════════════════════════════════════════════════════════════════╗{RESET}")
            print(f"{BOLD}{GREEN}║   🎉 КОГНИТИВНАЯ ВАЛИДАЦИЯ УСПЕШНА                            ║{RESET}")
            print(f"{BOLD}{GREEN}╚════════════════════════════════════════════════════════════════╝{RESET}\n")
            print(f"{GREEN}Проект WORLD_OLLAMA готов к продуктивной эксплуатации.{RESET}\n")
            sys.exit(0)
        else:
            print(f"{BOLD}{RED}╔════════════════════════════════════════════════════════════════╗{RESET}")
            print(f"{BOLD}{RED}║   ⚠️ ТРЕБУЕТСЯ ДОПОЛНИТЕЛЬНАЯ НАСТРОЙКА                       ║{RESET}")
            print(f"{BOLD}{RED}╚════════════════════════════════════════════════════════════════╝{RESET}\n")
            print(f"{YELLOW}Рекомендация: Fine-tuning через LLaMA Board (TD-009){RESET}\n")
            sys.exit(1)
            
    except Exception as e:
        print(f"{RED}❌ Ошибка выполнения запроса: {e}{RESET}\n")
        
        # Диагностика
        if "timeout" in str(e).lower():
            print(f"{YELLOW}⏱️ TIMEOUT: CORTEX генерирует ответ дольше 120 секунд{RESET}")
            print(f"{YELLOW}   Это нормально для сложных запросов в режиме hybrid.{RESET}")
            print(f"{YELLOW}   Попробуйте режим 'naive' для более быстрого ответа.{RESET}\n")
        elif "401" in str(e) or "unauthorized" in str(e).lower():
            print(f"{RED}🔒 ОШИБКА АУТЕНТИФИКАЦИИ: API Key не принят{RESET}")
            print(f"{YELLOW}   Проверьте CORTEX_API_KEY в переменных окружения.{RESET}\n")
        else:
            print(f"{YELLOW}Проверьте статус CORTEX: http://localhost:8004/health{RESET}\n")
        
        sys.exit(1)


if __name__ == "__main__":
    main()
