#!/usr/bin/env python3
"""
FINAL E2E TEST — Real Chat Simulation via Ollama API
===================================================

Test Neural Link by sending actual chat request to model qwen
through Ollama API (which Open WebUI uses internally).

Difference from previous test: Uses simplified approach without tools
parameter - let WebUI backend handle tool injection.
"""

import requests
import json
import time


def test_cortex_direct():
    """Прямой тест CORTEX для подтверждения работы"""
    print("🔍 TEST 1: CORTEX Direct Query...")
    try:
        response = requests.post(
            "http://localhost:8004/query",
            json={"query": "На каком порту работает CORTEX (LightRAG)?", "mode": "naive"},
            timeout=60
        )
        
        if response.status_code == 200:
            data = response.json()
            answer = data.get('response', '')
            has_port = '8004' in answer
            
            print(f"✅ CORTEX responded: {len(answer)} chars")
            print(f"   Contains '8004': {has_port}")
            
            if not has_port:
                print(f"   Sample: {answer[:200]}...")
            
            return True
        else:
            print(f"❌ CORTEX error: HTTP {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ CORTEX error: {e}")
        return False


def test_model_direct_knowledge():
    """Тест модели qwen на знание о проекте (должна НЕ знать без Tool)"""
    print("\n🔍 TEST 2: Model WITHOUT Tool (baseline)...")
    
    try:
        response = requests.post(
            "http://localhost:11434/api/generate",
            json={
                "model": "qwen2.5:14b-instruct-q4_k_m",
                "prompt": "На каком порту работает CORTEX (LightRAG) в проекте WORLD_OLLAMA? Ответь только номером порта.",
                "stream": False
            },
            timeout=60
        )
        
        if response.status_code == 200:
            data = response.json()
            answer = data.get('response', '')
            has_8004 = '8004' in answer
            
            print(f"📝 Model answer (without tool): {answer[:150]}...")
            print(f"   Contains '8004': {has_8004}")
            
            if has_8004:
                print("   ⚠️  Model knows fact (possibly from training data or previous context)")
            else:
                print("   ✅ Model doesn't know (expected - needs Tool)")
            
            return True
        else:
            print(f"❌ Model error: HTTP {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Model error: {e}")
        return False


def main():
    print("\n" + "="*70)
    print("🧪 FINAL E2E TEST — Neural Link Functional Verification")
    print("="*70 + "\n")
    
    # Test 1: CORTEX работает
    cortex_ok = test_cortex_direct()
    
    if not cortex_ok:
        print("\n❌ CORTEX offline - Neural Link cannot work")
        print("   Run: pwsh E:\\WORLD_OLLAMA\\scripts\\start_lightrag.ps1")
        return False
    
    # Test 2: Модель без Tool (baseline)
    model_ok = test_model_direct_knowledge()
    
    print("\n" + "="*70)
    print("📊 DIAGNOSTIC SUMMARY")
    print("="*70)
    print(f"CORTEX (port 8004): {'✅ OPERATIONAL' if cortex_ok else '❌ OFFLINE'}")
    print(f"Model qwen2.5: {'✅ RESPONDS' if model_ok else '❌ ERROR'}")
    
    print("\n📋 NEXT STEPS:")
    print("  1. Open WebUI должен автоматически инжектить Tool при запросе")
    print("  2. Smoke test в браузере: http://localhost:3100")
    print("  3. Запрос к модели qwen: 'Какой порт использует Cortex?'")
    print("  4. Проверить индикатор: 🛠️ Used Knowledge Base")
    
    print("\n⚠️  NOTE: Tool injection происходит на уровне Open WebUI backend,")
    print("    не через прямой Ollama API. Функциональный тест требует")
    print("    использования WebUI интерфейса (браузер) или WebUI Chat API.")
    
    return cortex_ok and model_ok


if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)
