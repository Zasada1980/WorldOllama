#!/usr/bin/env python3
"""
Security Perimeter Tests - ОПЕРАЦИЯ "SECURE ENCLAVE"
Тесты изоляции CORTEX (LightRAG) с API Key защитой

Цель: Доказать, что CORTEX недоступен без правильного ключа

ТРИЗ Принцип №11 "Заблаговременная амортизация":
  Проверяем защиту до развертывания в production

Created: 26.11.2025
Author: SESA3002a
"""

import requests
import sys
import os
from pathlib import Path

# Цветной вывод
class Colors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'


# Конфигурация
CORTEX_BASE_URL = "http://localhost:8004"
VALID_API_KEY = os.getenv("CORTEX_API_KEY", "sesa-secure-core-v1")
INVALID_API_KEY = "fake-key-12345"

# Счетчики
tests_passed = 0
tests_failed = 0


def print_test_header(test_name: str):
    """Печать заголовка теста"""
    print(f"\n{Colors.HEADER}{'='*70}{Colors.ENDC}")
    print(f"{Colors.HEADER}{Colors.BOLD}TEST: {test_name}{Colors.ENDC}")
    print(f"{Colors.HEADER}{'='*70}{Colors.ENDC}\n")


def print_success(message: str):
    """Печать успешного результата"""
    global tests_passed
    tests_passed += 1
    print(f"{Colors.OKGREEN}✓ PASS:{Colors.ENDC} {message}")


def print_failure(message: str):
    """Печать неудачного результата"""
    global tests_failed
    tests_failed += 1
    print(f"{Colors.FAIL}✗ FAIL:{Colors.ENDC} {message}")


def print_info(message: str):
    """Печать информационного сообщения"""
    print(f"{Colors.OKCYAN}ℹ INFO:{Colors.ENDC} {message}")


def test_1_health_check_public():
    """
    Тест 1: /health доступен БЕЗ API ключа
    
    Ожидание: 200 OK
    Обоснование: Health check должен быть доступен для мониторинга
    """
    print_test_header("1. Health Check - Public Access")
    
    try:
        response = requests.get(f"{CORTEX_BASE_URL}/health", timeout=5)
        
        if response.status_code == 200:
            print_success(f"Health check доступен без ключа (200 OK)")
            print_info(f"Response: {response.json()}")
        else:
            print_failure(f"Unexpected status code: {response.status_code}")
    
    except requests.exceptions.ConnectionError:
        print_failure("CORTEX server не запущен! Запустите: pwsh scripts\\start_lightrag.ps1")
        sys.exit(1)
    except Exception as e:
        print_failure(f"Ошибка: {str(e)}")


def test_2_query_without_key():
    """
    Тест 2: /query БЕЗ API ключа должен вернуть 401 Unauthorized
    
    Ожидание: 401 UNAUTHORIZED
    КРИТИЧНО: Это основная проверка защиты CORTEX
    """
    print_test_header("2. Query Endpoint - Unauthorized Access (NO KEY)")
    
    try:
        payload = {
            "query": "Тестовый запрос без ключа",
            "mode": "naive"
        }
        
        # Запрос БЕЗ заголовка X-API-KEY
        response = requests.post(
            f"{CORTEX_BASE_URL}/query",
            json=payload,
            timeout=10
        )
        
        if response.status_code == 401:
            print_success(f"Доступ заблокирован без ключа (401 Unauthorized)")
            print_info(f"Response: {response.json()}")
        else:
            print_failure(
                f"КРИТИЧЕСКАЯ УЯЗВИМОСТЬ: Доступ разрешен без ключа! "
                f"Status: {response.status_code}"
            )
    
    except Exception as e:
        print_failure(f"Ошибка теста: {str(e)}")


def test_3_query_with_invalid_key():
    """
    Тест 3: /query с НЕПРАВИЛЬНЫМ API ключом должен вернуть 401
    
    Ожидание: 401 UNAUTHORIZED
    """
    print_test_header("3. Query Endpoint - Invalid API Key")
    
    try:
        payload = {
            "query": "Тестовый запрос с неверным ключом",
            "mode": "naive"
        }
        
        # Запрос с НЕПРАВИЛЬНЫМ ключом
        headers = {"X-API-KEY": INVALID_API_KEY}
        response = requests.post(
            f"{CORTEX_BASE_URL}/query",
            json=payload,
            headers=headers,
            timeout=10
        )
        
        if response.status_code == 401:
            print_success(f"Доступ заблокирован с неверным ключом (401 Unauthorized)")
            print_info(f"Response: {response.json()}")
        else:
            print_failure(
                f"КРИТИЧЕСКАЯ УЯЗВИМОСТЬ: Доступ разрешен с неверным ключом! "
                f"Status: {response.status_code}"
            )
    
    except Exception as e:
        print_failure(f"Ошибка теста: {str(e)}")


def test_4_query_with_valid_key():
    """
    Тест 4: /query с ПРАВИЛЬНЫМ API ключом должен работать
    
    Ожидание: 200 OK + корректный ответ
    """
    print_test_header("4. Query Endpoint - Valid API Key (Authorized)")
    
    try:
        payload = {
            "query": "Структура проекта WORLD_OLLAMA",
            "mode": "hybrid"
        }
        
        # Запрос с ПРАВИЛЬНЫМ ключом
        headers = {"X-API-KEY": VALID_API_KEY}
        response = requests.post(
            f"{CORTEX_BASE_URL}/query",
            json=payload,
            headers=headers,
            timeout=120  # LightRAG может долго генерировать
        )
        
        if response.status_code == 200:
            result = response.json()
            answer = result.get("response", "")
            
            if answer and len(answer) > 50:
                print_success(f"Доступ разрешен с валидным ключом (200 OK)")
                print_info(f"Response length: {len(answer)} chars")
                print_info(f"Preview: {answer[:100]}...")
            else:
                print_failure(f"Ответ пустой или слишком короткий: {len(answer)} chars")
        else:
            print_failure(
                f"Неожиданный статус с валидным ключом: {response.status_code}"
            )
    
    except requests.exceptions.Timeout:
        print_failure("Timeout - CORTEX слишком долго генерирует ответ (>120s)")
    except Exception as e:
        print_failure(f"Ошибка теста: {str(e)}")


def test_5_status_endpoint_protected():
    """
    Тест 5: /status должен быть защищен API ключом
    
    Ожидание: 401 без ключа, 200 с ключом
    """
    print_test_header("5. Status Endpoint - Protected Access")
    
    try:
        # Без ключа
        response_no_key = requests.get(f"{CORTEX_BASE_URL}/status", timeout=5)
        
        if response_no_key.status_code == 401:
            print_success("/status заблокирован без ключа (401)")
        else:
            print_failure(f"/status доступен без ключа! Status: {response_no_key.status_code}")
        
        # С ключом
        headers = {"X-API-KEY": VALID_API_KEY}
        response_with_key = requests.get(
            f"{CORTEX_BASE_URL}/status",
            headers=headers,
            timeout=5
        )
        
        if response_with_key.status_code == 200:
            print_success("/status доступен с валидным ключом (200)")
            print_info(f"Status data: {response_with_key.json()}")
        else:
            print_failure(f"/status недоступен с ключом! Status: {response_with_key.status_code}")
    
    except Exception as e:
        print_failure(f"Ошибка теста: {str(e)}")


def print_summary():
    """Печать итогов тестирования"""
    print(f"\n{Colors.BOLD}{'='*70}{Colors.ENDC}")
    print(f"{Colors.BOLD}SECURITY PERIMETER TEST RESULTS{Colors.ENDC}")
    print(f"{Colors.BOLD}{'='*70}{Colors.ENDC}\n")
    
    total_tests = tests_passed + tests_failed
    
    print(f"Total Tests: {total_tests}")
    print(f"{Colors.OKGREEN}Passed: {tests_passed}{Colors.ENDC}")
    print(f"{Colors.FAIL}Failed: {tests_failed}{Colors.ENDC}")
    
    if tests_failed == 0:
        print(f"\n{Colors.OKGREEN}{Colors.BOLD}✓ ALL TESTS PASSED - CORTEX ISOLATED{Colors.ENDC}")
        print(f"{Colors.OKGREEN}Операция 'SECURE ENCLAVE' успешна!{Colors.ENDC}\n")
        return 0
    else:
        print(f"\n{Colors.FAIL}{Colors.BOLD}✗ SECURITY VULNERABILITIES DETECTED{Colors.ENDC}")
        print(f"{Colors.FAIL}Защита CORTEX НЕ активна или неэффективна!{Colors.ENDC}\n")
        return 1


def main():
    """Запуск всех тестов"""
    print(f"\n{Colors.HEADER}{Colors.BOLD}╔════════════════════════════════════════════════════════════════╗{Colors.ENDC}")
    print(f"{Colors.HEADER}{Colors.BOLD}║         SECURE ENCLAVE - SECURITY PERIMETER TESTS              ║{Colors.ENDC}")
    print(f"{Colors.HEADER}{Colors.BOLD}║         CORTEX (LightRAG) API Key Isolation                    ║{Colors.ENDC}")
    print(f"{Colors.HEADER}{Colors.BOLD}╚════════════════════════════════════════════════════════════════╝{Colors.ENDC}")
    
    print_info(f"Target: {CORTEX_BASE_URL}")
    print_info(f"API Key: {VALID_API_KEY[:10]}... (masked)")
    
    # Выполнение тестов
    test_1_health_check_public()
    test_2_query_without_key()
    test_3_query_with_invalid_key()
    test_4_query_with_valid_key()
    test_5_status_endpoint_protected()
    
    # Итоги
    exit_code = print_summary()
    sys.exit(exit_code)


if __name__ == "__main__":
    main()
