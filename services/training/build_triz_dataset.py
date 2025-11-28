import argparse
import json
import random
from pathlib import Path
import os

# TASK 16.1: Dynamic project root
if "WORLD_OLLAMA_ROOT" in os.environ:
    ROOT = Path(os.environ["WORLD_OLLAMA_ROOT"])
else:
    # Script: services/training/build_triz_dataset.py → root = 2 levels up
    ROOT = Path(__file__).resolve().parent.parent.parent
RAW_DOCS = ROOT / "library" / "raw_documents"
OUTPUT_DIR = ROOT / "services" / "training" / "data"
OUTPUT_FILE = OUTPUT_DIR / "triz_dataset.jsonl"

# Mini-run limit for safety
MINI_FILE_LIMIT = 30


def iter_text_files(limit: int | None = None):
    count = 0
    for path in RAW_DOCS.rglob("*.txt"):
        yield path
        count += 1
        if limit is not None and count >= limit:
            break


def clean_text(text: str) -> str:
    # Basic cleanup: normalize line breaks, strip BOM and extra spaces
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    text = text.replace("\ufeff", "")
    # Collapse 3+ newlines into 2
    while "\n\n\n" in text:
        text = text.replace("\n\n\n", "\n\n")
    return text.strip()


def chunk_text(text: str, max_chars: int = 1500):
    # Simple character-based chunking by paragraphs
    paragraphs = [p.strip() for p in text.split("\n\n") if p.strip()]
    current = []
    current_len = 0
    for p in paragraphs:
        if current_len + len(p) + 2 > max_chars and current:
            yield "\n\n".join(current)
            current = []
            current_len = 0
        current.append(p)
        current_len += len(p) + 2
    if current:
        yield "\n\n".join(current)


TRIZ_PROMPTS = [
    "Объясни, что такое этот принцип ТРИЗ на понятном языке.",
    "Сформулируй кратко основной смысл этого фрагмента ТРИЗ.",
    "Сделай сжатое объяснение ключевой идеи из этого текста.",
]


def build_example_from_chunk(chunk: str) -> dict:
    instruction = random.choice(TRIZ_PROMPTS)
    return {
        "instruction": instruction,
        "input": "",
        "output": chunk.strip(),
    }


def main(mini: bool = True):
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    file_limit = MINI_FILE_LIMIT if mini else None
    files = list(iter_text_files(limit=file_limit))

    mode = "mini" if file_limit is not None else "full"
    total_files = len(files)
    total_examples = 0

    with OUTPUT_FILE.open("w", encoding="utf-8") as f_out:
        for path in files:
            text = path.read_text(encoding="utf-8", errors="ignore")
            cleaned = clean_text(text)
            for chunk in chunk_text(cleaned):
                ex = build_example_from_chunk(chunk)
                f_out.write(json.dumps(ex, ensure_ascii=False) + "\n")
                total_examples += 1

    print(f"TRIZ dataset build completed in {mode} mode")
    print(f"Files processed: {total_files}")
    print(f"Examples generated: {total_examples}")
    print(f"Output: {OUTPUT_FILE}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Build TRIZ instruction dataset from raw documents.")
    parser.add_argument(
        "--mode",
        choices=["mini", "full"],
        default="mini",
        help="mini: ограниченный прогон для проверки пайплайна; full: полный прогон по всей библиотеке",
    )

    args = parser.parse_args()
    mini_flag = args.mode == "mini"
    print(f"Running TRIZ dataset builder in {args.mode} mode (mini={mini_flag})")
    main(mini=mini_flag)
