# RUST TOOLCHAIN PREREQUISITE

**Проект:** WORLD_OLLAMA Desktop Client (Tauri)  
**Документ:** Rust Toolchain Requirement & Installation Guide  
**Дата создания:** 27.11.2025  
**Статус:** ✅ **RESOLVED** (Rust 1.91.1 установлен 27.11.2025 17:05)

---

## 🚨 КРИТИЧЕСКАЯ ЗАВИСИМОСТЬ

**Phase 3 (Tauri MVP) РАЗБЛОКИРОВАНА** ✅

### ✅ Rust Toolchain Установлен

**Дата установки:** 27.11.2025 17:05  
**Версия:** rustc 1.91.1 (ed61e7d7e 2025-11-07)  
**Результат проверки:**

```
rustc 1.91.1 (ed61e7d7e 2025-11-07)
cargo 1.91.1 (ea2d97820 2025-10-10)
rustup 1.28.2 (e4f3ad6f8 2025-04-28)
```

**Статус:** ✅ **ВСЕ КОМПОНЕНТЫ РАБОТАЮТ**

---

## 📋 ИСТОРИЯ УСТАНОВКИ (для справки)

### Проверка до установки (27.11.2025 16:50)

**Результат команды `rustc --version`:**

```
rustc: The term 'rustc' is not recognized as a name of a cmdlet, function, 
script file, or executable program.
```

**Диагноз:** ❌ **Rust не установлен** или не добавлен в PATH.

---

## 📋 ТРЕБОВАНИЯ TAURI

**Tauri Framework требует:**

1. **Rust toolchain** (stable channel)
   - `rustc` — компилятор Rust
   - `cargo` — пакетный менеджер Rust
   - `rustup` — версионный менеджер Rust

2. **Platform-specific build tools** (Windows)
   - Microsoft C++ Build Tools
   - Windows 10/11 SDK

**Без установленного Rust:**
- ❌ `npx create-tauri-app` создаёт структуру, но выдаёт предупреждение
- ❌ `npm run tauri dev` **не запустится** (ошибка компиляции Rust Core)
- ❌ `npm run tauri build` **не соберёт** бинарник

**Вывод:**
> **Без Rust Phase 3 (Tauri MVP) продолжать нельзя.**  
> **Нужна установка через rustup (Windows).**

---

## 🔧 УСТАНОВКА RUST (WINDOWS)

### Вариант 1: Автоматическая установка через rustup-init

**Шаги (вручную):**

1. **Открыть браузер:**
   - Перейти на https://rustup.rs/

2. **Скачать установщик:**
   - Для Windows x64: `rustup-init.exe` (~1-2 MB)
   - Прямая ссылка: https://win.rustup.rs/x86_64

3. **Запустить установщик:**
   - Двойной клик на `rustup-init.exe`
   - **Рекомендуемые настройки:**
     - Install option: `1) Proceed with installation (default)`
     - Toolchain: `stable-x86_64-pc-windows-msvc` (default)
     - Default host triple: `x86_64-pc-windows-msvc`

4. **Дождаться завершения установки:**
   - Скачивание Rust toolchain: ~200-500 MB
   - Время: 5-10 минут (зависит от скорости интернета)

5. **Перезапустить терминал:**
   - **ВАЖНО:** Закрыть текущее окно PowerShell
   - Открыть новое (чтобы PATH обновился)

---

### Вариант 2: Установка через PowerShell (автоматизация)

**Команды для PowerShell (Run as Administrator):**

```powershell
# Download rustup-init.exe
Invoke-WebRequest -Uri https://win.rustup.rs/x86_64 -OutFile $env:TEMP\rustup-init.exe

# Run installer with default settings (non-interactive)
& $env:TEMP\rustup-init.exe -y

# Refresh PATH in current session (optional, лучше открыть новый терминал)
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
```

**После установки:**

```powershell
# Verify installation
rustc --version
cargo --version
rustup --version
```

**Ожидаемый вывод:**

```
rustc 1.xx.x (xxxxx 2025-xx-xx)
cargo 1.xx.x (xxxxx 2025-xx-xx)
rustup 1.xx.x (xxxxx 2025-xx-xx)
```

---

## 📝 ПРОВЕРКА УСПЕШНОЙ УСТАНОВКИ

### Команды для проверки

**1. Проверить компилятор Rust:**

```powershell
rustc --version
```

**Ожидаемый результат:**

```
rustc 1.83.0 (90b35a623 2024-11-26)
```

(или более новая версия)

---

**2. Проверить Cargo (пакетный менеджер):**

```powershell
cargo --version
```

**Ожидаемый результат:**

```
cargo 1.83.0 (5ffbef321 2024-10-29)
```

---

**3. Проверить Rustup (версионный менеджер):**

```powershell
rustup --version
```

**Ожидаемый результат:**

```
rustup 1.27.1 (54dd3d00f 2024-04-24)
```

---

**4. Проверить установленные toolchains:**

```powershell
rustup show
```

**Ожидаемый результат:**

```
Default host: x86_64-pc-windows-msvc
rustup home:  C:\Users\<user>\.rustup

installed toolchains
--------------------
stable-x86_64-pc-windows-msvc (default)

active toolchain
----------------
stable-x86_64-pc-windows-msvc (default)
rustc 1.83.0 (90b35a623 2024-11-26)
```

---

## ✅ ПОСЛЕ УСПЕШНОЙ УСТАНОВКИ

### Обновить этот документ

**После установки Rust обновить раздел ниже:**

```markdown
## Обновление статуса

- **Дата:** <текущая дата>
- **rustc:** <вывод `rustc --version`>
- **cargo:** <вывод `cargo --version`>
- **Статус:** ✅ Rust доступен, можно продолжать настройку Tauri.
```

---

### Продолжить Phase 3

**Следующие шаги:**

1. **Вернуться к Task 1:**
   ```powershell
   cd E:\WORLD_OLLAMA
   npx create-tauri-app@latest client --manager npm --template svelte-ts --yes
   ```

2. **Установить зависимости:**
   ```powershell
   cd client
   npm install
   ```

3. **Запустить Tauri dev:**
   ```powershell
   npm run tauri dev
   ```

4. **Проверить успешный запуск:**
   - Окно приложения открылось
   - Нет ошибок компиляции Rust Core
   - Базовый UI видим

5. **Зафиксировать успех:**
   - Обновить `PHASE_3_DIRECTOR_REPORT.md`
   - Отметить Task 1 как ✅ COMPLETE

---

## 🔗 ДОПОЛНИТЕЛЬНЫЕ РЕСУРСЫ

**Official Documentation:**
- Rust Installation: https://www.rust-lang.org/tools/install
- Rustup Book: https://rust-lang.github.io/rustup/
- Tauri Prerequisites: https://tauri.app/start/prerequisites/

**Windows-Specific:**
- Microsoft C++ Build Tools: https://visualstudio.microsoft.com/downloads/ (если требуется)
- Windows SDK: обычно устанавливается автоматически через rustup

**Troubleshooting:**
- Rust не в PATH после установки → Перезапустить терминал
- Ошибки компиляции MSVC → Установить Visual Studio Build Tools
- `cargo` медленно работает → Настроить зеркала crates.io (optional)

---

## 📊 IMPACT ASSESSMENT

**Блокирует:**
- ✅ Task 1: Tauri + Svelte initialization
- ✅ Task 2: Core bridge (Rust backend для Ollama/CORTEX)
- ✅ Task 3: Chat UI (нет backend без Rust)
- ✅ Tasks 4-7: Все последующие задачи Phase 3

**Не блокирует:**
- ✅ Task 1R: Подготовка структуры `client/` (можно делать параллельно)
- ✅ Документация UX_SPEC (Phase 2 завершена)
- ✅ Работа с existing сервисами (Ollama, CORTEX работают независимо)

**Timeline Impact:**
- **Estimated installation time:** 10-20 минут (download + install + verify)
- **Phase 3 delay:** 0 дней (если установка сегодня)
- **Deadline risk:** 🟡 LOW (13 дней до 10.12.2025, buffer достаточный)

---

**Статус:** 🔴 **BLOCKER ACTIVE** (awaiting Rust installation)  
**Next Action:** Install Rust via rustup, then update this document  
**Responsible:** Developer (manual installation required)  
**Updated:** 27.11.2025
