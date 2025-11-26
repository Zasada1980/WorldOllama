"""
Создание Агента АРХИТЕКТОР с инструментом Knowledge Base через БД
"""
import sqlite3
import json
import time

db_path = r'E:\WORLD_OLLAMA\services\open-webui-local\data\webui.db'
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# 1. Получаем ID администратора
cursor.execute("SELECT id FROM user WHERE role = 'admin' LIMIT 1")
admin_id = cursor.fetchone()[0]
print(f'👤 Admin ID: {admin_id}')

# 2. Создаём ID агента
import uuid
agent_id = str(uuid.uuid4())
timestamp = int(time.time())

print(f'🤖 Создаём агента ID: {agent_id}')

# 3. Агент = запись в таблице function с type='agent'
agent_name = "Архитектор WORLD_OLLAMA"
agent_description = "AI Agent с доступом к базе знаний CORTEX (331 документ, GraphRAG). Отвечает на вопросы о структуре проекта, GPU overclocking, ТРИЗ, SSL, AI agents."

# Определяем content агента (минимальная заглушка для Pydantic)
agent_content = """
class Agent:
    pass
"""

# meta для агента
agent_meta = {
    "name": agent_name,
    "description": agent_description,
    "profile_image_url": "/static/favicon.png",
    "capabilities": {
        "vision": False,
        "usage": True,
        "citations": True
    },
    "knowledge": ["knowledge_base"]  # СВЯЗЬ С TOOL
}

# valves для агента
agent_valves = {
    "tools": ["knowledge_base"],  # АКТИВАЦИЯ TOOL
    "enable_memory": True,
    "enable_web_search": False,
    "model": "qwen2.5:14b-instruct-q4_k_m"
}

# 4. INSERT агента
cursor.execute("""
INSERT INTO function (
    id, user_id, name, type, content, meta, valves, created_at, updated_at, is_active, is_global
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
""", (
    agent_id,
    admin_id,
    agent_name,
    'agent',  # ТИП АГЕНТ!
    agent_content,
    json.dumps(agent_meta),
    json.dumps(agent_valves),
    timestamp,
    timestamp,
    1,  # is_active
    1   # is_global
))

conn.commit()

print(f'✅ Агент создан!')
print(f'   ID: {agent_id}')
print(f'   Name: {agent_name}')
print(f'   Tool: knowledge_base')
print(f'   Model: qwen2.5:14b-instruct-q4_k_m')

# 5. Проверяем создание
cursor.execute("SELECT id, name, type FROM function WHERE type='agent'")
agents = cursor.fetchall()
print(f'\n📊 Всего агентов в БД: {len(agents)}')
for aid, name, atype in agents:
    print(f'  - {name} (ID: {aid})')

conn.close()

print('\n🎯 СЛЕДУЮЩИЙ ШАГ: Создать чат с этим агентом')
print(f'   Agent ID: {agent_id}')
