"""Neuro-Terminal: Chainlit UI that talks to Ollama and Cortex."""

import json
import os
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Literal, Optional

import chainlit as cl
from ollama import Client as OllamaClient

SERVICES_ROOT = Path(__file__).resolve().parents[1]
if str(SERVICES_ROOT) not in sys.path:
    sys.path.append(str(SERVICES_ROOT))

try:
    from connectors.synapse import knowledge_client
except ModuleNotFoundError as exc:  # pragma: no cover
    raise RuntimeError(
        "Unable to import knowledge_client from services/connectors/synapse"
    ) from exc

OLLAMA_HOST = os.getenv("NEURO_OLLAMA_HOST", "http://127.0.0.1:11434")
OLLAMA_MODEL = os.getenv("NEURO_MODEL", "qwen2.5:14b-instruct-q4_k_m")
PLANNER_PROMPT = (
    "You are the planner inside Neuro-Terminal. Decide if external knowledge "
    "from CORTEX is required before answering the user. Respond with compact "
    "JSON using keys: reasoning (string), call_knowledge (true/false), "
    "knowledge_query (string), search_mode (one of ['naive','local','global','hybrid'])."
)
RESPONSE_SYSTEM_PROMPT = (
    "You are the Neuro-Terminal assistant. Obey the Anti-Hallucination Protocol. "
    "Use CORTEX knowledge when available, cite facts, and admit when data is missing."
)


@dataclass
class Step:
    """Narrative step to mirror the agent's reasoning."""

    title: str
    content: str
    status: Literal["info", "success", "warning", "error"] = "info"

    async def publish(self) -> None:
        async with cl.Step(name=self.title) as chainlit_step:
            prefix = {
                "info": "ℹ️",
                "success": "✅",
                "warning": "⚠️",
                "error": "❌",
            }.get(self.status, "")
            chainlit_step.output = f"{prefix} {self.content}".strip()


@dataclass
class PlanDecision:
    reasoning: str
    call_knowledge: bool
    knowledge_query: str
    search_mode: knowledge_client.SearchMode = "hybrid"

    @classmethod
    def from_text(cls, text: str) -> "PlanDecision":
        json_blob = _extract_json(text) or "{}"
        try:
            data = json.loads(json_blob)
        except json.JSONDecodeError:
            data = {}
        raw_mode = str(data.get("search_mode", "hybrid")).lower()
        mode: knowledge_client.SearchMode = (  # type: ignore[assignment]
            raw_mode if raw_mode in {"naive", "local", "global", "hybrid"} else "hybrid"
        )
        raw_reasoning = str(data.get("reasoning", text.strip()))
        raw_call = str(data.get("call_knowledge", "false")).lower()
        call_flag = raw_call in {"true", "1", "yes"}
        return cls(
            reasoning=raw_reasoning,
            call_knowledge=call_flag,
            knowledge_query=data.get("knowledge_query", ""),
            search_mode=mode,
        )


def _extract_json(payload: str) -> Optional[str]:
    match = re.search(r"\{.*\}", payload, re.DOTALL)
    return match.group(0) if match else None


def _get_ollama_client() -> OllamaClient:
    client = cl.user_session.get("ollama_client")
    if client is None:
        client = OllamaClient(host=OLLAMA_HOST)
        cl.user_session.set("ollama_client", client)
    return client


def _sync_chat(messages: List[Dict[str, str]], temperature: float = 0.2) -> str:
    response = _get_ollama_client().chat(
        model=OLLAMA_MODEL,
        messages=messages,
        options={"temperature": temperature},
    )
    return response["message"]["content"]


def _format_history(history: List[Dict[str, str]]) -> List[Dict[str, str]]:
    formatted: List[Dict[str, str]] = []
    for turn in history:
        formatted.append({"role": turn["role"], "content": turn["content"]})
    return formatted


def _sanitize_query(query: str, fallback: str) -> str:
    return query.strip() or fallback


async def _plan_next_step(user_content: str, history: List[Dict[str, str]]) -> "PlanDecision":
    planner_messages = (
        [{"role": "system", "content": PLANNER_PROMPT}]
        + _format_history(history)
        + [{"role": "user", "content": user_content}]
    )
    plan_text = await cl.make_async(_sync_chat)(planner_messages, temperature=0.0)
    decision = PlanDecision.from_text(plan_text)
    await Step(
        title="Planner",
        content=f"{decision.reasoning}\nKnowledge required: {decision.call_knowledge}",
    ).publish()
    return decision


async def _fetch_knowledge(decision: "PlanDecision", user_content: str) -> Optional[str]:
    if not decision.call_knowledge:
        return None
    query = _sanitize_query(decision.knowledge_query, user_content)
    await Step(
        title="CORTEX Lookup",
        content=f"Запрос: {query[:80]}... | mode={decision.search_mode}",
        status="info",
    ).publish()
    lookup = cl.make_async(knowledge_client.lookup_knowledge)
    try:
        answer = await lookup(query=query, mode=decision.search_mode)
        await Step(
            title="Knowledge Result",
            content=f"Получено {len(answer)} символов от CORTEX",
            status="success",
        ).publish()
        return answer
    except Exception as exc:  # noqa: BLE001
        await Step(
            title="Knowledge Result",
            content=f"Ошибка доступа к CORTEX: {exc}",
            status="error",
        ).publish()
        return None


async def _generate_final_reply(
    user_content: str,
    history: List[Dict[str, str]],
    knowledge: Optional[str],
) -> str:
    messages: List[Dict[str, str]] = [{"role": "system", "content": RESPONSE_SYSTEM_PROMPT}]
    messages.extend(_format_history(history))
    if knowledge:
        messages.append({"role": "system", "content": f"CORTEX KNOWLEDGE:\n{knowledge}"})
    messages.append({"role": "user", "content": user_content})
    reply = await cl.make_async(_sync_chat)(messages, temperature=0.2)
    await Step(title="Response", content="Сформирован ответ модели", status="success").publish()
    return reply


@cl.on_chat_start
async def on_chat_start() -> None:
    cl.user_session.set("conversation", [])
    client_summary = f"Model: {OLLAMA_MODEL} @ {OLLAMA_HOST}"
    await Step(title="Neuro Terminal", content=client_summary, status="info").publish()
    try:
        health = await cl.make_async(knowledge_client.check_cortex_health)()
        status = health.get("status", "unknown")
        detail = (
            f"CORTEX status: {status}. "
            f"Working dir: {health.get('working_dir_exists')}, "
            f"Library dir: {health.get('library_dir_exists')}"
        )
        await Step(title="CORTEX", content=detail, status="success").publish()
    except Exception as exc:  # noqa: BLE001
        await Step(
            title="CORTEX",
            content=f"Не удалось подключиться: {exc}",
            status="error",
        ).publish()
    await cl.Message(content="Neuro-Terminal готов к работе. Задайте вопрос.").send()


@cl.on_message
async def on_message(message: cl.Message) -> None:
    history: List[Dict[str, str]] = cl.user_session.get("conversation", []) or []
    decision = await _plan_next_step(message.content, history)
    knowledge = await _fetch_knowledge(decision, message.content)
    reply = await _generate_final_reply(message.content, history, knowledge)
    await cl.Message(content=reply, author="Qwen").send()
    history.append({"role": "user", "content": message.content})
    history.append({"role": "assistant", "content": reply})
    cl.user_session.set("conversation", history)
