#!/usr/bin/env python3
"""
Экспорт данных из LightRAG кэша для загрузки в Gemini Files API.

Скрипт извлекает документы и сущности из кэша LightRAG и преобразует их
в текстовые файлы, готовые для загрузки через Gemini Files API.

Выходные файлы:
- library_documents.txt - полные тексты всех документов из библиотеки
- library_entities.txt - извлеченные сущности и их связи из графа знаний

Использование:
    python export_for_gemini.py --cache-dir E:/AI_Librarian_Core/lightrag_cache
"""

import json
import argparse
from pathlib import Path
from typing import Dict, List, Any
from datetime import datetime


class LightRAGExporter:
    """Экспортер данных из LightRAG кэша для Gemini Files API."""
    
    def __init__(self, cache_dir: Path, output_dir: Path):
        self.cache_dir = Path(cache_dir)
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        # Пути к файлам кэша
        self.full_docs_path = self.cache_dir / "kv_store_full_docs.json"
        self.entities_path = self.cache_dir / "vdb_entities.json"
        self.relations_path = self.cache_dir / "kv_store_full_relations.json"
        
    def validate_cache(self) -> bool:
        """Проверка наличия необходимых файлов кэша."""
        required_files = [
            self.full_docs_path,
            self.entities_path
        ]
        
        missing = []
        for file_path in required_files:
            if not file_path.exists():
                missing.append(str(file_path))
        
        if missing:
            print(f"❌ Отсутствуют файлы кэша:")
            for path in missing:
                print(f"   - {path}")
            return False
        
        return True
    
    def load_json(self, file_path: Path) -> Dict[str, Any]:
        """Загрузка JSON файла с обработкой ошибок."""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        except json.JSONDecodeError as e:
            print(f"⚠️ Ошибка парсинга JSON в {file_path.name}: {e}")
            return {}
        except Exception as e:
            print(f"⚠️ Ошибка чтения {file_path.name}: {e}")
            return {}
    
    def export_documents(self) -> str:
        """
        Экспорт полных документов из кэша.
        
        Returns:
            Путь к созданному файлу library_documents.txt
        """
        print("\n📄 Экспорт документов...")
        
        docs_data = self.load_json(self.full_docs_path)
        
        if not docs_data or not isinstance(docs_data, dict):
            print("⚠️ Нет документов для экспорта")
            return ""
        
        output_file = self.output_dir / "library_documents.txt"
        doc_count = 0
        total_chars = 0
        
        with open(output_file, 'w', encoding='utf-8') as f:
            # Заголовок файла
            f.write("=" * 80 + "\n")
            f.write("БИБЛИОТЕКА ЗНАНИЙ - ПОЛНЫЕ ДОКУМЕНТЫ\n")
            f.write(f"Экспортировано: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write("=" * 80 + "\n\n")
            
            # Экспорт каждого документа
            for doc_id, doc_data in docs_data.items():
                # Проверка структуры: doc_data может быть строкой или объектом с полем 'content'
                if isinstance(doc_data, str):
                    doc_text = doc_data
                elif isinstance(doc_data, dict) and 'content' in doc_data:
                    doc_text = doc_data['content']
                else:
                    continue
                
                if not doc_text or not isinstance(doc_text, str):
                    continue
                
                doc_count += 1
                total_chars += len(doc_text)
                
                # Разделитель документов
                f.write("\n" + "-" * 80 + "\n")
                f.write(f"ДОКУМЕНТ ID: {doc_id}\n")
                f.write("-" * 80 + "\n\n")
                
                # Текст документа
                f.write(doc_text)
                f.write("\n\n")
        
        file_size_mb = output_file.stat().st_size / (1024 * 1024)
        
        print(f"✅ Экспортировано {doc_count} документов")
        print(f"📊 Общий объем: {total_chars:,} символов")
        print(f"💾 Размер файла: {file_size_mb:.2f} MB")
        print(f"📁 Файл сохранен: {output_file}")
        
        # Предупреждение о лимите Gemini
        if file_size_mb > 2000:
            print(f"⚠️ ВНИМАНИЕ: Размер превышает лимит Gemini Files API (2 GB)")
        
        return str(output_file)
    
    def export_entities(self) -> str:
        """
        Экспорт сущностей и связей из графа знаний.
        
        Returns:
            Путь к созданному файлу library_entities.txt
        """
        print("\n🔗 Экспорт сущностей...")
        
        entities_data = self.load_json(self.entities_path)
        
        if not entities_data:
            print("⚠️ Нет сущностей для экспорта")
            return ""
        
        # Попытка загрузить связи (опционально)
        relations_data = self.load_json(self.relations_path) if self.relations_path.exists() else {}
        
        output_file = self.output_dir / "library_entities.txt"
        entity_count = 0
        
        with open(output_file, 'w', encoding='utf-8') as f:
            # Заголовок файла
            f.write("=" * 80 + "\n")
            f.write("БИБЛИОТЕКА ЗНАНИЙ - ГРАФ СУЩНОСТЕЙ И СВЯЗЕЙ\n")
            f.write(f"Экспортировано: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write("=" * 80 + "\n\n")
            
            # Экспорт сущностей
            if isinstance(entities_data, dict):
                for entity_id, entity_info in entities_data.items():
                    entity_count += 1
                    
                    f.write(f"\n{'=' * 60}\n")
                    f.write(f"СУЩНОСТЬ: {entity_id}\n")
                    f.write(f"{'=' * 60}\n\n")
                    
                    # Если entity_info это строка
                    if isinstance(entity_info, str):
                        f.write(f"Описание: {entity_info}\n")
                    # Если entity_info это словарь
                    elif isinstance(entity_info, dict):
                        for key, value in entity_info.items():
                            f.write(f"{key}: {value}\n")
                    
                    f.write("\n")
            
            # Экспорт связей (если есть)
            if relations_data:
                f.write("\n\n" + "=" * 80 + "\n")
                f.write("СВЯЗИ МЕЖДУ СУЩНОСТЯМИ\n")
                f.write("=" * 80 + "\n\n")
                
                relation_count = 0
                if isinstance(relations_data, dict):
                    for rel_id, rel_info in relations_data.items():
                        relation_count += 1
                        f.write(f"Связь {relation_count}: {rel_id}\n")
                        
                        if isinstance(rel_info, str):
                            f.write(f"  {rel_info}\n")
                        elif isinstance(rel_info, dict):
                            for key, value in rel_info.items():
                                f.write(f"  {key}: {value}\n")
                        
                        f.write("\n")
                
                print(f"✅ Экспортировано {relation_count} связей")
        
        file_size_mb = output_file.stat().st_size / (1024 * 1024)
        
        print(f"✅ Экспортировано {entity_count} сущностей")
        print(f"💾 Размер файла: {file_size_mb:.2f} MB")
        print(f"📁 Файл сохранен: {output_file}")
        
        return str(output_file)
    
    def run(self) -> Dict[str, str]:
        """
        Выполнение полного экспорта.
        
        Returns:
            Словарь с путями к созданным файлам
        """
        print("🚀 Начало экспорта данных LightRAG для Gemini Files API")
        print(f"📂 Кэш LightRAG: {self.cache_dir}")
        print(f"📁 Выходная папка: {self.output_dir}")
        
        # Проверка кэша
        if not self.validate_cache():
            print("\n❌ Экспорт прерван: отсутствуют необходимые файлы кэша")
            return {}
        
        # Экспорт данных
        results = {
            "documents": self.export_documents(),
            "entities": self.export_entities()
        }
        
        # Итоговый отчет
        print("\n" + "=" * 80)
        print("✅ ЭКСПОРТ ЗАВЕРШЕН")
        print("=" * 80)
        print("\nСозданные файлы:")
        for file_type, file_path in results.items():
            if file_path:
                print(f"  • {file_type}: {file_path}")
        
        print("\n📋 Следующий шаг:")
        print("   python upload_to_gemini.py --input-dir", str(self.output_dir))
        
        return results


def main():
    parser = argparse.ArgumentParser(
        description="Экспорт данных из LightRAG кэша для Gemini Files API"
    )
    parser.add_argument(
        "--cache-dir",
        type=str,
        default="E:/AI_Librarian_Core/lightrag_cache",
        help="Путь к папке с кэшем LightRAG (по умолчанию: E:/AI_Librarian_Core/lightrag_cache)"
    )
    parser.add_argument(
        "--output-dir",
        type=str,
        default="./gemini_export",
        help="Папка для сохранения экспортированных файлов (по умолчанию: ./gemini_export)"
    )
    
    args = parser.parse_args()
    
    exporter = LightRAGExporter(
        cache_dir=Path(args.cache_dir),
        output_dir=Path(args.output_dir)
    )
    
    exporter.run()


if __name__ == "__main__":
    main()
