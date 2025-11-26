#!/usr/bin/env python3
"""
SILENT FIX #3: Migrate Tool from 'tool' table to 'function' table
Root Cause: Open WebUI v0.6.38 renamed 'tool' → 'function'
"""

import sqlite3
import json
from pathlib import Path

DB_PATH = Path(r"E:\WORLD_OLLAMA\services\open-webui-local\data\webui.db")

def migrate_tool_to_function():
    print("\n🔄 МИГРАЦИЯ: tool.knowledge_base → function.knowledge_base\n")
    
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # 1. Читаем Tool из старой таблицы
    print("1️⃣ Чтение Tool record из таблицы 'tool'...")
    cursor.execute("""
        SELECT id, user_id, name, content, specs, meta, valves, updated_at, created_at
        FROM tool 
        WHERE id = 'knowledge_base'
    """)
    tool_data = cursor.fetchone()
    
    if not tool_data:
        print("   ❌ Tool 'knowledge_base' не найден в таблице 'tool'")
        return False
    
    tool_id, user_id, name, content, specs, meta, valves, updated_at, created_at = tool_data
    print(f"   ✅ Найден: {name} (user_id: {user_id[:8]}..., content: {len(content)} chars)")
    
    # 2. Проверяем схему таблицы function
    print("\n2️⃣ Проверка схемы таблицы 'function'...")
    cursor.execute("PRAGMA table_info(function);")
    function_columns = {row[1] for row in cursor.fetchall()}
    print(f"   Колонки: {', '.join(sorted(function_columns))}")
    
    # 3. Вставляем в таблицу function
    print("\n3️⃣ Вставка в таблицу 'function'...")
    
    # Проверяем, есть ли уже такая запись
    cursor.execute("SELECT id FROM function WHERE id = ?", (tool_id,))
    if cursor.fetchone():
        print(f"   ⚠️ Function '{tool_id}' уже существует, обновляем...")
        cursor.execute("""
            UPDATE function 
            SET user_id = ?, name = ?, content = ?, specs = ?, 
                meta = ?, valves = ?, updated_at = ?
            WHERE id = ?
        """, (user_id, name, content, specs, meta, valves, updated_at, tool_id))
    else:
        print(f"   📝 Создаем новую function '{tool_id}'...")
        
        # Open WebUI function table может иметь дополнительные поля
        # Базовые поля: id, user_id, name, content, specs, meta, valves, type, is_active, is_global
        insert_data = {
            'id': tool_id,
            'user_id': user_id,
            'name': name,
            'content': content,
            'specs': specs,
            'meta': meta,
            'valves': valves,
            'updated_at': updated_at,
            'created_at': created_at,
            'type': 'tool',  # Указываем тип (function может быть tool/filter/pipe)
            'is_active': 1,  # Активный
            'is_global': 0   # НЕ глобальный (привязан к user)
        }
        
        # Фильтруем только существующие колонки
        filtered_data = {k: v for k, v in insert_data.items() if k in function_columns}
        
        columns = ', '.join(filtered_data.keys())
        placeholders = ', '.join(['?' for _ in filtered_data])
        
        cursor.execute(
            f"INSERT INTO function ({columns}) VALUES ({placeholders})",
            tuple(filtered_data.values())
        )
    
    conn.commit()
    print("   ✅ Commit в БД")
    
    # 4. Верификация
    print("\n4️⃣ Верификация:")
    cursor.execute("SELECT id, name, type, LENGTH(content) FROM function WHERE id = ?", (tool_id,))
    result = cursor.fetchone()
    
    if result:
        func_id, func_name, func_type, content_len = result
        print(f"   ✅ Function существует:")
        print(f"      ID: {func_id}")
        print(f"      Name: {func_name}")
        print(f"      Type: {func_type}")
        print(f"      Content: {content_len} chars")
    else:
        print("   ❌ ОШИБКА: Function не найдена после вставки")
        return False
    
    conn.close()
    
    print("\n✅ МИГРАЦИЯ ЗАВЕРШЕНА")
    return True

def update_model_link():
    """Обновляем params модели для использования function вместо tool"""
    print("\n5️⃣ Обновление params модели 'qwen'...")
    
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    cursor.execute("SELECT params FROM model WHERE name = 'qwen'")
    result = cursor.fetchone()
    
    if not result:
        print("   ⚠️ Модель 'qwen' не найдена")
        return
    
    params = json.loads(result[0])
    
    # В новых версиях WebUI может использовать 'functions' вместо 'tools'
    if 'tools' in params:
        params['functions'] = params['tools']
        print(f"   ℹ️ Скопировано tools → functions: {params['functions']}")
    
    # Обновляем timestamp для сброса кеша
    import time
    timestamp = int(time.time())
    
    cursor.execute("""
        UPDATE model 
        SET params = ?, updated_at = ?
        WHERE name = 'qwen'
    """, (json.dumps(params), timestamp))
    
    conn.commit()
    conn.close()
    
    print(f"   ✅ Model params updated, timestamp: {timestamp}")

if __name__ == "__main__":
    try:
        if migrate_tool_to_function():
            update_model_link()
            
            print("\n" + "="*60)
            print("  🎯 СЛЕДУЮЩИЙ ШАГ: ПЕРЕЗАПУСТИТЬ Open WebUI")
            print("="*60)
            print("\n  PowerShell:")
            print("  Get-Process python* | Where-Object {$_.CommandLine -like '*open-webui*'} | Stop-Process")
            print("  cd E:\\WORLD_OLLAMA; .\\scripts\\start_webui_production.ps1")
            
    except Exception as e:
        print(f"\n❌ ОШИБКА: {e}")
        import traceback
        traceback.print_exc()
