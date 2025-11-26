import sqlite3

db_path = r"E:\AGENTS\open-webui-bridge\data\webui.db"

conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# Список таблиц
cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
tables = [row[0] for row in cursor.fetchall()]
print(f"Таблицы в БД: {tables}")

# Проверка пользователей
if 'user' in tables:
    cursor.execute("SELECT COUNT(*) FROM user")
    count = cursor.fetchone()[0]
    print(f"\nПользователей в таблице user: {count}")
    
    if count > 0:
        cursor.execute("SELECT id, name, email FROM user LIMIT 5")
        users = cursor.fetchall()
        print("\nПервые 5 пользователей:")
        for user in users:
            print(f"  - ID: {user[0]}, Name: {user[1]}, Email: {user[2]}")
    else:
        print("\n⚠️ Таблица user пуста!")
else:
    print("\n❌ Таблица 'user' не найдена!")

conn.close()
