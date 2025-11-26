import sqlite3
import json

conn = sqlite3.connect(r'E:\WORLD_OLLAMA\services\open-webui-local\data\webui.db')
cursor = conn.cursor()

cursor.execute('SELECT id, params FROM model WHERE id=?', ('qwen',))
row = cursor.fetchone()

if row:
    params = json.loads(row[1])
    print('📋 ПАРАМЕТРЫ МОДЕЛИ qwen:')
    print(json.dumps(params, indent=2, ensure_ascii=False))
    
    # Проверка активации инструмента
    tools = params.get('tools', [])
    functions = params.get('functions', [])
    
    print(f'\n📊 АКТИВИРОВАННЫЕ ИНСТРУМЕНТЫ:')
    print(f'  tools: {tools}')
    print(f'  functions: {functions}')
    
    if 'knowledge_base' in tools or 'knowledge_base' in functions:
        print('\n✅ Knowledge Base АКТИВИРОВАН для модели qwen')
    else:
        print('\n❌ Knowledge Base НЕ АКТИВИРОВАН для модели qwen')
        print('   ТРЕБУЕТСЯ: активировать в Models → qwen → Edit → Tools')

conn.close()
