"""Knowledge Connector SDK
============================

Sandbox-friendly Python client for the LightRAG knowledge library API. The
implementation is intentionally self-contained so it can be vendored into any
agent without extra dependencies beyond ``requests``.
"""
from __future__ import annotations

from dataclasses import dataclass
import os
from typing import Any, Dict, Literal, Optional

import requests

QueryMode = Literal["naive", "local", "global", "hybrid"]


def _clean_base_url(base_url: str) -> str:
    """Strip trailing slash while preserving scheme."""
    return base_url.rstrip("/") if base_url else base_url


@dataclass
class ConnectorConfig:
    """Runtime configuration for :class:`KnowledgeLibrary`."""

    base_url: str = "http://localhost:8003"
    api_key: Optional[str] = None

    @classmethod
    def from_env(cls) -> "ConnectorConfig":
        """Create config from environment variables.

        Recognized variables:
        - ``KNOWLEDGE_LIBRARY_URL``: override base URL.
        - ``KNOWLEDGE_LIBRARY_API_KEY``: optional bearer token.
        """

        return cls(
            base_url=os.getenv("KNOWLEDGE_LIBRARY_URL", "http://localhost:8003"),
            api_key=os.getenv("KNOWLEDGE_LIBRARY_API_KEY"),
        )


class KnowledgeLibrary:
    """Client for the AI Knowledge Library REST API."""

    def __init__(self, base_url: str = "http://localhost:8003", api_key: Optional[str] = None) -> None:
        self.config = ConnectorConfig(base_url=_clean_base_url(base_url), api_key=api_key)
        self.session = requests.Session()

    @classmethod
    def from_env(cls) -> "KnowledgeLibrary":
        """Instantiate client using :class:`ConnectorConfig.from_env`."""

        cfg = ConnectorConfig.from_env()
        return cls(base_url=cfg.base_url, api_key=cfg.api_key)

    # ------------------------------------------------------------------
    # Core operations
    # ------------------------------------------------------------------
    def query(self, query: str, mode: QueryMode = "hybrid", timeout: int = 60) -> Dict[str, Any]:
        """Send a semantic query to the LightRAG API."""

        payload = {"query": query, "mode": mode}
        return self._post("/query", payload, timeout)

    def insert(
        self,
        text: str,
        description: Optional[str] = None,
        metadata: Optional[Dict[str, Any]] = None,
        timeout: int = 600,
    ) -> Dict[str, Any]:
        """Insert a raw text document into the library."""

        payload: Dict[str, Any] = {"text": text}
        if description:
            payload["description"] = description
        if metadata:
            payload["metadata"] = metadata
        return self._post("/insert", payload, timeout)

    def get_status(self) -> Dict[str, Any]:
        """Return ingestion status summary."""

        return self._get("/status")

    def health_check(self) -> bool:
        """Return ``True`` if the API responds with HTTP 200."""

        try:
            response = self.session.get(self._url("/health"), timeout=5)
            response.raise_for_status()
        except requests.RequestException:
            return False
        return True

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------
    def _url(self, path: str) -> str:
        return f"{self.config.base_url}{path}"

    def _headers(self) -> Dict[str, str]:
        headers = {"Content-Type": "application/json"}
        if self.config.api_key:
            headers["Authorization"] = f"Bearer {self.config.api_key}"
        return headers

    def _post(self, path: str, payload: Dict[str, Any], timeout: int) -> Dict[str, Any]:
        try:
            response = self.session.post(
                self._url(path),
                json=payload,
                headers=self._headers(),
                timeout=timeout,
            )
            response.raise_for_status()
            return response.json()
        except requests.Timeout:
            return {"error": "Request timeout", "payload": payload}
        except requests.RequestException as exc:
            return {"error": str(exc), "payload": payload}

    def _get(self, path: str, timeout: int = 30) -> Dict[str, Any]:
        try:
            response = self.session.get(self._url(path), headers=self._headers(), timeout=timeout)
            response.raise_for_status()
            return response.json()
        except requests.Timeout:
            return {"error": "Request timeout", "endpoint": path}
        except requests.RequestException as exc:
            return {"error": str(exc), "endpoint": path}


__all__ = ["KnowledgeLibrary", "ConnectorConfig", "QueryMode"]
