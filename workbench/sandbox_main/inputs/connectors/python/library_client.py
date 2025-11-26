"""
AI Knowledge Library - Python Client
Простой клиент для доступа к библиотеке знаний через REST API
"""
import requests
from typing import Literal, Optional, Dict, Any

QueryMode = Literal["naive", "local", "global", "hybrid"]

class KnowledgeLibrary:
    """Клиент для работы с AI Knowledge Library"""
    
    def __init__(self, base_url: str = "http://localhost:8003"):
        """
        Инициализация клиента
        
        Args:
            base_url: URL сервера LightRAG (по умолчанию localhost:8003)
        """
        self.base_url = base_url.rstrip("/")
        self.session = requests.Session()
    
    def query(
        self, 
        query: str, 
        mode: QueryMode = "hybrid",
        timeout: int = 60
    ) -> Dict[str, Any]:
        """
        Запрос к библиотеке знаний
        
        Args:
            query: Текст запроса
            mode: Режим поиска (naive/local/global/hybrid)
            timeout: Таймаут запроса в секундах
        
        Returns:
            Словарь с ответом и метаданными
        
        Example:
            >>> library = KnowledgeLibrary()
            >>> result = library.query("Что такое ТРИЗ?", mode="hybrid")
            >>> print(result['answer'])
        """
        endpoint = f"{self.base_url}/query"
        payload = {"query": query, "mode": mode}
        
        try:
            response = self.session.post(
                endpoint, 
                json=payload, 
                timeout=timeout
            )
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
        timeout: int = 600
    ) -> Dict[str, Any]:
        """
        Добавить документ в библиотеку
        
        Args:
            text: Текст документа
            description: Описание документа
            timeout: Таймаут запроса в секундах (10 минут по умолчанию)
        
        Returns:
            Статус операции
        """
        endpoint = f"{self.base_url}/insert"
        payload = {"text": text}
        if description:
            payload["description"] = description
        
        try:
            response = self.session.post(
                endpoint, 
                json=payload, 
                timeout=timeout
            )
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            return {"error": str(e)}
    
    def get_status(self) -> Dict[str, Any]:
        """
        Получить статус индексации
        
        Returns:
            Статистика по обработанным документам
        """
        endpoint = f"{self.base_url}/status"
        
        try:
            response = self.session.get(endpoint, timeout=10)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            return {"error": str(e)}
    
    def health_check(self) -> bool:
        """
        Проверка доступности сервера
        
        Returns:
            True если сервер доступен
        """
        endpoint = f"{self.base_url}/health"
        
        try:
            response = self.session.get(endpoint, timeout=5)
            return response.status_code == 200
        except:
            return False
