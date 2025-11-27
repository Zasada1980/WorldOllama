import { writable } from "svelte/store";

// ============================================================================
// Task 6.1: Global Notification Store
// Единое хранилище уведомлений для всего приложения
// ============================================================================

export type NotificationType = "info" | "success" | "warning" | "error";

export interface Notification {
  id: string;
  type: NotificationType;
  message: string;
  details?: string;
  createdAt: number;
  timeoutMs?: number;
}

function createNotificationStore() {
  const { subscribe, update } = writable<Notification[]>([]);

  /**
   * Добавить новое уведомление
   * @param notification Данные уведомления (id и createdAt генерируются автоматически)
   * @returns ID созданного уведомления
   */
  function push(notification: Omit<Notification, "id" | "createdAt">) {
    const id = crypto.randomUUID();
    const createdAt = Date.now();
    const full: Notification = { id, createdAt, ...notification };
    
    update((list) => [...list, full]);

    // Автоматическое удаление через таймаут (по умолчанию 6 секунд)
    const timeout = notification.timeoutMs ?? 6000;
    if (timeout > 0) {
      setTimeout(() => {
        remove(id);
      }, timeout);
    }

    return id;
  }

  /**
   * Удалить уведомление по ID
   */
  function remove(id: string) {
    update((list) => list.filter((n) => n.id !== id));
  }

  /**
   * Очистить все уведомления
   */
  function clear() {
    update(() => []);
  }

  return { subscribe, push, remove, clear };
}

export const notifications = createNotificationStore();
