"""Диагностика Agent в БД"""
import sqlite3
import json

db = r'E:\WORLD_OLLAMA\services\open-webui-local\data\webui.db'
conn = sqlite3.connect(db)
c = conn.cursor()

print('🔍 ДИАГНОСТИКА АГЕНТА\n')

# 1. Agent
c.execute("SELECT id, name, valves, meta FROM function WHERE type='agent' LIMIT 1")
agent = c.fetchone()
if agent:
    print(f'🤖 AGENT:')
    print(f'  ID: {agent[0]}')
    print(f'  Name: {agent[1]}')
    
    valves = json.loads(agent[2]) if agent[2] else {}
    print(f'  Valves:')
    print(f'    tools: {valves.get("tools", [])}')
    print(f'    model: {valves.get("model", "N/A")}')
    
    meta = json.loads(agent[3]) if agent[3] else {}
    print(f'  Meta:')
    print(f'    knowledge: {meta.get("knowledge", [])}')
else:
    print('❌ Agent не найден!')

# 2. Tool
print(f'\n🛠️ TOOL:')
c.execute("SELECT id, name, is_active, is_global FROM function WHERE type='tool' LIMIT 1")
tool = c.fetchone()
if tool:
    print(f'  ID: {tool[0]}')
    print(f'  Name: {tool[1]}')
    print(f'  Active: {bool(tool[2])}')
    print(f'  Global: {bool(tool[3])}')
else:
    print('❌ Tool не найден!')

# 3. Chat
print(f'\n💬 LAST CHAT:')
c.execute('SELECT id, title, chat FROM chat ORDER BY created_at DESC LIMIT 1')
chat = c.fetchone()
if chat:
    chat_data = json.loads(chat[2])
    print(f'  ID: {chat[0]}')
    print(f'  Title: {chat[1]}')
    print(f'  Models in chat: {chat_data.get("models", [])}')
    print(f'  Message count: {len(chat_data.get("messages", []))}')

conn.close()

print(f'\n🎯 ПРОБЛЕМА:')
print(f'  Agent создан как function.type="agent"')
print(f'  НО Open WebUI ожидает МОДЕЛЬ из Ollama!')
print(f'\n💡 РЕШЕНИЕ:')
print(f'  Agent в WebUI = НЕ отдельная сущность')
print(f'  Agent = MODEL + TOOLS')
print(f'  Нужно активировать Tool для модели qwen')
