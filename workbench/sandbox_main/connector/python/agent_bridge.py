"""
SESA3002a Agent Bridge v2.0 (Parametrized)
-------------------------------------------

Интеграционный модуль «Агент — LightRAG» для задач SESA3002a (ТРИЗ
Аэрокосмический Архитектор). Использует локальный сервер библиотеки знаний на
базе LightRAG.

Версия 2.0: Добавлена поддержка CLI аргументов для удаленного тестирования.
"""
import sys
import json
import argparse
from typing import List, Dict, Any, Literal

from library_client import KnowledgeLibrary, QueryMode

LIBRARY_URL = "http://localhost:8003"


class SESAKnowledgeConnector:
    """Прокси между агентом и библиотекой знаний."""

    def __init__(self, url: str = LIBRARY_URL):
        self.lib = KnowledgeLibrary(base_url=url)
        self._check_connection()

    # ------------------------------------------------------------------
    def _check_connection(self) -> None:
        """Первичный health-check + базовая телеметрия."""

        if self.lib.health_check():
            print(f"✅ [SYSTEM] Связь установлена: {self.lib.base_url}")
            status = self.lib.get_status()
            processed = status.get("processed") or status.get("processed_count") or "N/A"
            print(f"📊 [STATUS] Индекс содержит документов: {processed}")
        else:
            print(f"❌ [CRITICAL] Сервер знаний недоступен по адресу {self.lib.base_url}")
            print("   Убедитесь, что LightRAG запущен (см. connector/README.md)")
            sys.exit(1)

    # ------------------------------------------------------------------
    def retrieve_engineering_context(self, problem: str, mode: QueryMode = "hybrid") -> str:
        """
        Гибридный поиск по базе знаний для задачи problem.
        
        Args:
            problem: Описание инженерной задачи
            mode: Режим поиска LightRAG (naive/local/global/hybrid)
        
        Returns:
            Контекст из библиотеки знаний
        """

        print(f"\n🔍 [SEARCH] Запрос: '{problem}'")
        query_payload = f"ТРИЗ принципы и аэрокосмические решения для проблемы: {problem}"

        result = self.lib.query(query=query_payload, mode=mode, timeout=120)
        if "error" in result:
            print(f"⚠️ [WARNING] Ошибка поиска: {result['error']}")
            return ""

        answer = result.get("response", "")
        print(f"💡 [CONTEXT] Получено {len(answer)} символов контекста")
        return answer

    # ------------------------------------------------------------------
    def memorize_solution(self, problem: str, solution: str, principles: List[str]) -> None:
        """Инсерция решения обратно в LightRAG (long-term memory)."""

        print("💾 [MEMORY] Сохранение решения...")

        doc_text = f"""
        # ENGINEERING SOLUTION RECORD
        **Problem:** {problem}
        **Applied TRIZ Principles:** {', '.join(principles)}
        **Solution (IFR):** {solution}
        **Domain:** Aerospace / Engineering
        """

        metadata: Dict[str, Any] = {
            "author": "SESA3002a",
            "type": "solution_report",
            "principles": principles,
        }

        result = self.lib.insert(
            text=doc_text,
            description=f"TRIZ solution for: {problem}",
            metadata=metadata,
            timeout=300,
        )

        if result.get("status") == "success":
            print(f"✅ [SUCCESS] Решение сохранено. Doc ID: {result.get('doc_id')}")
        else:
            print(f"❌ [ERROR] Ошибка сохранения: {result.get('message', result)}")


# ----------------------------------------------------------------------
def main():
    """
    CLI-точка входа для тестирования агента.
    
    Примеры использования:
        python agent_bridge.py --problem "Тестовое соединение агента"
        python agent_bridge.py --problem "Герметизация космического аппарата" --mode hybrid
    """
    parser = argparse.ArgumentParser(
        description="SESA3002a ТРИЗ Agent - Тестирование подключения к библиотеке знаний"
    )
    parser.add_argument(
        "--problem",
        type=str,
        default="Вибрация обшивки самолета при сверхзвуковых скоростях",
        help="Инженерная задача для тестирования поиска"
    )
    parser.add_argument(
        "--mode",
        type=str,
        choices=["naive", "local", "global", "hybrid"],
        default="hybrid",
        help="Режим поиска в LightRAG (по умолчанию: hybrid)"
    )
    parser.add_argument(
        "--url",
        type=str,
        default=LIBRARY_URL,
        help=f"URL библиотеки знаний (по умолчанию: {LIBRARY_URL})"
    )
    
    args = parser.parse_args()
    
    print("=" * 70)
    print("🚀 SESA3002a ТРИЗ AEROSPACE ARCHITECT - AGENT BRIDGE v2.0")
    print("=" * 70)
    print(f"\n📋 Задача: {args.problem}")
    print(f"🔍 Режим поиска: {args.mode}")
    print(f"🌐 URL библиотеки: {args.url}\n")
    
    # Инициализация агента
    try:
        agent = SESAKnowledgeConnector(url=args.url)
    except SystemExit:
        print("\n❌ [FATAL] Не удалось установить соединение с библиотекой знаний")
        print("   Убедитесь, что LightRAG сервер запущен на", args.url)
        return 1
    
    # Извлечение контекста
    print(f"\n🔎 Поиск релевантных знаний для задачи...")
    context = agent.retrieve_engineering_context(args.problem, mode=args.mode)
    
    if context:
        print("\n" + "─" * 70)
        print("✅ [SUCCESS] ИЗВЛЕЧЕННЫЕ ЗНАНИЯ ИЗ БИБЛИОТЕКИ")
        print("─" * 70)
        # Показываем первые 800 символов для телеметрии
        preview = context[:800] if len(context) > 800 else context
        print(preview)
        if len(context) > 800:
            print(f"\n... (всего {len(context)} символов)")
        print("─" * 70)
        
        # Демонстрация сохранения решения
        print("\n💾 Тестирование функции memorize_solution()...")
        generated_solution = (
            f"[ТЕСТОВОЕ РЕШЕНИЕ] Для задачи '{args.problem}' применяются "
            "принципы ТРИЗ: 'Дробление', 'Динамичность', 'Предварительное действие'"
        )
        used_principles = ["1. Дробление", "15. Динамичность", "10. Предварительное действие"]
        
        agent.memorize_solution(args.problem, generated_solution, used_principles)
        
        print("\n" + "=" * 70)
        print("✅ [AGENT STATUS] ONLINE - Готов к работе с инженерными задачами")
        print("=" * 70)
        return 0
    else:
        print("\n" + "─" * 70)
        print("⚠️ [WARNING] База знаний не вернула релевантной информации")
        print("─" * 70)
        print("Агент работает на эвристике (без контекста библиотеки)")
        print("=" * 70)
        return 1


if __name__ == "__main__":
    main()
