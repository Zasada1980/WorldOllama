// WORLD_OLLAMA Desktop Client
// Task 8.5: Command Slot Store (Chat → CommandSlot Bridge)

import { writable } from "svelte/store";

export interface CommandSlotState {
  commandText: string;
  description: string | null;
}

const initial: CommandSlotState = {
  commandText: "",
  description: null,
};

function createCommandSlotStore() {
  const { subscribe, set, update } = writable<CommandSlotState>(initial);

  return {
    subscribe,
    
    /**
     * Устанавливает команду и описание в Command Slot
     * @param commandText - DSL команда (например, INDEX KNOWLEDGE\nPATH="...")
     * @param description - Человеко-читаемое описание (опционально)
     */
    setCommand(commandText: string, description?: string | null) {
      set({
        commandText,
        description: description ?? null,
      });
    },

    /**
     * Очищает Command Slot (сброс к начальному состоянию)
     */
    clear() {
      set(initial);
    },
  };
}

export const commandSlotStore = createCommandSlotStore();
