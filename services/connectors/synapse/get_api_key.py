"""
Извлечение API ключа администратора из WebUI БД
"""
import sqlite3

db_path = r'E:\WORLD_OLLAMA\services\open-webui-local\data\webui.db'
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# Проверяем структуру user
cursor.execute('PRAGMA table_info(user)')
columns = [col[1] for col in cursor.fetchall()]
print(f'📋 Колонки user: {columns}\n')

# Получаем данные администратора
cursor.execute('SELECT id, name, email, role FROM user WHERE role="admin" LIMIT 1')
user = cursor.fetchone()
print(f'👤 Admin:')
print(f'   ID: {user[0]}')
print(f'   Name: {user[1]}')
print(f'   Email: {user[2]}')
print(f'   Role: {user[3]}')

# Если есть api_key колонка
if 'api_key' in columns:
    cursor.execute('SELECT api_key FROM user WHERE role="admin" LIMIT 1')
    api_key = cursor.fetchone()[0]
    if api_key:
        print(f'\n🔑 API KEY: {api_key}')
    else:
        print(f'\n⚠️ API KEY не задан')
else:
    print(f'\n⚠️ Колонка api_key отсутствует')

conn.close()

print(f'\n💡 АЛЬТЕРНАТИВА: Используйте session cookie из браузера')
print(f'   F12 → Application → Cookies → http://localhost:3100 → token')
