#!/usr/bin/env python3
"""
E2E Browser Test: Neuro-Terminal + CORTEX Integration
=====================================================

Автоматизированный тест браузерного интерфейса Chainlit (Neuro-Terminal)
с проверкой интеграции CORTEX через Knowledge Base tool.

ТРЕБОВАНИЯ:
- pip install playwright pytest-playwright
- playwright install chromium

ПРОВЕРКИ:
1. Neuro-Terminal доступен (localhost:8501)
2. CORTEX отвечает на health check
3. Отправка тестового вопроса через UI
4. Проверка появления Steps (Planner, CORTEX Lookup, Response)
5. Валидация ответа на наличие данных из CORTEX

Created: 25.11.2025
Author: SESA3002a + Codex
"""

import time
from playwright.sync_api import sync_playwright, Page, expect
import requests


class NeuroTerminalE2ETest:
    """E2E Browser Test для Neuro-Terminal"""
    
    def __init__(
        self,
        neuro_url: str = "http://localhost:8501",
        cortex_url: str = "http://localhost:8004",
        headless: bool = False
    ):
        self.neuro_url = neuro_url
        self.cortex_url = cortex_url
        self.headless = headless
        self.test_results = []
    
    def log_test(self, name: str, passed: bool, details: str = ""):
        """Логирование результата теста"""
        status = "✅ PASS" if passed else "❌ FAIL"
        self.test_results.append({
            "name": name,
            "passed": passed,
            "details": details
        })
        print(f"{status} | {name}")
        if details:
            print(f"     {details}")
    
    def check_services(self) -> bool:
        """Проверка доступности сервисов перед запуском браузера"""
        print("\n🔍 PRE-FLIGHT: Services Health Check...")
        
        # Neuro-Terminal
        try:
            resp = requests.get(self.neuro_url, timeout=3)
            neuro_ok = resp.status_code == 200
            self.log_test("Neuro-Terminal accessible", neuro_ok, f"HTTP {resp.status_code}")
        except Exception as e:
            self.log_test("Neuro-Terminal accessible", False, str(e))
            return False
        
        # CORTEX
        try:
            resp = requests.get(f"{self.cortex_url}/health", timeout=3)
            if resp.status_code == 200:
                data = resp.json()
                cortex_ok = data.get("status") == "healthy"
                self.log_test("CORTEX healthy", cortex_ok, f"Status: {data.get('status')}")
            else:
                self.log_test("CORTEX healthy", False, f"HTTP {resp.status_code}")
                return False
        except Exception as e:
            self.log_test("CORTEX healthy", False, str(e))
            return False
        
        return neuro_ok and cortex_ok
    
    def run_browser_test(self):
        """Основной браузерный тест"""
        print("\n🚀 BROWSER TEST: Launching Chromium...")
        
        with sync_playwright() as p:
            browser = p.chromium.launch(headless=self.headless)
            page = browser.new_page()
            
            try:
                # 1. Открытие Neuro-Terminal
                print("\n🔍 TEST 1: Opening Neuro-Terminal UI...")
                page.goto(self.neuro_url, timeout=10000)
                page.wait_for_load_state("networkidle")
                
                # Проверка заголовка
                title = page.title()
                self.log_test(
                    "Page loaded",
                    "chainlit" in title.lower() or len(title) > 0,
                    f"Title: {title}"
                )
                
                # 2. Поиск input поля для ввода
                print("\n🔍 TEST 2: Locating chat input...")
                time.sleep(2)  # Даём UI время инициализироваться
                
                # Chainlit использует textarea для ввода
                input_selector = "textarea[placeholder*='Type']"
                page.wait_for_selector(input_selector, timeout=5000)
                self.log_test("Chat input found", True, f"Selector: {input_selector}")
                
                # 3. Отправка тестового вопроса
                print("\n🔍 TEST 3: Sending test query...")
                test_question = "Что такое CORTEX и сколько документов в нём?"
                
                page.fill(input_selector, test_question)
                time.sleep(0.5)
                
                # Отправка (обычно Enter или кнопка Submit)
                page.keyboard.press("Enter")
                self.log_test("Query sent", True, f"Question: {test_question}")
                
                # 4. Ожидание появления шагов (Steps)
                print("\n🔍 TEST 4: Waiting for Planner step...")
                time.sleep(5)  # Даём Planner время на обработку
                
                # Chainlit создаёт элементы с классом cl-step
                planner_found = self._check_step_exists(page, "Planner", timeout=10)
                self.log_test("Planner step appeared", planner_found)
                
                # 5. Ожидание CORTEX Lookup
                print("\n🔍 TEST 5: Waiting for CORTEX Lookup...")
                cortex_lookup_found = self._check_step_exists(page, "CORTEX Lookup", timeout=60)
                self.log_test("CORTEX Lookup step appeared", cortex_lookup_found)
                
                # 6. Ожидание Knowledge Result
                print("\n🔍 TEST 6: Waiting for Knowledge Result...")
                knowledge_result_found = self._check_step_exists(page, "Knowledge Result", timeout=10)
                self.log_test("Knowledge Result step appeared", knowledge_result_found)
                
                # 7. Проверка финального ответа
                print("\n🔍 TEST 7: Checking final response...")
                time.sleep(5)  # Даём время на генерацию ответа
                
                # Ищем текст ответа (обычно в div с классом message)
                response_text = page.inner_text("body")
                
                # Сохранение полного ответа в файл
                response_file = "e:/WORLD_OLLAMA/workbench/sandbox_main/tests/neuro_terminal_response.txt"
                with open(response_file, "w", encoding="utf-8") as f:
                    f.write(response_text)
                
                # Проверка наличия ключевых слов из CORTEX
                keywords = ["8004", "LightRAG", "документ"]
                keyword_found = any(kw in response_text for kw in keywords)
                self.log_test(
                    "Response contains CORTEX data",
                    keyword_found,
                    f"Keywords found: {[kw for kw in keywords if kw in response_text]}"
                )
                self.log_test("Response saved to file", True, response_file)
                
                # 8. Скриншот для визуальной проверки
                screenshot_path = "e:/WORLD_OLLAMA/workbench/sandbox_main/tests/neuro_terminal_test.png"
                page.screenshot(path=screenshot_path)
                self.log_test("Screenshot saved", True, screenshot_path)
                
            except Exception as e:
                self.log_test("Browser test execution", False, f"{type(e).__name__}: {e}")
                # Скриншот ошибки
                try:
                    page.screenshot(path="e:/WORLD_OLLAMA/workbench/sandbox_main/tests/neuro_terminal_error.png")
                except:
                    pass
            
            finally:
                browser.close()
    
    def _check_step_exists(self, page: Page, step_name: str, timeout: int = 30) -> bool:
        """Проверка наличия шага в UI"""
        try:
            # Chainlit создаёт элементы с текстом шага
            # Ищем по частичному совпадению текста
            selector = f"text={step_name}"
            page.wait_for_selector(selector, timeout=timeout * 1000)
            return True
        except:
            return False
    
    def run_all_tests(self):
        """Запуск всех тестов"""
        print("=" * 70)
        print("🧪 NEURO-TERMINAL E2E BROWSER TEST")
        print("=" * 70)
        
        # Pre-flight checks
        if not self.check_services():
            print("\n❌ Pre-flight failed. Ensure Neuro-Terminal and CORTEX are running.")
            return False
        
        # Browser tests
        self.run_browser_test()
        
        # Summary
        print("\n" + "=" * 70)
        print("📊 TEST SUMMARY")
        print("=" * 70)
        
        total = len(self.test_results)
        passed = sum(1 for r in self.test_results if r["passed"])
        
        for result in self.test_results:
            status = "✅" if result["passed"] else "❌"
            print(f"{status} {result['name']}")
        
        print(f"\n🎯 RESULT: {passed}/{total} tests passed")
        
        if passed == total:
            print("✅ ALL TESTS PASSED")
            return True
        else:
            print(f"❌ {total - passed} tests failed")
            return False


if __name__ == "__main__":
    # Запуск теста в режиме с видимым браузером для отладки
    test = NeuroTerminalE2ETest(headless=False)
    success = test.run_all_tests()
    
    exit(0 if success else 1)
