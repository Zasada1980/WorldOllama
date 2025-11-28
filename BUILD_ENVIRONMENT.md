# Build Environment — WORLD_OLLAMA v0.2.0

**Дата:** 28 ноября 2025 г.  
**OS:** Windows 10/11 (64-bit)

## Toolchain Versions

### Rust
- **rustc:** 1.83.0 (проверьте: `rustc --version`)
- **cargo:** 1.83.0 (проверьте: `cargo --version`)
- **Target:** x86_64-pc-windows-msvc

### Node.js / JavaScript
- **Node.js:** v23.3.0 (проверьте: `node --version`)
- **npm:** 10.9.0 (проверьте: `npm --version`)
- **SvelteKit:** (проверьте: `cd client; npm list @sveltejs/kit`)
- **Tauri CLI:** 2.0.0

### Python (Services)
- **Python:** 3.12.10 ✅ (подтверждено)
- **LLaMA Factory:** Custom fork
- **LightRAG:** v1.4.9.8

## System Requirements (минимальные)

- **RAM:** 16 GB (рекомендуется 32 GB)
- **VRAM:** 12 GB (для qwen2.5:14b + training)
- **Disk:** 50 GB свободного места
- **Ports:** 11434, 8004, 8501 (свободны)

## Verification Commands

Выполните в PowerShell терминале:

```powershell
# Rust
rustc --version
cargo --version

# Node.js
node --version
npm --version

# Python
python --version

# Ollama
ollama --version

# SvelteKit (в директории client)
cd client
npm list @sveltejs/kit
```

## Next Steps (КОМАНДА 2)

После проверки версий выполнить:

```powershell
# Компиляция Rust
cd E:\WORLD_OLLAMA\client\src-tauri
cargo check

# Компиляция Frontend
cd E:\WORLD_OLLAMA\client
npm run check
```
