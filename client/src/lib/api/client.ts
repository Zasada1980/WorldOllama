import { invoke } from "@tauri-apps/api/core";
import { notifications } from "$lib/stores/notifications";

// ============================================================================
// Task 6.3: Unified API Client Wrapper
// Обёртка над Tauri invoke с автоматической обработкой ошибок
// ============================================================================

/**
 * Структура ошибки из Rust бекенда
 */
export interface ApiError {
  type: string;
  message: string;
}

/**
 * Стандартный ответ от всех Tauri команд
 */
export interface ApiResponse<T> {
  ok: boolean;
  data?: T;
  error?: ApiError;
}

/**
 * Настройки приложения (соответствует Rust struct AppSettings)
 */
export interface AppSettings {
  ollama_model: string;
  max_tokens: number | null;
  cortex_top_k: number;
  cortex_mode: string;
  active_agent_profile: string;
}

/**
 * Единая точка вызова всех Tauri команд.
 * 
 * - Автоматически обрабатывает ошибки (ApiResponse.ok === false)
 * - Ловит исключения (connection refused, command not found, etc.)
 * - Пушит уведомления в глобальный store
 * - Возвращает data или null (компонент проверяет null)
 * 
 * @param command - имя Tauri команды (например, "send_ollama_chat")
 * @param args - аргументы команды (Record<string, unknown>)
 * @param silent - если true, не показывать уведомление (для статусных запросов)
 * @returns Promise<T | null> - данные или null при ошибке
 */
export async function callApi<T>(
  command: string,
  args?: Record<string, unknown>,
  silent: boolean = false
): Promise<T | null> {
  try {
    const res = await invoke<ApiResponse<T>>(command, args);

    // ========================================================================
    // Случай 1: Rust вернул ApiResponse с ok: false
    // (например, Ollama недоступен, CORTEX вернул ошибку)
    // ========================================================================
    if (!res.ok) {
      if (!silent) {
        notifications.push({
          type: "error",
          message: `Ошибка: ${command}`,
          details: res.error?.message ?? "Неизвестная ошибка из бекенда",
          timeoutMs: 8000, // ошибки показываем дольше
        });
      }
      return null;
    }

    // ========================================================================
    // Случай 2: Успех - возвращаем data (может быть undefined)
    // ========================================================================
    return res.data ?? null;

  } catch (e: any) {
    // ========================================================================
    // Случай 3: Исключение на уровне invoke
    // (таймаут, connection refused, команда не найдена, сериализация упала)
    // ========================================================================
    if (!silent) {
      notifications.push({
        type: "error",
        message: `Не удалось выполнить команду ${command}`,
        details: e?.message ?? String(e),
        timeoutMs: 8000,
      });
    }
    return null;
  }
}

// ============================================================================
// Удобные методы для типизированных вызовов
// ============================================================================

/**
 * Обёртка для отправки сообщения в Ollama
 */
export async function sendOllamaChat(
  message: string,
  model: string
): Promise<{ text: string } | null> {
  return callApi<{ text: string }>("send_ollama_chat", { prompt: message, model });
}

/**
 * Обёртка для запроса к CORTEX (LightRAG)
 */
export async function sendCortexQuery(
  query: string,
  mode: string
): Promise<{ text: string } | null> {
  return callApi<{ text: string }>("send_cortex_query", { query, mode });
}

/**
 * Обёртка для получения статуса системы (без уведомлений при ошибке)
 */
export async function getSystemStatus() {
  return callApi<{
    ollama: { available: boolean; models: string[] };
    cortex: { available: boolean };
  }>("get_system_status", undefined, true); // silent = true
}

/**
 * Обёртка для загрузки настроек
 */
export async function getAppSettings() {
  return callApi<AppSettings>("get_app_settings");
}

/**
 * Обёртка для сохранения настроек
 */
export async function saveAppSettings(settings: AppSettings) {
  const result = await callApi<AppSettings>("save_app_settings", { settings });

  // При успешном сохранении показываем success уведомление
  if (result) {
    notifications.push({
      type: "success",
      message: "Настройки сохранены",
      timeoutMs: 4000,
    });
  }

  return result;
}

// Task 7.1: Indexation API
export async function startIndexation() {
  return callApi<{ started_at: string; status: string }>("start_indexation");
}

export async function getIndexationStatus() {
  return callApi<{
    state: string;
    last_run: string | null;
    last_error?: string | null;
  }>("get_indexation_status", {}, true); // silent mode
}

// Task 8.2: Agent Command Execution API
export async function executeAgentCommand(command_text: string) {
  return callApi<{
    success: boolean;
    message: string;
    command_type: string;
  }>("execute_agent_command", { command_text });
}

// TASK 12.2: Training Management API
export async function getTrainingStatus() {
  return callApi<{
    state: 'idle' | 'queued' | 'running' | 'done' | 'error';
    profile: string | null;
    dataset_path: string | null;
    progress: number | null;
    log_path: string | null;
    updated_at: string | null;
    message: string | null;
    total_epochs: number | null;
    current_epoch: number | null;
  }>("get_training_status", {}, true); // silent mode
}

export async function clearTrainingStatus() {
  return callApi<void>("clear_training_status");
}

export async function listTrainingProfiles() {
  return callApi<Array<{
    id: string;
    name: string;
    description: string;
    base_model: string;
    recommended_epochs: number;
  }>>("list_training_profiles", {}, true);
}

export async function listDatasetsRoots() {
  return callApi<Array<{
    path: string;
    name: string;
    file_count: number | null;
  }>>("list_datasets_roots", {}, true);
}

// ORDER 42.2: Direct training start via Tauri (bypasses DSL)
export async function startTrainingJob(
  profile: string,
  dataPath: string,  // ← camelCase (Tauri converts to data_path automatically)
  epochs: number,
  mode: string = "llama_factory"
) {
  return callApi<{
    success: boolean;
    message: string;
  }>("start_training_job", {
    profile,
    dataPath,  // ← camelCase matches Tauri's auto-conversion
    epochs,
    mode
  });
}

export const apiClient = {
  callApi,
  sendOllamaChat,
  sendCortexQuery,
  getSystemStatus,
  getAppSettings,
  saveAppSettings,
  startIndexation,
  getIndexationStatus,
  executeAgentCommand,
  getTrainingStatus,
  clearTrainingStatus,
  listTrainingProfiles,
  listDatasetsRoots,
  startTrainingJob, // ORDER 42.2
};
