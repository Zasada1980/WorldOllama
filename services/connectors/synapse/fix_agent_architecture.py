"""ИСПРАВЛЕНИЕ: Удаляем Agent, активируем Tool для qwen"""
import sqlite3
import json

db = r'E:\WORLD_OLLAMA\services\open-webui-local\data\webui.db'
conn = sqlite3.connect(db)
c = conn.cursor()

print('🔧 SILENT FIX #5: Правильная активация Tool\n')

# 1. УДАЛЯЕМ неправильный Agent
c.execute("DELETE FROM function WHERE type='agent'")
deleted = c.rowcount
print(f'🗑️ Удалено Agent (type=agent): {deleted} записей')

# 2. АКТИВИРУЕМ Tool для модели qwen
c.execute("SELECT params FROM model WHERE id='qwen'")
result = c.fetchone()

if result:
    params = json.loads(result[0]) if result[0] else {}
    
    # Добавляем Tool в оба массива
    if 'tools' not in params:
        params['tools'] = []
    if 'functions' not in params:
        params['functions'] = []
    
    if 'knowledge_base' not in params['tools']:
        params['tools'].append('knowledge_base')
    if 'knowledge_base' not in params['functions']:
        params['functions'].append('knowledge_base')
    
    # Сохраняем
    c.execute("UPDATE model SET params = ? WHERE id = 'qwen'", (json.dumps(params),))
    print(f'\n✅ Модель qwen обновлена:')
    print(f'   tools: {params["tools"]}')
    print(f'   functions: {params["functions"]}')
else:
    print(f'\n❌ Модель qwen не найдена!')

# 3. ОБНОВЛЯЕМ чат - используем модель qwen
c.execute("SELECT chat FROM chat WHERE id='bd10a3d9-7369-45b3-b5b8-d8d580b212da'")
chat_result = c.fetchone()

if chat_result:
    chat_data = json.loads(chat_result[0])
    chat_data['models'] = ['qwen']  # ВАЖНО: qwen, а не agent!
    
    c.execute("UPDATE chat SET chat = ? WHERE id = 'bd10a3d9-7369-45b3-b5b8-d8d580b212da'", 
              (json.dumps(chat_data),))
    print(f'\n✅ Чат обновлён:')
    print(f'   models: {chat_data["models"]}')
else:
    print(f'\n⚠️ Чат не найден')

conn.commit()
conn.close()

print(f'\n═══════════════════════════════════════════════')
print(f'✅ SILENT FIX #5 ЗАВЕРШЁН!')
print(f'═══════════════════════════════════════════════')
print(f'\n🔄 СЛЕДУЮЩИЕ ШАГИ:')
print(f'  1. Откройте чат: http://localhost:3100/c/bd10a3d9-7369-45b3-b5b8-d8d580b212da')
print(f'  2. Обновите страницу (F5 или Ctrl+R)')
print(f'  3. Отправьте запрос: "Архитектор, доложи структуру WORLD_OLLAMA"')
print(f'  4. Смотрите на индикатор 🛠️ Used Knowledge Base')
