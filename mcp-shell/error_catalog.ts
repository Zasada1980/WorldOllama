export type Classification = "timeout_exec" | "no_output_timeout" | "exec_error" | "unknown_error" | "spawn_error" | "file_not_found" | "access_denied" | "path_issue";

export interface ErrorInfo {
  code: string;
  userMessage: string;
}

const catalog: Record<Classification, ErrorInfo> = {
  timeout_exec: {
    code: "MCP_TIMEOUT",
    userMessage: "Команда превысила допустимое время выполнения. Разбейте задачу или увеличьте таймаут."
  },
  no_output_timeout: {
    code: "MCP_NO_OUTPUT",
    userMessage: "Команда не выводила данных слишком долго и была остановлена (подвисание процесса)."
  },
  exec_error: {
    code: "MCP_EXEC_ERROR",
    userMessage: "Команда завершилась с ошибкой. Проверьте синтаксис, пути и права доступа."
  },
  unknown_error: {
    code: "MCP_UNKNOWN",
    userMessage: "Неизвестная ошибка выполнения команды."
  },
  spawn_error: {
    code: "MCP_SPAWN_ERROR",
    userMessage: "Не удалось запустить процесс. Проверьте окружение и доступность интерпретатора."
  },
  file_not_found: {
    code: "MCP_FILE_NOT_FOUND",
    userMessage: "Файл или команда не найдены. Проверьте путь и наличие файла."
  },
  access_denied: {
    code: "MCP_ACCESS_DENIED",
    userMessage: "Доступ запрещён. Запустите с правами или измените ACL/политику."
  },
  path_issue: {
    code: "MCP_PATH_ISSUE",
    userMessage: "Некорректный путь или имя файла. Проверьте кавычки и экранирование."
  }
};

export function getErrorInfo(classification: Classification): ErrorInfo {
  return catalog[classification] || catalog.unknown_error;
}

export function classifyByStderr(stderr: string): Classification | null {
  const s = stderr.toLowerCase();
  if (s.includes("not found") || s.includes("cannot find path") || s.includes("не найден")) return "file_not_found";
  if (s.includes("access is denied") || s.includes("доступ запрещен") || s.includes("permission denied")) return "access_denied";
  if (s.includes("path") && (s.includes("invalid") || s.includes("incorrect") || s.includes("некоррект") || s.includes("ошиб") )) return "path_issue";
  return null;
}
