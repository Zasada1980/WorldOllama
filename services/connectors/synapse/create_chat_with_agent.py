"""
Создание ЧАТА с Агентом АРХИТЕКТОР через БД
"""
import sqlite3
import json
import time
import datetime

db_path = r'E:\WORLD_OLLAMA\services\open-webui-local\data\webui.db'
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# 1. Получаем ID администратора и агента
cursor.execute("SELECT id FROM user WHERE role = 'admin' LIMIT 1")
admin_id = cursor.fetchone()[0]

cursor.execute("SELECT id FROM function WHERE type='agent' LIMIT 1")
agent_result = cursor.fetchone()
if not agent_result:
    print('❌ Агент не найден! Запустите create_agent_with_tool.py')
    exit(1)

agent_id = agent_result[0]

print(f'👤 User ID: {admin_id}')
print(f'🤖 Agent ID: {agent_id}')

# 2. Создаём ID чата
import uuid
chat_id = str(uuid.uuid4())
now = datetime.datetime.now()

print(f'💬 Создаём чат ID: {chat_id}')

# 3. Структура chat (JSON)
chat_data = {
    "models": [agent_id],  # ВАЖНО: Используем ID агента как модель!
    "messages": [],  # Пока пусто
    "history": {
        "messages": {},
        "currentId": None
    },
    "tags": [],
    "timestamp": int(time.time())
}

# 4. Meta для чата
chat_meta = {
    "agent_id": agent_id,
    "agent_name": "Архитектор WORLD_OLLAMA",
    "tools_enabled": True,
    "knowledge_base_active": True
}

# 5. INSERT чата
cursor.execute("""
INSERT INTO chat (
    id, user_id, title, share_id, archived, created_at, updated_at, chat, pinned, meta, folder_id
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
""", (
    chat_id,
    admin_id,
    "Тест АРХИТЕКТОР + Knowledge Base",  # title
    None,  # share_id
    0,  # archived
    now,  # created_at
    now,  # updated_at
    json.dumps(chat_data),  # chat JSON
    0,  # pinned
    json.dumps(chat_meta),  # meta JSON
    None  # folder_id
))

conn.commit()

print(f'✅ Чат создан!')
print(f'   Chat ID: {chat_id}')
print(f'   Title: Тест АРХИТЕКТОР + Knowledge Base')
print(f'   Agent: {agent_id}')

# 6. Проверяем
cursor.execute("SELECT id, title FROM chat WHERE user_id = ? ORDER BY created_at DESC LIMIT 3", (admin_id,))
chats = cursor.fetchall()
print(f'\n📊 Последние чаты:')
for cid, title in chats:
    marker = '🔥 НОВЫЙ' if cid == chat_id else ''
    print(f'  - {title} {marker}')

conn.close()

print('\n🎯 СЛЕДУЮЩИЙ ШАГ: Отправить запрос в этот чат через API')
print(f'   Chat ID: {chat_id}')
print(f'   URL: http://localhost:3100/c/{chat_id}')
