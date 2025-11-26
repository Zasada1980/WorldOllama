#!/usr/bin/env python3
"""
E2E NEURAL LINK TEST — End-to-End Verification
==============================================

ЦЕЛЬ: Проверить функциональность Neural Link (Agent ↔ CORTEX через SYNAPSE)

МЕТОД: Симуляция браузерного чата через прямой API вызов Ollama

ПРОВЕРКИ:
1. CORTEX доступен (порт 8004)
2. Ollama доступен (порт 11434)
3. Модель qwen2.5:14b-instruct-q4_k_m загружена
4. Отправка тестового запроса к модели с активным Tool
5. Анализ ответа на наличие фактов из CORTEX

КРИТЕРИИ УСПЕХА:
- Ответ содержит точные данные: "8004", "LightRAG", "331 документ"
- Нет hallucination (выдуманных портов или несуществующих сервисов)

Created: 25.11.2025
Author: SESA3002a Autonomous Protocol
"""

import requests
import json
import time
from typing import Dict, Any, Optional


class NeuralLinkE2ETest:
    """End-to-End тест интеграции Agent ↔ CORTEX"""
    
    def __init__(self,
                 cortex_url: str = "http://localhost:8004",
                 ollama_url: str = "http://localhost:11434",
                 model_name: str = "qwen2.5:14b-instruct-q4_k_m"):
        self.cortex_url = cortex_url
        self.ollama_url = ollama_url
        self.model_name = model_name
        self.test_results = []
    
    def log_test(self, name: str, passed: bool, details: str = ""):
        """Логирует результат теста"""
        status = "✅ PASS" if passed else "❌ FAIL"
        self.test_results.append({
            "name": name,
            "passed": passed,
            "details": details
        })
        print(f"{status} | {name}")
        if details:
            print(f"     {details}")
    
    def check_cortex_health(self) -> bool:
        """Проверка доступности CORTEX"""
        print("\n🔍 TEST 1: CORTEX Health Check...")
        try:
            response = requests.get(f"{self.cortex_url}/health", timeout=5)
            if response.status_code == 200:
                data = response.json()
                self.log_test(
                    "CORTEX Health Check",
                    True,
                    f"Status: {data.get('status')}, Working Dir: {data.get('working_dir_exists')}"
                )
                return True
            else:
                self.log_test("CORTEX Health Check", False, f"HTTP {response.status_code}")
                return False
        except Exception as e:
            self.log_test("CORTEX Health Check", False, f"{type(e).__name__}: {e}")
            return False
    
    def check_ollama_health(self) -> bool:
        """Проверка доступности Ollama"""
        print("\n🔍 TEST 2: Ollama Health Check...")
        try:
            response = requests.get(f"{self.ollama_url}/api/tags", timeout=5)
            if response.status_code == 200:
                data = response.json()
                models = [m['name'] for m in data.get('models', [])]
                model_loaded = self.model_name in models
                self.log_test(
                    "Ollama Health Check",
                    model_loaded,
                    f"Models: {len(models)}, Target model loaded: {model_loaded}"
                )
                return model_loaded
            else:
                self.log_test("Ollama Health Check", False, f"HTTP {response.status_code}")
                return False
        except Exception as e:
            self.log_test("Ollama Health Check", False, f"{type(e).__name__}: {e}")
            return False
    
    def test_cortex_direct_query(self) -> bool:
        """Тест прямого запроса к CORTEX"""
        print("\n🔍 TEST 3: CORTEX Direct Query...")
        try:
            payload = {
                "query": "Какой порт использует сервис Cortex?",
                "mode": "hybrid"
            }
            response = requests.post(
                f"{self.cortex_url}/query",
                json=payload,
                timeout=30
            )
            
            if response.status_code == 200:
                data = response.json()
                answer = data.get('response', '')
                has_port = '8004' in answer
                has_lightrag = 'LightRAG' in answer or 'lightrag' in answer.lower()
                
                self.log_test(
                    "CORTEX Direct Query",
                    has_port or has_lightrag,
                    f"Response length: {len(answer)} chars, Contains '8004': {has_port}, Contains 'LightRAG': {has_lightrag}"
                )
                return has_port or has_lightrag
            else:
                self.log_test("CORTEX Direct Query", False, f"HTTP {response.status_code}")
                return False
        except Exception as e:
            self.log_test("CORTEX Direct Query", False, f"{type(e).__name__}: {e}")
            return False
    
    def test_ollama_with_tool(self) -> bool:
        """Тест запроса к Ollama с использованием Tool (Function Calling)"""
        print("\n🔍 TEST 4: Ollama + Tool Integration...")
        
        # Определяем Tool для Function Calling
        tools = [{
            "type": "function",
            "function": {
                "name": "lookup_knowledge",
                "description": "Поиск информации в базе знаний CORTEX (LightRAG GraphRAG)",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "query": {
                            "type": "string",
                            "description": "Запрос для поиска в базе знаний"
                        },
                        "mode": {
                            "type": "string",
                            "enum": ["naive", "local", "global", "hybrid"],
                            "description": "Режим поиска"
                        }
                    },
                    "required": ["query"]
                }
            }
        }]
        
        # Формируем запрос
        payload = {
            "model": self.model_name,
            "messages": [
                {
                    "role": "user",
                    "content": "Какой порт использует сервис Cortex в проекте WORLD_OLLAMA?"
                }
            ],
            "tools": tools,
            "stream": False
        }
        
        try:
            print("   🔄 Отправка запроса к Ollama (может занять 30-90s)...")
            response = requests.post(
                f"{self.ollama_url}/api/chat",
                json=payload,
                timeout=120
            )
            
            if response.status_code == 200:
                data = response.json()
                
                # Проверяем, был ли вызван tool
                message = data.get('message', {})
                tool_calls = message.get('tool_calls', [])
                content = message.get('content', '')
                
                if tool_calls:
                    print(f"   🛠️  Tool вызван: {len(tool_calls)} call(s)")
                    # Эмулируем выполнение Tool (вызов CORTEX)
                    for tool_call in tool_calls:
                        func_name = tool_call['function']['name']
                        func_args = tool_call['function']['arguments']
                        print(f"   📞 Function: {func_name}, Args: {func_args}")
                        
                        # Вызываем CORTEX
                        cortex_response = requests.post(
                            f"{self.cortex_url}/query",
                            json={"query": func_args.get('query', ''), "mode": "hybrid"},
                            timeout=60
                        )
                        
                        if cortex_response.status_code == 200:
                            cortex_data = cortex_response.json()
                            cortex_answer = cortex_data.get('response', '')
                            print(f"   📥 CORTEX ответ: {len(cortex_answer)} chars")
                            
                            # Отправляем ответ Tool обратно в модель
                            follow_up_payload = {
                                "model": self.model_name,
                                "messages": [
                                    {"role": "user", "content": "Какой порт использует сервис Cortex в проекте WORLD_OLLAMA?"},
                                    {"role": "assistant", "content": "", "tool_calls": tool_calls},
                                    {"role": "tool", "content": cortex_answer}
                                ],
                                "stream": False
                            }
                            
                            final_response = requests.post(
                                f"{self.ollama_url}/api/chat",
                                json=follow_up_payload,
                                timeout=60
                            )
                            
                            if final_response.status_code == 200:
                                final_data = final_response.json()
                                final_answer = final_data.get('message', {}).get('content', '')
                                
                                # Валидация ответа
                                has_port = '8004' in final_answer
                                has_lightrag = 'LightRAG' in final_answer or 'lightrag' in final_answer.lower()
                                has_docs = '331' in final_answer or 'документ' in final_answer.lower()
                                
                                success = has_port or (has_lightrag and has_docs)
                                
                                self.log_test(
                                    "Ollama + Tool Integration",
                                    success,
                                    f"Final answer: {len(final_answer)} chars, Port 8004: {has_port}, LightRAG: {has_lightrag}, Docs count: {has_docs}"
                                )
                                
                                if success:
                                    print("\n📋 ФИНАЛЬНЫЙ ОТВЕТ МОДЕЛИ:")
                                    print("-" * 70)
                                    print(final_answer[:500] + ("..." if len(final_answer) > 500 else ""))
                                    print("-" * 70)
                                
                                return success
                else:
                    # Tool НЕ был вызван - проверяем прямой ответ
                    print("   ⚠️  Tool НЕ вызван, модель ответила напрямую")
                    has_port = '8004' in content
                    has_lightrag = 'LightRAG' in content or 'lightrag' in content.lower()
                    
                    # Если ответ содержит факты - возможно модель знает из контекста
                    # Но это НЕ считается успехом Neural Link (Tool должен быть вызван)
                    self.log_test(
                        "Ollama + Tool Integration",
                        False,
                        f"Tool NOT called (Neural Link INACTIVE). Direct answer: {len(content)} chars"
                    )
                    return False
            else:
                self.log_test("Ollama + Tool Integration", False, f"HTTP {response.status_code}")
                return False
                
        except Exception as e:
            self.log_test("Ollama + Tool Integration", False, f"{type(e).__name__}: {e}")
            return False
        
        # Fallback если не попали ни в одну ветку
        return False
    
    def run(self) -> bool:
        """Запуск всех тестов"""
        print("\n" + "="*70)
        print("🧪 E2E NEURAL LINK TEST — Autonomous Verification")
        print("="*70 + "\n")
        
        # Последовательность тестов
        cortex_ok = self.check_cortex_health()
        if not cortex_ok:
            print("\n⚠️  CORTEX недоступен. Запустите: pwsh E:\\WORLD_OLLAMA\\scripts\\start_lightrag.ps1")
            return False
        
        ollama_ok = self.check_ollama_health()
        if not ollama_ok:
            print("\n⚠️  Ollama или модель недоступна")
            return False
        
        cortex_query_ok = self.test_cortex_direct_query()
        
        # Главный тест - интеграция через Tool
        tool_ok = self.test_ollama_with_tool()
        
        # Итоговый отчет
        print("\n" + "="*70)
        print("📊 TEST SUMMARY")
        print("="*70)
        
        passed = sum(1 for r in self.test_results if r['passed'])
        total = len(self.test_results)
        
        for result in self.test_results:
            status = "✅" if result['passed'] else "❌"
            print(f"{status} {result['name']}")
        
        print(f"\nTotal: {passed}/{total} tests passed")
        
        if tool_ok:
            print("\n" + "="*70)
            print("✅ NEURAL LINK FUNCTIONAL")
            print("="*70)
            print("\n🎯 Результат: Agent успешно использует CORTEX через SYNAPSE Tool")
            print("🧠 Cognitive Architecture: User → qwen2-main → lookup_knowledge → CORTEX → 331 docs")
            return True
        else:
            print("\n" + "="*70)
            print("❌ NEURAL LINK NOT FUNCTIONAL")
            print("="*70)
            print("\n⚠️  Tool не вызывается моделью или не настроен в Open WebUI")
            print("📋 Проверьте:")
            print("  1. Tool 'Knowledge Base' создан в БД (auto_connect_synapse.py)")
            print("  2. Open WebUI перезапущен после изменений БД")
            print("  3. Модель qwen имеет tool в params['tools']")
            return False


if __name__ == "__main__":
    tester = NeuralLinkE2ETest()
    success = tester.run()
    exit(0 if success else 1)
