import sqlite3

conn = sqlite3.connect(r'E:\WORLD_OLLAMA\services\open-webui-local\data\webui.db')
cursor = conn.cursor()

cursor.execute('SELECT id, name FROM tool')
tools = cursor.fetchall()

cursor.execute('SELECT id, name FROM function WHERE type=?', ('tool',))
functions = cursor.fetchall()

print('=== ТАБЛИЦА tool ===')
for t in tools:
    print(f'  {t[0]}: {t[1]}')

print('\n=== ТАБЛИЦА function (type=tool) ===')
for f in functions:
    print(f'  {f[0]}: {f[1]}')

print(f'\n📊 ИТОГО:')
print(f'  tool: {len(tools)} записей')
print(f'  function: {len(functions)} записей')

if len(tools) > 0 and len(functions) > 0:
    print('\n❌ ОБНАРУЖЕН ДУБЛИКАТ!')
    print('   Инструмент существует в ОБЕИХ таблицах!')
    print('   Это вызывает WARNING в логах WebUI')

conn.close()
