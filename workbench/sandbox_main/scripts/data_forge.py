#!/usr/bin/env python3
"""
ОПЕРАЦИЯ "DATA FORGE" - Кузница обучающих данных
Цель: Самогенерация датасета для Fine-tuning через Cortex

Created: 26.11.2025
Author: SESA3002a
Protocol: TD-009 (Evolution Phase - Self-Distillation)

ТРИЗ Принцип №25 "Самообслуживание": Агент генерирует собственный датасет
"""

import sys
import json
import time
from pathlib import Path
from typing import List, Dict

# Добавляем путь к SYNAPSE connector
sys.path.insert(0, str(Path(__file__).parent.parent.parent.parent / "services" / "connectors" / "synapse"))

from knowledge_client import lookup_knowledge, check_cortex_health

# ЦВЕТА
GREEN = "\033[92m"
RED = "\033[91m"
YELLOW = "\033[93m"
CYAN = "\033[96m"
MAGENTA = "\033[95m"
BOLD = "\033[1m"
RESET = "\033[0m"

# КОНФИГУРАЦИЯ
OUTPUT_DIR = Path(__file__).parent.parent / "outputs"
OUTPUT_FILE = OUTPUT_DIR / "triz_synthesis_v1.jsonl"
TARGET_SAMPLES = 300  # Целевое количество пар
TRIZ_PRINCIPLES_COUNT = 40  # Всего принципов ТРИЗ

# ШАБЛОНЫ ЗАПРОСОВ (ТРИЗ Принцип №23 "Обратная связь")
QUERY_TEMPLATES = {
    "synthesis": [
        "Примени принципы ТРИЗ №{p1} и №{p2} для оптимизации архитектуры AI агента с ограниченной памятью",
        "Как объединить принципы №{p1} '{name1}' и №{p2} '{name2}' для создания самообучающейся системы?",
        "Используя принципы №{p1} и №{p2}, предложи решение для масштабирования LLM системы",
        "Синтезируй подход к защите AI агента от джейлбрейка, применяя принципы №{p1} и №{p2}",
    ],
    "analysis": [
        "В чем разница между Принципом ТРИЗ №{p1} '{name1}' и Принципом №{p2} '{name2}'?",
        "Сравни применение принципов №{p1} и №{p2} в контексте разработки AI систем",
        "Объясни когнитивные аналогии между принципами №{p1} '{name1}' и №{p2} '{name2}'",
        "Проанализируй, когда использовать принцип №{p1} вместо принципа №{p2} при проектировании агента",
    ],
    "application": [
        "Как применить принцип ТРИЗ №{p1} '{name1}' для оптимизации RAG системы?",
        "Опиши практическое применение принципа №{p1} в архитектуре многоагентной системы",
        "Приведи пример использования принципа №{p1} для решения проблемы hallucinations в LLM",
        "Как принцип №{p1} '{name1}' помогает в разработке защищенного когнитивного анклава?",
    ],
    "deep_dive": [
        "Объясни принцип ТРИЗ №{p1} '{name1}' с примерами из области AI и машинного обучения",
        "Какие когнитивные паттерны лежат в основе принципа №{p1}?",
        "Продемонстрируй применение принципа №{p1} на примере реальной архитектуры AI системы",
        "Как принцип №{p1} '{name1}' связан с современными подходами в AI разработке?",
    ]
}

# Названия принципов ТРИЗ (для шаблонов)
PRINCIPLE_NAMES = {
    1: "Дробление",
    2: "Вынесение",
    9: "Предварительное антидействие",
    10: "Предварительное действие",
    11: "Заблаговременная амортизация",
    16: "Частичное или избыточное действие",
    23: "Обратная связь",
    24: "Посредник",
    25: "Самообслуживание",
    # Добавьте другие по мере необходимости
}


def print_header():
    """Печать заголовка операции"""
    print(f"\n{MAGENTA}╔════════════════════════════════════════════════════════════════╗{RESET}")
    print(f"{MAGENTA}║   🔨 ОПЕРАЦИЯ 'DATA FORGE' - КУЗНИЦА ДАННЫХ                  ║{RESET}")
    print(f"{MAGENTA}╚════════════════════════════════════════════════════════════════╝{RESET}\n")
    
    print(f"{YELLOW}ПРОТОКОЛ:{RESET} TD-009 (Evolution Phase - Self-Distillation)")
    print(f"{YELLOW}ЦЕЛЬ:{RESET} Самогенерация обучающего датасета через Cortex\n")
    print(f"{YELLOW}ТРИЗ Принцип №25:{RESET} Самообслуживание - Агент генерирует свои данные\n")
    print(f"{YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{RESET}\n")


def generate_query(template_type: str, p1: int, p2: int = None) -> str:
    """Генерация запроса из шаблона"""
    import random
    
    templates = QUERY_TEMPLATES[template_type]
    template = random.choice(templates)
    
    # Подстановка параметров
    query = template.format(
        p1=p1,
        p2=p2 if p2 else p1,
        name1=PRINCIPLE_NAMES.get(p1, f"Принцип {p1}"),
        name2=PRINCIPLE_NAMES.get(p2, f"Принцип {p2}") if p2 else ""
    )
    
    return query


def fetch_response(query: str, mode: str = "hybrid") -> str:
    """Получение ответа от Cortex через SYNAPSE"""
    try:
        response = lookup_knowledge(
            query=query,
            mode=mode,
            timeout=180
        )
        return response
    except Exception as e:
        print(f"{RED}  ✗ Ошибка запроса: {e}{RESET}")
        return None


def create_training_sample(instruction: str, response: str) -> Dict:
    """Создание обучающего примера в формате LLaMA-Factory"""
    return {
        "instruction": instruction,
        "input": "",
        "output": response
    }


def save_dataset(samples: List[Dict], output_path: Path):
    """Сохранение датасета в JSONL формате"""
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    with open(output_path, 'w', encoding='utf-8') as f:
        for sample in samples:
            f.write(json.dumps(sample, ensure_ascii=False) + '\n')


def main():
    """Основная функция генерации датасета"""
    print_header()
    
    # Проверка Cortex
    print(f"{CYAN}Проверка связи с CORTEX...{RESET}")
    try:
        health = check_cortex_health()
        print(f"{GREEN}✓ CORTEX онлайн: {health['status']}{RESET}\n")
    except Exception as e:
        print(f"{RED}✗ Ошибка подключения к CORTEX: {e}{RESET}\n")
        print(f"{YELLOW}Запустите систему: E:\\WORLD_OLLAMA\\USER\\START_ALL.ps1{RESET}\n")
        sys.exit(1)
    
    print(f"{YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{RESET}\n")
    print(f"{BOLD}{CYAN}ГЕНЕРАЦИЯ ОБУЧАЮЩИХ ДАННЫХ{RESET}\n")
    print(f"  Целевое количество: {TARGET_SAMPLES} пар")
    print(f"  Охват: {TRIZ_PRINCIPLES_COUNT} принципов ТРИЗ")
    print(f"  Выходной файл: {OUTPUT_FILE}\n")
    print(f"{YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{RESET}\n")
    
    samples = []
    errors = 0
    
    import random
    
    # Генерация пар
    for i in range(TARGET_SAMPLES):
        # Выбор типа шаблона
        template_types = list(QUERY_TEMPLATES.keys())
        template_type = random.choice(template_types)
        
        # Выбор принципов
        p1 = random.randint(1, TRIZ_PRINCIPLES_COUNT)
        p2 = random.randint(1, TRIZ_PRINCIPLES_COUNT) if template_type in ["synthesis", "analysis"] else None
        
        # Генерация запроса
        query = generate_query(template_type, p1, p2)
        
        print(f"{CYAN}[{i+1}/{TARGET_SAMPLES}]{RESET} Генерация пары...")
        print(f"  Тип: {template_type}")
        print(f"  Принципы: №{p1}" + (f", №{p2}" if p2 else ""))
        print(f"  Запрос: {query[:80]}...")
        
        # Получение ответа от Cortex
        response = fetch_response(query, mode="hybrid")
        
        if response and len(response) > 100:  # Минимальная длина ответа
            sample = create_training_sample(query, response)
            samples.append(sample)
            print(f"{GREEN}  ✓ Пара создана ({len(response)} символов){RESET}\n")
        else:
            errors += 1
            print(f"{YELLOW}  ⚠ Ответ слишком короткий или ошибка, пропускаем{RESET}\n")
        
        # Задержка между запросами (не перегружаем Cortex)
        if (i + 1) % 10 == 0:
            print(f"{YELLOW}  ⏱️ Пауза 5 секунд (защита от перегрузки)...{RESET}\n")
            time.sleep(5)
    
    # Сохранение датасета
    print(f"{YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{RESET}\n")
    print(f"{CYAN}Сохранение датасета...{RESET}")
    
    save_dataset(samples, OUTPUT_FILE)
    
    print(f"{GREEN}✓ Датасет сохранен: {OUTPUT_FILE}{RESET}")
    print(f"  Успешно создано: {len(samples)} пар")
    print(f"  Ошибок: {errors}")
    print(f"  Размер файла: {OUTPUT_FILE.stat().st_size / 1024:.1f} KB\n")
    
    # Финальный отчет
    print(f"{YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{RESET}\n")
    print(f"{BOLD}{MAGENTA}СТАТИСТИКА ГЕНЕРАЦИИ:{RESET}\n")
    
    # Анализ длин ответов
    response_lengths = [len(s['output']) for s in samples]
    avg_length = sum(response_lengths) / len(response_lengths) if response_lengths else 0
    
    print(f"  Всего пар: {len(samples)}")
    print(f"  Средняя длина ответа: {avg_length:.0f} символов")
    print(f"  Минимальная длина: {min(response_lengths) if response_lengths else 0} символов")
    print(f"  Максимальная длина: {max(response_lengths) if response_lengths else 0} символов")
    print(f"  Успешность: {(len(samples) / TARGET_SAMPLES * 100):.1f}%\n")
    
    # Следующие шаги
    print(f"{BOLD}{GREEN}╔════════════════════════════════════════════════════════════════╗{RESET}")
    print(f"{BOLD}{GREEN}║   ✅ ОПЕРАЦИЯ 'DATA FORGE' УСПЕШНА                           ║{RESET}")
    print(f"{BOLD}{GREEN}╚════════════════════════════════════════════════════════════════╝{RESET}\n")
    
    print(f"{CYAN}СЛЕДУЮЩИЕ ШАГИ:{RESET}\n")
    print(f"  1. Скопировать датасет в LLaMA-Factory:")
    print(f"     {YELLOW}copy {OUTPUT_FILE} E:\\WORLD_OLLAMA\\services\\llama_factory\\data\\{RESET}\n")
    print(f"  2. Открыть LLaMA Board: {CYAN}http://localhost:7860{RESET}\n")
    print(f"  3. Настроить Fine-tuning:")
    print(f"     - Dataset: {YELLOW}triz_synthesis_v1.jsonl{RESET}")
    print(f"     - Model: {YELLOW}Qwen2-7B-Instruct{RESET}")
    print(f"     - Method: {YELLOW}LoRA (rank 8){RESET}")
    print(f"     - Output: {YELLOW}qwen2-triz-v2{RESET}\n")
    print(f"  4. Запустить обучение: {GREEN}Start Training{RESET}\n")
    
    print(f"{YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{RESET}\n")
    print(f"{GREEN}Датасет готов к Fine-tuning!{RESET}\n")


if __name__ == "__main__":
    main()
