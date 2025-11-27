<script lang="ts">
  import { notifications, type Notification } from "$lib/stores/notifications";
  import { onDestroy } from "svelte";

  // ============================================================================
  // Task 6.2: NotificationCenter Component
  // Отображение всех уведомлений в overlay (правый верхний угол)
  // ============================================================================

  let items: Notification[] = [];
  const unsubscribe = notifications.subscribe((value) => (items = value));

  onDestroy(() => {
    unsubscribe();
  });
</script>

<div class="notifications-container">
  {#each items as n (n.id)}
    <div class="notification notification-{n.type}" role="alert">
      <div class="notification-content">
        <div class="notification-header">
          <span class="notification-icon">
            {#if n.type === "error"}❌{/if}
            {#if n.type === "warning"}⚠️{/if}
            {#if n.type === "success"}✅{/if}
            {#if n.type === "info"}ℹ️{/if}
          </span>
          <span class="notification-message">{n.message}</span>
          <button 
            class="notification-close" 
            on:click={() => notifications.remove(n.id)}
            aria-label="Закрыть"
          >
            ×
          </button>
        </div>
        {#if n.details}
          <div class="notification-details">
            {n.details}
          </div>
        {/if}
      </div>
    </div>
  {/each}
</div>

<style>
  .notifications-container {
    position: fixed;
    top: 20px;
    right: 20px;
    z-index: 9999;
    display: flex;
    flex-direction: column;
    gap: 12px;
    max-width: 400px;
    pointer-events: none;
  }

  .notification {
    pointer-events: auto;
    background: white;
    border-radius: 8px;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15), 0 0 0 1px rgba(0, 0, 0, 0.1);
    overflow: hidden;
    animation: slideIn 0.3s ease-out;
    min-width: 300px;
  }

  @keyframes slideIn {
    from {
      transform: translateX(100%);
      opacity: 0;
    }
    to {
      transform: translateX(0);
      opacity: 1;
    }
  }

  .notification-content {
    padding: 16px;
  }

  .notification-header {
    display: flex;
    align-items: flex-start;
    gap: 12px;
  }

  .notification-icon {
    font-size: 20px;
    flex-shrink: 0;
    line-height: 1;
  }

  .notification-message {
    flex: 1;
    font-weight: 600;
    font-size: 14px;
    line-height: 1.5;
    color: #1a1a1a;
  }

  .notification-close {
    background: none;
    border: none;
    color: #666;
    font-size: 24px;
    line-height: 1;
    cursor: pointer;
    padding: 0;
    width: 24px;
    height: 24px;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: 4px;
    transition: all 0.2s;
    flex-shrink: 0;
  }

  .notification-close:hover {
    background: rgba(0, 0, 0, 0.05);
    color: #333;
  }

  .notification-details {
    margin-top: 8px;
    margin-left: 32px;
    font-size: 13px;
    line-height: 1.5;
    color: #666;
    word-break: break-word;
  }

  /* Цветовые схемы для разных типов */
  .notification-error {
    border-left: 4px solid #ef4444;
  }

  .notification-error .notification-message {
    color: #dc2626;
  }

  .notification-warning {
    border-left: 4px solid #f59e0b;
  }

  .notification-warning .notification-message {
    color: #d97706;
  }

  .notification-success {
    border-left: 4px solid #10b981;
  }

  .notification-success .notification-message {
    color: #059669;
  }

  .notification-info {
    border-left: 4px solid #3b82f6;
  }

  .notification-info .notification-message {
    color: #2563eb;
  }

  /* Анимация исчезновения */
  .notification {
    transition: all 0.3s ease-out;
  }

  .notification:hover {
    transform: translateY(-2px);
    box-shadow: 0 6px 16px rgba(0, 0, 0, 0.2), 0 0 0 1px rgba(0, 0, 0, 0.1);
  }
</style>
