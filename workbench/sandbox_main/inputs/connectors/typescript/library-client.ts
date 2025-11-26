/**
 * AI Knowledge Library - TypeScript Client
 * Простой клиент для доступа к библиотеке знаний через REST API
 */

export type QueryMode = "naive" | "local" | "global" | "hybrid";

export interface QueryRequest {
  query: string;
  mode: QueryMode;
}

export interface QueryResponse {
  response: string;
  mode: QueryMode;
  processing_time?: number;
}

export interface InsertRequest {
  text: string;
  description?: string;
  metadata?: Record<string, any>;
}

export interface InsertResponse {
  status: string;
  message: string;
  doc_id?: string;
}

export interface StatusResponse {
  total_docs: number;
  processed: number;
  pending: number;
  processing: number;
  failed: number;
  completion_rate: number;
}

export interface HealthResponse {
  status: string;
  message: string;
}

export class KnowledgeLibraryClient {
  private baseUrl: string;
  private timeout: number;

  /**
   * Инициализация клиента
   *
   * @param baseUrl - URL LightRAG сервера (по умолчанию http://localhost:8003)
   * @param timeout - Таймаут запросов в миллисекундах (по умолчанию 60000)
   */
  constructor(baseUrl: string = "http://localhost:8003", timeout: number = 60000) {
    this.baseUrl = baseUrl.replace(/\/$/, "");
    this.timeout = timeout;
    console.log(`📚 KnowledgeLibraryClient инициализирован: ${this.baseUrl}`);
  }

  /**
   * Проверка доступности сервера
   */
  async healthCheck(): Promise<HealthResponse> {
    try {
      const response = await fetch(`${this.baseUrl}/health`, {
        method: "GET",
        signal: AbortSignal.timeout(5000),
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      const data: HealthResponse = await response.json();
      console.log("✅ Health check:", data);
      return data;
    } catch (error) {
      console.error("❌ Health check failed:", error);
      throw error;
    }
  }

  /**
   * Запрос к базе знаний
   *
   * @param query - Текст вопроса на русском языке
   * @param mode - Режим поиска (naive/local/global/hybrid, рекомендуется hybrid)
   * @param topK - Количество возвращаемых результатов (опционально)
   */
  async query(
    query: string,
    mode: QueryMode = "hybrid",
    topK?: number
  ): Promise<QueryResponse> {
    const payload: any = { query, mode };
    if (topK !== undefined) {
      payload.top_k = topK;
    }

    console.log(`🔍 Отправка запроса: query='${query.substring(0, 50)}...', mode=${mode}`);

    try {
      const response = await fetch(`${this.baseUrl}/query`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
        signal: AbortSignal.timeout(this.timeout),
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      const data: QueryResponse = await response.json();
      console.log(`✅ Получен ответ: ${data.response.length} символов`);
      return data;
    } catch (error) {
      console.error("❌ Ошибка запроса:", error);
      throw error;
    }
  }

  /**
   * Добавление нового документа в базу знаний
   *
   * @param text - Текст документа для индексации
   * @param description - Описание документа (опционально)
   * @param metadata - Метаданные документа (опционально)
   */
  async insert(
    text: string,
    description?: string,
    metadata?: Record<string, any>
  ): Promise<InsertResponse> {
    const payload: InsertRequest = { text };
    if (description) payload.description = description;
    if (metadata) payload.metadata = metadata;

    console.log(`📝 Добавление документа: ${text.length} символов`);

    try {
      const response = await fetch(`${this.baseUrl}/insert`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
        signal: AbortSignal.timeout(this.timeout),
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      const data: InsertResponse = await response.json();
      console.log(`✅ Документ добавлен: ${data.doc_id || "N/A"}`);
      return data;
    } catch (error) {
      console.error("❌ Ошибка добавления:", error);
      throw error;
    }
  }

  /**
   * Получение статуса индексации
   */
  async getStatus(): Promise<StatusResponse> {
    try {
      const response = await fetch(`${this.baseUrl}/status`, {
        method: "GET",
        signal: AbortSignal.timeout(5000),
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      const data: StatusResponse = await response.json();
      console.log(
        `📊 Статус: ${data.processed}/${data.total_docs} (${data.completion_rate.toFixed(1)}%)`
      );
      return data;
    } catch (error) {
      console.error("❌ Ошибка получения статуса:", error);
      throw error;
    }
  }

  /**
   * Пакетная обработка запросов
   *
   * @param queries - Список вопросов
   * @param mode - Режим поиска (применяется ко всем запросам)
   */
  async batchQuery(
    queries: string[],
    mode: QueryMode = "hybrid"
  ): Promise<Array<QueryResponse | { error: string; query: string }>> {
    const results: Array<QueryResponse | { error: string; query: string }> = [];

    for (let i = 0; i < queries.length; i++) {
      console.log(`🔄 Обработка запроса ${i + 1}/${queries.length}`);
      try {
        const result = await this.query(queries[i], mode);
        results.push(result);
      } catch (error: any) {
        console.warn(`⚠️ Запрос ${i + 1} failed:`, error.message);
        results.push({ error: error.message, query: queries[i] });
      }
    }

    return results;
  }
}

// Экспорт для Node.js
if (typeof module !== "undefined" && module.exports) {
  module.exports = { KnowledgeLibraryClient };
}
