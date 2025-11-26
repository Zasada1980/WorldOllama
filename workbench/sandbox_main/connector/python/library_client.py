"""
AI Knowledge Library - Python Client (sandbox copy)
"""
import requests
from typing import Literal, Optional, Dict, Any

QueryMode = Literal["naive", "local", "global", "hybrid"]

class KnowledgeLibrary:
    """Клиент для работы с AI Knowledge Library"""

    def __init__(self, base_url: str = "http://localhost:8003"):
        self.base_url = base_url.rstrip("/")
        self.session = requests.Session()

    def query(
        self,
        query: str,
        mode: QueryMode = "hybrid",
        timeout: int = 60
    ) -> Dict[str, Any]:
        endpoint = f"{self.base_url}/query"
        payload = {"query": query, "mode": mode}

        try:
            response = self.session.post(endpoint, json=payload, timeout=timeout)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.Timeout:
            return {"error": "Request timeout", "query": query}
        except requests.exceptions.RequestException as e:
            return {"error": str(e), "query": query}

    def insert(
        self,
        text: str,
        description: Optional[str] = None,
        metadata: Optional[Dict[str, Any]] = None,
        timeout: int = 600
    ) -> Dict[str, Any]:
        endpoint = f"{self.base_url}/insert"
        payload: Dict[str, Any] = {"text": text}
        if description:
            payload["description"] = description
        if metadata:
            payload["metadata"] = metadata

        try:
            response = self.session.post(endpoint, json=payload, timeout=timeout)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            return {"error": str(e)}

    def get_status(self) -> Dict[str, Any]:
        endpoint = f"{self.base_url}/status"

        try:
            response = self.session.get(endpoint, timeout=10)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            return {"error": str(e)}

    def health_check(self) -> bool:
        endpoint = f"{self.base_url}/health"
        try:
            response = self.session.get(endpoint, timeout=5)
            return response.status_code == 200
        except Exception:
            return False
