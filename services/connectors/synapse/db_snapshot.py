"""
Создание полного слепка структуры БД Open WebUI
"""
import sqlite3
import json

db_path = r'E:\WORLD_OLLAMA\services\open-webui-local\data\webui.db'
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# Получаем структуру всех таблиц
cursor.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")
tables = [row[0] for row in cursor.fetchall()]

print('=== СТРУКТУРА БД OPEN WEBUI v0.6.38 ===\n')

for table in tables:
    print(f'📋 ТАБЛИЦА: {table}')
    cursor.execute(f'PRAGMA table_info("{table}")')
    columns = cursor.fetchall()
    for col in columns:
        col_id, name, dtype, notnull, default, pk = col
        pk_mark = ' 🔑 PRIMARY KEY' if pk else ''
        print(f'  - {name}: {dtype}{pk_mark}')
    
    # Показываем количество записей
    cursor.execute(f'SELECT COUNT(*) FROM "{table}"')
    count = cursor.fetchone()[0]
    print(f'  📊 Записей: {count}\n')

# Детальный слепок важных таблиц
print('\n=== ДЕТАЛИ ВАЖНЫХ ТАБЛИЦ ===\n')

# 1. TOOLS/FUNCTIONS
print('🛠️ ТАБЛИЦА function (type=tool):')
cursor.execute("SELECT id, name, type, meta FROM function WHERE type='tool'")
for row in cursor.fetchall():
    fid, name, ftype, meta = row
    meta_obj = json.loads(meta) if meta else {}
    print(f'  ID: {fid}')
    print(f'    Name: {name}')
    print(f'    Description: {meta_obj.get("description", "N/A")}')
    print()

# 2. MODELS
print('🤖 ТАБЛИЦА model:')
cursor.execute('SELECT id, name, base_model_id, params FROM model')
for row in cursor.fetchall():
    mid, name, base_id, params = row
    params_obj = json.loads(params) if params else {}
    print(f'  ID: {mid}')
    print(f'    Name: {name}')
    print(f'    Base: {base_id}')
    print(f'    Tools: {params_obj.get("tools", [])}')
    print(f'    Functions: {params_obj.get("functions", [])}')
    print()

# 3. USERS
print('👤 ТАБЛИЦА user:')
cursor.execute('SELECT id, name, email, role FROM user LIMIT 3')
for row in cursor.fetchall():
    uid, name, email, role = row
    print(f'  ID: {uid}')
    print(f'    Name: {name}')
    print(f'    Email: {email}')
    print(f'    Role: {role}')
    print()

# 4. CHATS
print('💬 ТАБЛИЦА chat (последние 3):')
cursor.execute('SELECT id, user_id, title, created_at FROM chat ORDER BY created_at DESC LIMIT 3')
for row in cursor.fetchall():
    cid, uid, title, created = row
    print(f'  ID: {cid}')
    print(f'    User: {uid}')
    print(f'    Title: {title}')
    print(f'    Created: {created}')
    print()

conn.close()

print('✅ СЛЕПОК ЗАВЕРШЁН')
