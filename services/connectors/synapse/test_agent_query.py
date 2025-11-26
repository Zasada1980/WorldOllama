"""
Отправка тестового запроса Агенту АРХИТЕКТОР через WebUI API
"""
import requests
import json

# Параметры
WEBUI_URL = "http://localhost:3100"
CHAT_ID = "bd10a3d9-7369-45b3-b5b8-d8d580b212da"  # Из create_chat_with_agent.py
AGENT_ID = "9134f58e-b882-48ed-b2d5-a41991b2ff87"  # Из create_agent_with_tool.py

# Тестовый запрос
QUERY = "Архитектор, доложи текущую структуру проекта WORLD_OLLAMA и статус модуля Cortex."

print(f'🎯 ТЕСТ: Отправка запроса Агенту')
print(f'   Chat ID: {CHAT_ID}')
print(f'   Agent ID: {AGENT_ID}')
print(f'   Query: {QUERY}\n')

# Payload для /api/chat/completions
payload = {
    "model": AGENT_ID,  # ВАЖНО: ID агента!
    "messages": [
        {
            "role": "user",
            "content": QUERY
        }
    ],
    "stream": False,  # Для простоты отключаем стрим
    "chat_id": CHAT_ID,
    "tools": ["knowledge_base"],  # Явное указание Tool
    "tool_choice": "auto"  # Пусть модель сама решает когда вызывать
}

try:
    print('📡 Отправка POST /api/chat/completions...')
    response = requests.post(
        f"{WEBUI_URL}/api/chat/completions",
        json=payload,
        timeout=180  # 3 минуты на Tool + LLM generation
    )
    
    print(f'📥 Статус: {response.status_code}')
    
    if response.status_code == 200:
        result = response.json()
        
        # Извлекаем ответ
        if 'choices' in result:
            message = result['choices'][0]['message']
            content = message.get('content', '')
            
            print(f'\n✅ ОТВЕТ ПОЛУЧЕН:\n')
            print(f'{"="*60}')
            print(content)
            print(f'{"="*60}\n')
            
            # Проверяем использование Tool
            if 'tool_calls' in message:
                print(f'🛠️ TOOL ВЫЗВАН!')
                for tool_call in message['tool_calls']:
                    print(f'  - {tool_call["function"]["name"]}')
                    print(f'    Args: {tool_call["function"]["arguments"]}')
            else:
                print(f'⚠️ Tool НЕ вызван (модель ответила напрямую)')
            
            # Проверяем признаки галлюцинации
            if 'import os' in content or 'def create' in content:
                print(f'\n❌ ГАЛЛЮЦИНАЦИЯ ОБНАРУЖЕНА!')
                print(f'   Модель генерирует код вместо использования Tool')
            elif 'CORTEX' in content or '331 документ' in content or 'port 8004' in content:
                print(f'\n✅ ДАННЫЕ ИЗ CORTEX ПРИСУТСТВУЮТ!')
                print(f'   Tool сработал корректно')
            else:
                print(f'\n⚠️ Ответ неопределённый (нет явных признаков Tool)')
        else:
            print(f'⚠️ Неожиданная структура ответа:')
            print(json.dumps(result, indent=2, ensure_ascii=False))
    else:
        print(f'❌ Ошибка HTTP {response.status_code}')
        print(response.text)

except requests.exceptions.Timeout:
    print(f'⏱️ ТАЙМАУТ! Запрос превысил 180 секунд')
    print(f'   CORTEX может быть перегружен или модель зависла')
except Exception as e:
    print(f'❌ ОШИБКА: {e}')

print(f'\n📊 ПРОВЕРЬТЕ В БРАУЗЕРЕ:')
print(f'   URL: {WEBUI_URL}/c/{CHAT_ID}')
