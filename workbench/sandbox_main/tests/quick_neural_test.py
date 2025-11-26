#!/usr/bin/env python3
"""Quick E2E test for Neural Link with better query"""
import requests
import json

payload = {
    'model': 'qwen2.5:14b-instruct-q4_k_m',
    'messages': [
        {'role': 'user', 'content': 'На каком порту работает LightRAG сервер (Cortex)? Ответь точно.'}
    ],
    'tools': [{
        'type': 'function',
        'function': {
            'name': 'lookup_knowledge',
            'description': 'Поиск в базе знаний CORTEX',
            'parameters': {
                'type': 'object',
                'properties': {
                    'query': {'type': 'string'},
                    'mode': {'type': 'string', 'enum': ['naive', 'local', 'global', 'hybrid']}
                },
                'required': ['query']
            }
        }
    }],
    'stream': False
}

print('📞 Запрос к Ollama с Tool...')
resp = requests.post('http://localhost:11434/api/chat', json=payload, timeout=120)
data = resp.json()
msg = data.get('message', {})

tool_calls = msg.get('tool_calls', [])
if tool_calls:
    func_name = tool_calls[0]['function']['name']
    func_args = tool_calls[0]['function']['arguments']
    print(f'✅ Tool вызван: {func_name}')
    print(f'📋 Args: {func_args}')
    
    # Вызов CORTEX
    cortex_payload = json.loads(func_args) if isinstance(func_args, str) else func_args
    cortex_resp = requests.post('http://localhost:8004/query', json=cortex_payload, timeout=60)
    cortex_answer = cortex_resp.json()['response']
    print(f'📥 CORTEX ответ: {len(cortex_answer)} chars')
    print(f'🔍 Содержит 8004: {"8004" in cortex_answer}')
    print(f'🔍 Содержит LightRAG: {"LightRAG" in cortex_answer or "lightrag" in cortex_answer.lower()}')
    
    # Финальный ответ модели
    follow_up = {
        'model': 'qwen2.5:14b-instruct-q4_k_m',
        'messages': [
            {'role': 'user', 'content': payload['messages'][0]['content']},
            {'role': 'assistant', 'content': '', 'tool_calls': tool_calls},
            {'role': 'tool', 'content': cortex_answer}
        ],
        'stream': False
    }
    
    final = requests.post('http://localhost:11434/api/chat', json=follow_up, timeout=60)
    final_answer = final.json()['message']['content']
    print(f'\n📊 ФИНАЛЬНЫЙ ОТВЕТ ({len(final_answer)} chars):')
    print('-' * 70)
    print(final_answer[:700])
    print('-' * 70)
    print(f'\n✅ Содержит 8004: {"8004" in final_answer}')
    print(f'✅ Содержит LightRAG: {"LightRAG" in final_answer or "lightrag" in final_answer.lower()}')
    
    if "8004" in final_answer:
        print('\n🎯 SUCCESS: Neural Link работает!')
        exit(0)
    else:
        print('\n⚠️  Tool вызван, но ответ не содержит точной информации')
        exit(1)
else:
    print('❌ Tool НЕ вызван')
    exit(1)
