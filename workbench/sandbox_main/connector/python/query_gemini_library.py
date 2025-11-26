#!/usr/bin/env python3
"""
Интерактивный чат с библиотекой знаний через Gemini API.

Использует загруженные файлы из Files API как контекст для ответов.

Использование:
    python query_gemini_library.py "Расскажи о принципах ТРИЗ"
    python query_gemini_library.py --interactive  # Интерактивный режим
"""

import argparse
import sys
from pathlib import Path

try:
    import google.generativeai as genai
except ImportError:
    print("❌ Ошибка: Требуется установить google-generativeai")
    print("   Выполните: pip install google-generativeai")
    sys.exit(1)


class GeminiLibraryChat:
    """Чат с библиотекой знаний через Gemini API."""
    
    API_KEY = "AIzaSyCl02y_TELywzn9yvmftDruW-kxKgh6s0o"
    MODEL_NAME = "gemini-2.0-flash-exp"  # Или gemini-pro
    
    def __init__(self):
        genai.configure(api_key=self.API_KEY)
        self.model = genai.GenerativeModel(self.MODEL_NAME)
        self.files = []
        
    def list_files(self):
        """Получение списка доступных файлов из Files API."""
        try:
            files = list(genai.list_files())
            
            # Фильтр только файлов библиотеки
            library_files = [
                f for f in files 
                if f.display_name and "Knowledge Library" in f.display_name
            ]
            
            return library_files
        except Exception as e:
            print(f"⚠️ Ошибка получения списка файлов: {e}")
            return []
    
    def attach_library_files(self):
        """Прикрепление файлов библиотеки к контексту."""
        print("🔍 Поиск файлов библиотеки в Files API...")
        
        files = self.list_files()
        
        if not files:
            print("\n⚠️ Файлы библиотеки не найдены в Files API!")
            print("   Запустите: python upload_to_gemini.py")
            return False
        
        print(f"\n✅ Найдено файлов: {len(files)}")
        for f in files:
            print(f"   • {f.display_name} ({f.state.name})")
            self.files.append(f)
        
        return True
    
    def query(self, question: str, show_sources: bool = True) -> str:
        """
        Отправка запроса к Gemini с контекстом библиотеки.
        
        Args:
            question: Вопрос пользователя
            show_sources: Показывать ли ссылки на источники
        
        Returns:
            Ответ модели
        """
        if not self.files:
            return "❌ Нет прикрепленных файлов библиотеки. Выполните attach_library_files() сначала."
        
        # Формирование промпта с инструкциями
        system_prompt = """Ты — эксперт по ТРИЗ (Теория Решения Изобретательских Задач) и технический консультант.

Используй предоставленные файлы библиотеки знаний для ответа на вопросы.

ОБЯЗАТЕЛЬНО:
1. Отвечай на русском языке
2. Цитируй конкретные разделы из документов
3. Указывай источники (ID документа или раздел)
4. Если информации нет в библиотеке — честно скажи об этом

Вопрос пользователя:
"""
        
        full_prompt = system_prompt + question
        
        # Генерация с файлами в контексте
        try:
            print("\n🤔 Обработка запроса...")
            
            # Создаем контент с файлами
            content = [full_prompt] + self.files
            
            response = self.model.generate_content(content)
            
            return response.text
            
        except Exception as e:
            return f"❌ Ошибка генерации ответа: {e}"
    
    def interactive_mode(self):
        """Интерактивный режим чата."""
        print("\n" + "="*70)
        print("🤖 ИНТЕРАКТИВНЫЙ ЧАТ С БИБЛИОТЕКОЙ ЗНАНИЙ")
        print("="*70)
        print("\nКоманды:")
        print("  • Введите вопрос и нажмите Enter")
        print("  • 'exit' или 'quit' — выход")
        print("  • 'files' — показать прикрепленные файлы")
        print("="*70 + "\n")
        
        while True:
            try:
                question = input("\n💬 Ваш вопрос: ").strip()
                
                if not question:
                    continue
                
                if question.lower() in ['exit', 'quit', 'q']:
                    print("\n👋 До свидания!")
                    break
                
                if question.lower() == 'files':
                    print(f"\n📁 Прикрепленные файлы ({len(self.files)}):")
                    for f in self.files:
                        print(f"   • {f.display_name}")
                    continue
                
                # Запрос к Gemini
                answer = self.query(question)
                
                print("\n" + "─"*70)
                print("🤖 Ответ:")
                print("─"*70)
                print(answer)
                print("─"*70)
                
            except KeyboardInterrupt:
                print("\n\n👋 До свидания!")
                break
            except EOFError:
                print("\n\n👋 До свидания!")
                break


def main():
    parser = argparse.ArgumentParser(
        description="Интерактивный чат с библиотекой знаний через Gemini API"
    )
    parser.add_argument(
        "question",
        nargs="?",
        help="Вопрос к библиотеке (опционально, для одиночного запроса)"
    )
    parser.add_argument(
        "-i", "--interactive",
        action="store_true",
        help="Запустить в интерактивном режиме"
    )
    parser.add_argument(
        "--list-files",
        action="store_true",
        help="Показать список файлов в Files API и выйти"
    )
    
    args = parser.parse_args()
    
    chat = GeminiLibraryChat()
    
    # Режим просмотра файлов
    if args.list_files:
        files = chat.list_files()
        
        if not files:
            print("❌ Файлы не найдены в Files API")
            sys.exit(1)
        
        print(f"\n📁 Файлы в Gemini Files API ({len(files)}):\n")
        for f in files:
            print(f"📄 {f.display_name}")
            print(f"   URI: {f.uri}")
            print(f"   Статус: {f.state.name}")
            print()
        
        sys.exit(0)
    
    # Прикрепление файлов библиотеки
    if not chat.attach_library_files():
        sys.exit(1)
    
    # Интерактивный режим
    if args.interactive or not args.question:
        chat.interactive_mode()
    else:
        # Одиночный запрос
        print(f"\n💬 Вопрос: {args.question}\n")
        answer = chat.query(args.question)
        
        print("─"*70)
        print("🤖 Ответ:")
        print("─"*70)
        print(answer)
        print("─"*70)


if __name__ == "__main__":
    main()
