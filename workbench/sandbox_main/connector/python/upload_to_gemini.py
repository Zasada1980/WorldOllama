#!/usr/bin/env python3
"""
Загрузка экспортированных файлов в Gemini Files API.

Скрипт загружает текстовые файлы библиотеки знаний в Google Gemini Files API,
чтобы они стали доступны для использования в Gemini Gem чате.

Требования:
- pip install google-generativeai
- API ключ Google AI Studio

Использование:
    python upload_to_gemini.py --input-dir ./gemini_export
    
Примечание:
- Максимальный размер файла: 2 GB
- Максимальное количество файлов: 20 активных одновременно
- Срок жизни файлов: 48 часов с момента загрузки
"""

import argparse
import time
from pathlib import Path
from typing import List, Dict, Any
from datetime import datetime, timedelta

try:
    import google.generativeai as genai
    from google.generativeai.types import File
except ImportError:
    print("❌ Ошибка: Требуется установить google-generativeai")
    print("   Выполните: pip install google-generativeai")
    exit(1)


class GeminiUploader:
    """Загрузчик файлов в Gemini Files API."""
    
    # API ключ (WARNING: В продакшене использовать переменные окружения!)
    API_KEY = "AIzaSyCl02y_TELywzn9yvmftDruW-kxKgh6s0o"
    
    # Лимиты Gemini Files API
    MAX_FILE_SIZE_GB = 2.0
    MAX_ACTIVE_FILES = 20
    FILE_LIFETIME_HOURS = 48
    
    def __init__(self, input_dir: Path):
        self.input_dir = Path(input_dir)
        
        # Настройка API
        genai.configure(api_key=self.API_KEY)
        
        print(f"🔑 Gemini API настроен")
        print(f"📂 Входная папка: {self.input_dir}")
    
    def validate_input_dir(self) -> bool:
        """Проверка наличия входной папки и файлов."""
        if not self.input_dir.exists():
            print(f"❌ Папка не существует: {self.input_dir}")
            return False
        
        txt_files = list(self.input_dir.glob("*.txt"))
        if not txt_files:
            print(f"❌ В папке {self.input_dir} нет .txt файлов")
            return False
        
        print(f"✅ Найдено файлов для загрузки: {len(txt_files)}")
        return True
    
    def check_file_size(self, file_path: Path) -> bool:
        """Проверка размера файла на соответствие лимитам."""
        size_gb = file_path.stat().st_size / (1024 ** 3)
        
        if size_gb > self.MAX_FILE_SIZE_GB:
            print(f"⚠️ Файл {file_path.name} превышает лимит {self.MAX_FILE_SIZE_GB} GB")
            print(f"   Размер: {size_gb:.2f} GB")
            return False
        
        return True
    
    def list_active_files(self) -> List[File]:
        """Получение списка активных файлов в Gemini."""
        try:
            files = list(genai.list_files())
            print(f"\n📋 Активных файлов в Gemini: {len(files)}/{self.MAX_ACTIVE_FILES}")
            
            if files:
                print("\nСписок файлов:")
                for f in files:
                    # Вычисление времени до истечения срока
                    # FIXME: Gemini SDK может не предоставлять expiration_time
                    # В таком случае показываем только имя и URI
                    print(f"  • {f.name}")
                    print(f"    URI: {f.uri}")
                    if hasattr(f, 'state'):
                        print(f"    Статус: {f.state.name}")
            
            return files
        except Exception as e:
            print(f"⚠️ Ошибка получения списка файлов: {e}")
            return []
    
    def delete_file(self, file_uri: str) -> bool:
        """Удаление файла из Gemini."""
        try:
            genai.delete_file(file_uri)
            print(f"🗑️ Удален файл: {file_uri}")
            return True
        except Exception as e:
            print(f"⚠️ Ошибка удаления файла {file_uri}: {e}")
            return False
    
    def upload_file(self, file_path: Path, display_name: str = None) -> Dict[str, Any]:
        """
        Загрузка файла в Gemini Files API.
        
        Args:
            file_path: Путь к файлу для загрузки
            display_name: Отображаемое имя (опционально)
        
        Returns:
            Словарь с информацией о загруженном файле
        """
        if not self.check_file_size(file_path):
            return {"status": "error", "message": "Файл слишком большой"}
        
        file_size_mb = file_path.stat().st_size / (1024 ** 2)
        display_name = display_name or file_path.name
        
        print(f"\n📤 Загрузка файла: {file_path.name}")
        print(f"   Размер: {file_size_mb:.2f} MB")
        print(f"   Имя: {display_name}")
        
        try:
            # Загрузка файла
            uploaded_file = genai.upload_file(
                path=str(file_path),
                display_name=display_name
            )
            
            print(f"✅ Файл загружен успешно!")
            print(f"   URI: {uploaded_file.uri}")
            print(f"   Название: {uploaded_file.display_name}")
            
            # Ожидание обработки файла
            print("⏳ Ожидание обработки файла...")
            while uploaded_file.state.name == "PROCESSING":
                time.sleep(2)
                uploaded_file = genai.get_file(uploaded_file.name)
            
            if uploaded_file.state.name == "ACTIVE":
                print(f"✅ Файл активен и готов к использованию")
                
                # Вычисление времени истечения срока
                expiration_time = datetime.now() + timedelta(hours=self.FILE_LIFETIME_HOURS)
                print(f"⏰ Срок действия до: {expiration_time.strftime('%Y-%m-%d %H:%M:%S')}")
                
                return {
                    "status": "success",
                    "uri": uploaded_file.uri,
                    "name": uploaded_file.name,
                    "display_name": uploaded_file.display_name,
                    "expiration": expiration_time.isoformat()
                }
            else:
                print(f"⚠️ Неожиданный статус файла: {uploaded_file.state.name}")
                return {
                    "status": "error",
                    "message": f"Неожиданный статус: {uploaded_file.state.name}"
                }
        
        except Exception as e:
            print(f"❌ Ошибка загрузки: {e}")
            return {"status": "error", "message": str(e)}
    
    def upload_all(self, auto_cleanup: bool = False) -> Dict[str, List[Dict]]:
        """
        Загрузка всех .txt файлов из входной папки.
        
        Args:
            auto_cleanup: Автоматически удалять старые файлы при превышении лимита
        
        Returns:
            Словарь с результатами загрузки
        """
        print("\n🚀 Начало загрузки файлов в Gemini Files API")
        
        # Проверка входной папки
        if not self.validate_input_dir():
            return {"success": [], "failed": []}
        
        # Проверка лимита активных файлов
        active_files = self.list_active_files()
        txt_files = list(self.input_dir.glob("*.txt"))
        
        if len(active_files) + len(txt_files) > self.MAX_ACTIVE_FILES:
            print(f"\n⚠️ ВНИМАНИЕ: Превышен лимит активных файлов!")
            print(f"   Активных: {len(active_files)}")
            print(f"   К загрузке: {len(txt_files)}")
            print(f"   Лимит: {self.MAX_ACTIVE_FILES}")
            
            if auto_cleanup and active_files:
                print("\n🗑️ Автоматическая очистка старых файлов...")
                # Удаление первых N файлов, чтобы освободить место
                files_to_delete = len(active_files) + len(txt_files) - self.MAX_ACTIVE_FILES
                for f in active_files[:files_to_delete]:
                    self.delete_file(f.name)
            else:
                print("\n💡 Рекомендации:")
                print("   1. Удалите старые файлы вручную через Google AI Studio")
                print("   2. Используйте флаг --auto-cleanup для автоматической очистки")
                print("   3. Уменьшите количество файлов для загрузки")
        
        # Загрузка файлов
        results = {"success": [], "failed": []}
        
        for file_path in txt_files:
            result = self.upload_file(
                file_path=file_path,
                display_name=f"Knowledge Library - {file_path.stem}"
            )
            
            if result.get("status") == "success":
                results["success"].append({
                    "file": file_path.name,
                    "uri": result["uri"],
                    "expiration": result["expiration"]
                })
            else:
                results["failed"].append({
                    "file": file_path.name,
                    "error": result.get("message", "Unknown error")
                })
        
        # Итоговый отчет
        print("\n" + "=" * 80)
        print("📊 РЕЗУЛЬТАТЫ ЗАГРУЗКИ")
        print("=" * 80)
        print(f"✅ Успешно загружено: {len(results['success'])}")
        print(f"❌ Ошибок: {len(results['failed'])}")
        
        if results["success"]:
            print("\n✅ Загруженные файлы:")
            for item in results["success"]:
                print(f"\n  📄 {item['file']}")
                print(f"     URI: {item['uri']}")
                print(f"     Действителен до: {item['expiration']}")
        
        if results["failed"]:
            print("\n❌ Ошибки загрузки:")
            for item in results["failed"]:
                print(f"  • {item['file']}: {item['error']}")
        
        # Инструкции по использованию
        if results["success"]:
            print("\n" + "=" * 80)
            print("📋 СЛЕДУЮЩИЕ ШАГИ")
            print("=" * 80)
            print("\n1. Откройте Gemini Gem: https://gemini.google.com/gems/edit/f5848adf456f")
            print("\n2. В окне чата используйте команду прикрепления файлов:")
            print("   (Кнопка 📎 или Ctrl+Shift+F)")
            print("\n3. Выберите загруженные файлы из списка 'Files API'")
            print("\n4. Файлы будут доступны для запросов в чате")
            print("\n5. Пример запроса:")
            print("   'На основе загруженной библиотеки знаний, расскажи о принципах ТРИЗ'")
            print("\n⚠️ ВАЖНО: Файлы автоматически удалятся через 48 часов!")
            print("   Рекомендуется настроить автоматическую синхронизацию (см. sync_library_to_gemini.ps1)")
        
        return results


def main():
    parser = argparse.ArgumentParser(
        description="Загрузка файлов в Gemini Files API"
    )
    parser.add_argument(
        "--input-dir",
        type=str,
        default="./gemini_export",
        help="Папка с экспортированными файлами (по умолчанию: ./gemini_export)"
    )
    parser.add_argument(
        "--auto-cleanup",
        action="store_true",
        help="Автоматически удалять старые файлы при превышении лимита"
    )
    parser.add_argument(
        "--list-only",
        action="store_true",
        help="Только показать список активных файлов (без загрузки)"
    )
    
    args = parser.parse_args()
    
    uploader = GeminiUploader(input_dir=Path(args.input_dir))
    
    if args.list_only:
        uploader.list_active_files()
    else:
        uploader.upload_all(auto_cleanup=args.auto_cleanup)


if __name__ == "__main__":
    main()
