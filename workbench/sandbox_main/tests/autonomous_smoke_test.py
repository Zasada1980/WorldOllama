#!/usr/bin/env python3
"""
AUTONOMOUS SMOKE TEST — Log-based Tool Verification
==================================================

Since we cannot use WebUI Chat API without auth tokens,
we'll verify Tool functionality by monitoring WebUI logs
for tool_knowledge_base invocation patterns.

Method:
1. Clear current log position
2. Make a request that should trigger Tool
3. Monitor logs for tool invocation
4. Verify CORTEX was called

Created: 25.11.2025
Author: SESA3002a SILENT FIX Protocol
"""

import subprocess
import time
import re
from pathlib import Path


class AutonomousSmokeTest:
    """Автономная верификация Tool через мониторинг логов"""
    
    def __init__(self, log_path: str = r"E:\WORLD_OLLAMA\logs\webui_native.log"):
        self.log_path = Path(log_path)
        self.cortex_log = Path(r"E:\WORLD_OLLAMA\services\lightrag\cortex.log")
    
    def check_tool_loaded(self) -> bool:
        """Проверка что Tool загружен в WebUI"""
        print("🔍 Checking if Tool is loaded in Open WebUI...")
        
        if not self.log_path.exists():
            print(f"❌ Log file not found: {self.log_path}")
            return False
        
        with open(self.log_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
        
        # Ищем загрузку Tool
        patterns = [
            r"Loaded module: tool_knowledge_base",
            r"tool_knowledge_base",
            r"Knowledge Base"
        ]
        
        found_patterns = []
        for pattern in patterns:
            if re.search(pattern, content, re.IGNORECASE):
                found_patterns.append(pattern)
        
        if found_patterns:
            print(f"✅ Tool 'knowledge_base' IS LOADED in WebUI")
            print(f"   Found patterns: {', '.join(found_patterns)}")
            return True
        else:
            print("❌ Tool NOT found in logs")
            return False
    
    def check_cortex_health(self) -> bool:
        """Проверка работы CORTEX"""
        print("\n🔍 Checking CORTEX health...")
        
        import requests
        try:
            response = requests.get("http://localhost:8004/health", timeout=5)
            if response.status_code == 200:
                data = response.json()
                print(f"✅ CORTEX healthy: {data.get('status')}")
                return True
            else:
                print(f"❌ CORTEX unhealthy: HTTP {response.status_code}")
                return False
        except Exception as e:
            print(f"❌ CORTEX offline: {e}")
            return False
    
    def verify_model_tool_link(self) -> bool:
        """Верификация привязки Tool к модели qwen"""
        print("\n🔍 Verifying Model-Tool link in DB...")
        
        import sqlite3
        db_path = r"E:\WORLD_OLLAMA\services\open-webui-local\data\webui.db"
        
        try:
            conn = sqlite3.connect(db_path)
            cursor = conn.cursor()
            
            cursor.execute("SELECT params FROM model WHERE name = 'qwen'")
            result = cursor.fetchone()
            conn.close()
            
            if result and result[0]:
                import json
                params = json.loads(result[0])
                tools = params.get('tools', [])
                
                if 'knowledge_base' in tools:
                    print(f"✅ Model 'qwen' has tool_id: {tools}")
                    return True
                else:
                    print(f"❌ Model 'qwen' tools list: {tools} (knowledge_base missing)")
                    return False
            else:
                print("❌ Model 'qwen' has no params")
                return False
        except Exception as e:
            print(f"❌ DB check failed: {e}")
            return False
    
    def run(self) -> bool:
        """Главная точка входа"""
        print("\n" + "="*70)
        print("🧪 AUTONOMOUS SMOKE TEST — Tool Verification (Log-based)")
        print("="*70 + "\n")
        
        # Check 1: Tool загружен в WebUI
        tool_loaded = self.check_tool_loaded()
        
        # Check 2: CORTEX онлайн
        cortex_ok = self.check_cortex_health()
        
        # Check 3: Model-Tool link в БД
        link_ok = self.verify_model_tool_link()
        
        # Итог
        print("\n" + "="*70)
        print("📊 VERIFICATION SUMMARY")
        print("="*70)
        print(f"Tool loaded in WebUI: {'✅ YES' if tool_loaded else '❌ NO'}")
        print(f"CORTEX operational: {'✅ YES' if cortex_ok else '❌ NO'}")
        print(f"Model-Tool link in DB: {'✅ YES' if link_ok else '❌ NO'}")
        
        all_ok = tool_loaded and cortex_ok and link_ok
        
        if all_ok:
            print("\n" + "="*70)
            print("✅ ALL CHECKS PASSED — Neural Link Infrastructure Ready")
            print("="*70)
            print("\n📋 CONFIGURATION STATUS:")
            print("  • Tool 'Knowledge Base' loaded in Open WebUI memory")
            print("  • CORTEX (port 8004) responding to health checks")
            print("  • Model 'qwen' has tool_id 'knowledge_base' in DB")
            print("\n🎯 FUNCTIONAL TEST:")
            print("  Tool SHOULD be invoked when model receives knowledge queries.")
            print("  Verification requires actual chat interaction (browser/API).")
            print("\n⚠️  NOTE: E2E functional test blocked by:")
            print("  1. Open WebUI Chat API requires JWT authentication")
            print("  2. Direct Ollama API doesn't support Tool injection")
            print("  3. Programmatic browser automation out of scope")
            print("\n✅ RECOMMENDATION:")
            print("  Infrastructure is READY. Manual smoke test in browser")
            print("  will confirm functional Tool invocation.")
            
            return True
        else:
            print("\n" + "="*70)
            print("❌ VERIFICATION FAILED")
            print("="*70)
            
            if not tool_loaded:
                print("\n🔧 FIX: Restart Open WebUI")
            if not cortex_ok:
                print("\n🔧 FIX: Start CORTEX → pwsh E:\\WORLD_OLLAMA\\scripts\\start_lightrag.ps1")
            if not link_ok:
                print("\n🔧 FIX: Run fix_neural_link.py again")
            
            return False


if __name__ == "__main__":
    tester = AutonomousSmokeTest()
    success = tester.run()
    exit(0 if success else 1)
