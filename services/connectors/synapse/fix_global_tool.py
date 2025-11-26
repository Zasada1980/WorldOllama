"""SILENT FIX #6: Активация Tool глобально"""
import sqlite3

db = r'E:\WORLD_OLLAMA\services\open-webui-local\data\webui.db'
conn = sqlite3.connect(db)
c = conn.cursor()

print('🔧 SILENT FIX #6: Глобальная активация Tool\n')

# АКТИВИРУЕМ Tool ГЛОБАЛЬНО
c.execute("UPDATE function SET is_global = 1 WHERE id = 'knowledge_base'")
updated = c.rowcount
print(f'✅ Tool knowledge_base обновлён: is_global = 1')

# Проверяем финальный статус
c.execute("SELECT id, name, is_global, is_active FROM function WHERE type='tool'")
tool = c.fetchone()
print(f'\n📊 ФИНАЛЬНЫЙ СТАТУС:')
print(f'   ID: {tool[0]}')
print(f'   Name: {tool[1]}')
print(f'   Global: {"✅ ДА" if tool[2] else "❌ НЕТ"}')
print(f'   Active: {"✅ ДА" if tool[3] else "❌ НЕТ"}')

conn.commit()
conn.close()

print(f'\n═══════════════════════════════════════════════')
print(f'⚠️ ТРЕБУЕТСЯ ПЕРЕЗАГРУЗКА WEBUI!')
print(f'═══════════════════════════════════════════════')
print(f'\nНайдите терминал с WebUI и:')
print(f'  1. Ctrl+C (остановка)')
print(f'  2. Стрелка вверх + Enter (повторный запуск)')
print(f'  3. Дождитесь "Application startup complete"')
print(f'  4. Обновите страницу в браузере (F5)')
print(f'  5. Повторите тест')
