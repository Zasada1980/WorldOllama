"""Command-line helper for the Knowledge Connector.

The CLI is intentionally lightweight: it only depends on the bundled
``knowledge_connector`` package. Usage examples are documented in the README.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any, Dict

from knowledge_connector import KnowledgeLibrary


def _print_json(payload: Dict[str, Any]) -> None:
    print(json.dumps(payload, indent=2, ensure_ascii=False))


def cmd_health(args: argparse.Namespace) -> None:
    client = KnowledgeLibrary(base_url=args.base_url)
    ok = client.health_check()
    _print_json({"endpoint": "health", "ok": ok})


def cmd_query(args: argparse.Namespace) -> None:
    client = KnowledgeLibrary(base_url=args.base_url)
    if args.query_file:
        query_text = Path(args.query_file).read_text(encoding="utf-8").strip()
    else:
        query_text = args.query
    response = client.query(query_text, mode=args.mode)
    _print_json(response)


def cmd_status(args: argparse.Namespace) -> None:
    client = KnowledgeLibrary(base_url=args.base_url)
    response = client.get_status()
    _print_json(response)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Knowledge Connector CLI")
    parser.add_argument(
        "--base-url",
        default="http://localhost:8003",
        help="LightRAG API base URL (default: %(default)s)",
    )

    subparsers = parser.add_subparsers(dest="command", required=True)

    health = subparsers.add_parser("health", help="Perform health check")
    health.set_defaults(func=cmd_health)

    query = subparsers.add_parser("query", help="Send a semantic query")
    query.add_argument("--query", "-q", help="Inline query text")
    query.add_argument("--query-file", help="Path to file that contains query text")
    query.add_argument("--mode", default="hybrid", choices=["naive", "local", "global", "hybrid"])
    query.set_defaults(func=cmd_query)

    status = subparsers.add_parser("status", help="Fetch ingestion status")
    status.set_defaults(func=cmd_status)

    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
