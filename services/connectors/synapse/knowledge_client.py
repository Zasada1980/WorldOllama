#!/usr/bin/env python3
"""
SYNAPSE - Knowledge Connector (TD-007)
Клиентский модуль для связи Агента с CORTEX (LightRAG)

Реализует Принцип ТРИЗ №24 "Посредник" — стандартизированный интерфейс
между Интеллектом (Agent) и Памятью (Cortex).

Created: 25.11.2025
Author: SESA3002a + GitHub Copilot
Updated: 26.11.2025 - SECURE ENCLAVE (добавлена API Key аутентификация)
"""

import os
import requests
from typing import Optional, Literal
import logging

# Настройка логирования
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Конфигурация CORTEX
CORTEX_BASE_URL = "http://localhost:8004"
CORTEX_QUERY_ENDPOINT = f"{CORTEX_BASE_URL}/query"
CORTEX_HEALTH_ENDPOINT = f"{CORTEX_BASE_URL}/health"
DEFAULT_TIMEOUT = 120  # LightRAG может генерировать ответ долго (30-90s)

# ============================================================
# SECURITY CONFIGURATION (ОПЕРАЦИЯ "SECURE ENCLAVE")
# ============================================================

# API Key для аутентификации в CORTEX (ТРИЗ Принцип №2 "Вынесение")
# Загружается из переменной окружения или использует значение по умолчанию
CORTEX_API_KEY = os.getenv("CORTEX_API_KEY", "sesa-secure-core-v1")

# Заголовки для аутентификации
AUTH_HEADERS = {
    "X-API-KEY": CORTEX_API_KEY
}

# Логирование режима безопасности
if os.getenv("CORTEX_API_KEY"):
    logger.info("[SYNAPSE] API Key loaded from environment variable")
else:
    logger.warning("[SYNAPSE] Using default API Key - set CORTEX_API_KEY env variable for production")

# Типы режимов поиска
SearchMode = Literal["naive", "local", "global", "hybrid"]


class CortexConnectionError(Exception):
    """Исключение при проблемах с подключением к CORTEX"""
    pass


class CortexQueryError(Exception):
    """Исключение при ошибках выполнения запроса"""
    pass


def check_cortex_health() -> dict:
    """
    Проверка здоровья CORTEX сервера
    
    Returns:
        dict: Статус сервера {"status": "healthy", "working_dir_exists": True, ...}
    
    Raises:
        CortexConnectionError: Если сервер недоступен
    """
    try:
        response = requests.get(CORTEX_HEALTH_ENDPOINT, timeout=5)
        response.raise_for_status()
        health = response.json()
        logger.info(f"CORTEX health check: {health['status']}")
        return health
    except requests.exceptions.ConnectionError:
        raise CortexConnectionError(
            f"CORTEX сервер недоступен на {CORTEX_BASE_URL}. "
            "Запустите сервер: pwsh E:\\WORLD_OLLAMA\\scripts\\start_lightrag.ps1"
        )
    except requests.exceptions.Timeout:
        raise CortexConnectionError(
            f"CORTEX сервер не отвечает (timeout). Проверьте статус сервера."
        )
    except Exception as e:
        raise CortexConnectionError(f"Ошибка проверки здоровья CORTEX: {str(e)}")


def lookup_knowledge(
    query: str,
    mode: SearchMode = "hybrid",
    timeout: Optional[int] = None,
    check_health_first: bool = True
) -> str:
    """
    Основная функция для запроса знаний из CORTEX (LightRAG).
    
    Принцип ТРИЗ №24 "Посредник" — стандартизированный интерфейс
    между Агентом и базой знаний.
    
    Args:
        query (str): Поисковый запрос (детальный и конкретный)
        mode (SearchMode): Режим поиска
            - "naive": Прямой векторный поиск (~10-20s)
            - "local": Entity-based локальный поиск (~20-30s)
            - "global": Глобальный граф-поиск (~30-45s)
            - "hybrid": Комбинированный (рекомендуется, ~30-60s)
        timeout (int, optional): Таймаут запроса в секундах (default: 120)
        check_health_first (bool): Проверять здоровье сервера перед запросом
    
    Returns:
        str: Текстовый ответ от CORTEX (обычно 2000-3000 символов)
    
    Raises:
        CortexConnectionError: Если CORTEX недоступен
        CortexQueryError: Если запрос завершился с ошибкой
        ValueError: Если query пустой
    
    Examples:
        >>> # Простой запрос
        >>> answer = lookup_knowledge("Как разогнать RTX 5060 Ti?")
        >>> print(answer[:200])
        
        >>> # С указанием режима
        >>> answer = lookup_knowledge(
        ...     query="Структура проекта WORLD_OLLAMA",
        ...     mode="local"
        ... )
    """
    # Валидация входных данных
    if not query or not query.strip():
        raise ValueError("Query не может быть пустым")
    
    if timeout is None:
        timeout = DEFAULT_TIMEOUT
    
    # Проверка здоровья сервера (опционально)
    if check_health_first:
        try:
            health = check_cortex_health()
            if health.get("status") != "healthy":
                logger.warning(f"CORTEX в нездоровом состоянии: {health}")
        except CortexConnectionError as e:
            # Пробрасываем ошибку выше
            raise
    
    # Подготовка запроса
    payload = {
        "query": query.strip(),
        "mode": mode
    }
    
    logger.info(f"Отправка запроса в CORTEX: mode={mode}, query_len={len(query)}")
    logger.debug(f"Query preview: {query[:100]}...")
    
    try:
        # Выполнение POST запроса с API ключом (ОПЕРАЦИЯ "SECURE ENCLAVE")
        response = requests.post(
            CORTEX_QUERY_ENDPOINT,
            json=payload,
            headers=AUTH_HEADERS,  # КРИТИЧНО: аутентификация
            timeout=timeout
        )
        
        # Проверка статуса
        response.raise_for_status()
        
        # Парсинг ответа
        result = response.json()
        
        # Извлечение текста ответа
        answer = result.get("response", "")
        
        if not answer or answer == "Информация не найдена в базе знаний.":
            logger.warning(f"CORTEX не нашел информацию по запросу: {query[:50]}...")
            return "Информация не найдена в базе знаний CORTEX."
        
        # Метаданные для логирования
        detected_lang = result.get("detected_language", "unknown")
        tried_modes = result.get("tried_modes", [mode])
        
        logger.info(
            f"Получен ответ от CORTEX: length={len(answer)}, "
            f"lang={detected_lang}, modes={tried_modes}"
        )
        
        return answer
    
    except requests.exceptions.Timeout:
        raise CortexQueryError(
            f"CORTEX не успел обработать запрос за {timeout}s. "
            "LightRAG может долго генерировать ответы (30-90s). "
            "Попробуйте увеличить timeout или использовать режим 'naive'."
        )
    
    except requests.exceptions.ConnectionError:
        raise CortexConnectionError(
            f"Не удалось подключиться к CORTEX на {CORTEX_BASE_URL}. "
            "Убедитесь, что сервер запущен: "
            "pwsh E:\\WORLD_OLLAMA\\scripts\\start_lightrag.ps1"
        )
    
    except requests.exceptions.HTTPError as e:
        status_code = e.response.status_code
        error_detail = e.response.text[:200] if e.response.text else "No details"
        raise CortexQueryError(
            f"CORTEX вернул ошибку HTTP {status_code}: {error_detail}"
        )
    
    except Exception as e:
        raise CortexQueryError(f"Неожиданная ошибка при запросе к CORTEX: {str(e)}")


def batch_lookup(queries: list[str], mode: SearchMode = "hybrid") -> list[str]:
    """
    Пакетный запрос нескольких вопросов к CORTEX.
    
    Args:
        queries (list[str]): Список запросов
        mode (SearchMode): Режим поиска (один для всех)
    
    Returns:
        list[str]: Список ответов (в том же порядке)
    
    Note:
        Запросы выполняются последовательно, НЕ параллельно
        (CORTEX имеет ограничение LLM_MAX_ASYNC=1)
    """
    results = []
    
    for i, query in enumerate(queries, 1):
        logger.info(f"Batch query {i}/{len(queries)}: {query[:50]}...")
        try:
            answer = lookup_knowledge(query, mode=mode, check_health_first=(i == 1))
            results.append(answer)
        except (CortexConnectionError, CortexQueryError) as e:
            logger.error(f"Query {i} failed: {str(e)}")
            results.append(f"ERROR: {str(e)}")
    
    return results


# Алиас для совместимости с различными именованиями
query_cortex = lookup_knowledge
search_knowledge = lookup_knowledge


if __name__ == "__main__":
    # Простой тест при прямом запуске
    print("=== SYNAPSE Knowledge Client - Self Test ===\n")
    
    # Проверка здоровья
    try:
        health = check_cortex_health()
        print(f"✅ CORTEX Health: {health['status']}")
        print(f"   Working dir: {'✅' if health.get('working_dir_exists') else '❌'}")
        print(f"   Library dir: {'✅' if health.get('library_dir_exists') else '❌'}")
    except CortexConnectionError as e:
        print(f"❌ Health check failed: {e}")
        exit(1)
    
    # Тестовый запрос
    print("\n=== Testing lookup_knowledge ===")
    test_query = "What is WORLD_OLLAMA?"
    
    try:
        print(f"Query: {test_query}")
        print(f"Mode: hybrid")
        print("Waiting for response (may take 30-90s)...\n")
        
        answer = lookup_knowledge(test_query, mode="hybrid")
        
        print(f"✅ Response received ({len(answer)} chars):")
        print("-" * 60)
        print(answer[:500])  # Первые 500 символов
        if len(answer) > 500:
            print(f"\n... (total {len(answer)} characters)")
        print("-" * 60)
        
    except (CortexConnectionError, CortexQueryError) as e:
        print(f"❌ Query failed: {e}")
        exit(1)
    
    print("\n✅ SYNAPSE Self-Test PASSED")
