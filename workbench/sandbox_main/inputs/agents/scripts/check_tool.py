import sqlite3

conn = sqlite3.connect(r"E:\AGENTS\open-webui-bridge\data\webui.db")
cursor = conn.cursor()

cursor.execute("SELECT id, name, LENGTH(content) FROM tool WHERE id='librarian_knowledge_base'")
row = cursor.fetchone()

if row:
    print(f"✅ Tool найден:")
    print(f"   ID: {row[0]}")
    print(f"   Name: {row[1]}")
    print(f"   Content length: {row[2]} bytes")
else:
    print("❌ Tool не найден в БД")

conn.close()
