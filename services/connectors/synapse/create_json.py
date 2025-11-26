import json

# Читаем Python код
with open(r'E:\WORLD_OLLAMA\services\connectors\synapse\knowledge_base_tool.py', 'r', encoding='utf-8') as f:
    python_code = f.read()

# Формируем JSON для Open WebUI
tool_data = {
    'id': 'knowledge_base',
    'name': 'Knowledge Base',
    'type': 'tool',
    'content': python_code,
    'meta': {
        'description': 'Доступ к базе знаний WORLD_OLLAMA (331 документ, 1469 entities, GraphRAG)',
        'manifest': {
            'Created': '25.11.2025 (TD-007 NEURAL LINK)',
            'Author': 'SESA3002a + GitHub Copilot',
            'Version': '1.0.0',
            'Tags': ['knowledge', 'cortex', 'lightrag', 'worldollama', 'synapse']
        }
    },
    'valves': None
}

# Сохраняем в JSON
with open(r'E:\WORLD_OLLAMA\services\connectors\synapse\knowledge_base_IMPORT.json', 'w', encoding='utf-8') as f:
    json.dump(tool_data, f, ensure_ascii=False, indent=2)

print('✅ JSON файл создан!')
import os
size = os.path.getsize(r'E:\WORLD_OLLAMA\services\connectors\synapse\knowledge_base_IMPORT.json')
print(f'📏 Размер: {size / 1024:.2f} KB ({size} bytes)')
