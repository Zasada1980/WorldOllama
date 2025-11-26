#!/usr/bin/env python3
"""
SYNAPSE Test Suite (TD-007)
Верификация работы Knowledge Connector

Тесты:
1. Health check CORTEX
2. Simple query (проверка базовой функциональности)
3. Structured query (проверка детального запроса)
4. Error handling (проверка обработки ошибок)

Created: 25.11.2025
Author: SESA3002a + GitHub Copilot
"""

import sys
from pathlib import Path

# Добавляем путь к knowledge_client
sys.path.insert(0, str(Path(__file__).parent))

from knowledge_client import (
    lookup_knowledge,
    check_cortex_health,
    CortexConnectionError,
    CortexQueryError
)


def print_section(title: str):
    """Красивый вывод секций"""
    print(f"\n{'='*70}")
    print(f"  {title}")
    print(f"{'='*70}\n")


def test_health_check():
    """Тест 1: Проверка здоровья CORTEX"""
    print_section("TEST 1: CORTEX Health Check")
    
    try:
        health = check_cortex_health()
        print(f"✅ Status: {health['status']}")
        print(f"✅ Working dir exists: {health.get('working_dir_exists', 'unknown')}")
        print(f"✅ Library dir exists: {health.get('library_dir_exists', 'unknown')}")
        return True
    except CortexConnectionError as e:
        print(f"❌ CORTEX недоступен: {e}")
        print("\nЗапустите сервер:")
        print("  pwsh E:\\WORLD_OLLAMA\\scripts\\start_lightrag.ps1")
        return False


def test_simple_query():
    """Тест 2: Простой запрос"""
    print_section("TEST 2: Simple Query")
    
    query = "Какова структура проекта WORLD_OLLAMA?"
    print(f"Query: {query}")
    print(f"Mode: hybrid")
    print("\nОжидание ответа (может занять 30-60 секунд)...")
    
    try:
        answer = lookup_knowledge(query, mode="hybrid")
        
        print(f"\n✅ Ответ получен ({len(answer)} символов):\n")
        print("-" * 70)
        
        # Показываем первые 800 символов
        preview_length = min(800, len(answer))
        print(answer[:preview_length])
        
        if len(answer) > preview_length:
            print(f"\n... ({len(answer) - preview_length} символов скрыто)")
        
        print("-" * 70)
        
        # Проверка качества ответа
        if len(answer) > 100:
            print(f"\n✅ Качество: Ответ содержит {len(answer)} символов (достаточно)")
        else:
            print(f"\n⚠️  Качество: Короткий ответ ({len(answer)} символов)")
        
        return True
        
    except CortexQueryError as e:
        print(f"❌ Ошибка запроса: {e}")
        return False
    except CortexConnectionError as e:
        print(f"❌ Ошибка подключения: {e}")
        return False


def test_structured_query():
    """Тест 3: Детальный технический запрос"""
    print_section("TEST 3: Structured Technical Query")
    
    query = "Как разогнать память RTX 5060 Ti через MSI Afterburner?"
    print(f"Query: {query}")
    print(f"Mode: hybrid (рекомендуемый для технических вопросов)")
    print("\nОжидание ответа...")
    
    try:
        answer = lookup_knowledge(query, mode="hybrid")
        
        print(f"\n✅ Ответ получен ({len(answer)} символов):\n")
        print("-" * 70)
        
        # Показываем первые 600 символов
        preview_length = min(600, len(answer))
        print(answer[:preview_length])
        
        if len(answer) > preview_length:
            print(f"\n... ({len(answer) - preview_length} символов скрыто)")
        
        print("-" * 70)
        
        # Проверка наличия технических терминов
        technical_terms = ["Memory Clock", "MSI Afterburner", "MHz", "VRAM", "разгон"]
        found_terms = [term for term in technical_terms if term.lower() in answer.lower()]
        
        if found_terms:
            print(f"\n✅ Релевантность: Найдены технические термины: {', '.join(found_terms)}")
        else:
            print(f"\n⚠️  Релевантность: Технические термины не найдены")
        
        return True
        
    except CortexQueryError as e:
        print(f"❌ Ошибка запроса: {e}")
        return False
    except CortexConnectionError as e:
        print(f"❌ Ошибка подключения: {e}")
        return False


def test_error_handling():
    """Тест 4: Обработка ошибок"""
    print_section("TEST 4: Error Handling")
    
    # Тест с пустым запросом
    print("4a. Тест пустого запроса...")
    try:
        answer = lookup_knowledge("")
        print("❌ Должна была возникнуть ошибка ValueError")
        return False
    except ValueError as e:
        print(f"✅ ValueError корректно обработан: {e}")
    
    # Тест с некорректным режимом (будет проигнорирован requests)
    print("\n4b. Тест запроса, который может не найти информацию...")
    try:
        answer = lookup_knowledge("Абсолютно случайный текст XYZ123ABC")
        if "не найдена" in answer.lower():
            print(f"✅ Корректный ответ при отсутствии информации: {answer[:100]}")
        else:
            print(f"⚠️  Получен ответ (возможно, нашлось что-то): {answer[:100]}...")
    except Exception as e:
        print(f"⚠️  Неожиданная ошибка: {e}")
    
    return True


def main():
    """Главная функция запуска тестов"""
    print("\n" + "="*70)
    print("  SYNAPSE VERIFICATION TEST SUITE (TD-007)")
    print("  Knowledge Connector: Agent ↔ CORTEX Integration")
    print("="*70)
    
    results = {
        "Health Check": False,
        "Simple Query": False,
        "Structured Query": False,
        "Error Handling": False
    }
    
    # Тест 1: Health Check (критичный)
    results["Health Check"] = test_health_check()
    
    if not results["Health Check"]:
        print("\n❌ КРИТИЧЕСКАЯ ОШИБКА: CORTEX недоступен")
        print("Остальные тесты пропущены.\n")
        sys.exit(1)
    
    # Тест 2: Простой запрос
    results["Simple Query"] = test_simple_query()
    
    # Тест 3: Структурированный запрос
    results["Structured Query"] = test_structured_query()
    
    # Тест 4: Обработка ошибок
    results["Error Handling"] = test_error_handling()
    
    # Итоговый отчет
    print_section("TEST RESULTS SUMMARY")
    
    passed = sum(results.values())
    total = len(results)
    
    for test_name, passed_flag in results.items():
        status = "✅ PASSED" if passed_flag else "❌ FAILED"
        print(f"{test_name:.<50} {status}")
    
    print(f"\n{'='*70}")
    print(f"  TOTAL: {passed}/{total} tests passed")
    
    if passed == total:
        print(f"  VERDICT: ✅ SYNAPSE OPERATIONAL")
        print(f"  Agent ↔ CORTEX connection verified!")
    else:
        print(f"  VERDICT: ⚠️  SOME TESTS FAILED")
        print(f"  Review errors above.")
    
    print(f"{'='*70}\n")
    
    sys.exit(0 if passed == total else 1)


if __name__ == "__main__":
    main()
