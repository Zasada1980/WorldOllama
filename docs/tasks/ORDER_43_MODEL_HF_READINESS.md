# ORDER 43 — MODEL & HF READINESS

**Status:** 📋 PLANNED  
**Created:** 01.12.2025  
**Priority:** 🟡 MEDIUM  
**Blocks:** Real training execution (ORDER 42 UI/Backend works)

---

## 🎯 OBJECTIVE

Enable at least one training profile to complete end-to-end training without model access errors.

**Current Blocker:**  
ORDER 42 successfully launches `llamafactory-cli`, but training fails immediately due to HuggingFace gated model access:

```
OSError: You are trying to access a gated repo.
Access to model meta-llama/Meta-Llama-3-8B-Instruct is restricted.
You must have access to it and be authenticated to access it. Please log in.
```

---

## 📋 SUB-COMMANDS

### COMMAND 43.1 — HF Authentication Setup

**Option A: Configure HuggingFace Token**

Steps:
1. Create HuggingFace account
2. Request access to `meta-llama/Meta-Llama-3-8B-Instruct`
3. Generate access token at https://huggingface.co/settings/tokens
4. Login via CLI:
   ```powershell
   cd E:\WORLD_OLLAMA\services\llama_factory
   .\venv\Scripts\huggingface-cli.exe login
   # Paste token
   ```

**Option B: Use Open Model**

Steps:
1. Edit `services/llama_factory/examples/train_lora/llama3_lora_sft.yaml`
2. Change `model_name_or_path` from:
   ```yaml
   model_name_or_path: meta-llama/Meta-Llama-3-8B-Instruct
   ```
   To an open model:
   ```yaml
   model_name_or_path: microsoft/Phi-3-mini-4k-instruct
   # OR
   model_name_or_path: /path/to/local/model
   ```

**Option C: Create New Profile**

Steps:
1. Create new YAML config for non-gated model
2. Add mapping in `client/src-tauri/src/training_manager.rs`
3. Test via UI

---

### COMMAND 43.2 — E2E Smoke Test

**Objective:** Verify 1 epoch training completes successfully

Steps:
1. Configure model access (43.1)
2. Launch training via UI:
   - Profile: `default` (or new profile)
   - DataPath: `E:\WORLD_OLLAMA\library\raw_documents`
   - Epochs: 1
3. Monitor logs:
   ```powershell
   Get-Content E:\WORLD_OLLAMA\logs\training\train-*.log -Tail 50 -Wait
   ```
4. Verify completion:
   - No OSError
   - Training reaches 100%
   - Model checkpoint saved

---

### COMMAND 43.3 — User Documentation

**Objective:** Document setup steps for users

Create: `docs/TRAINING_SETUP.md`

Content:
- Prerequisites (Python, venv, HF account)
- Model access configuration
- First training run
- Troubleshooting common errors

---

## ✅ DEFINITION OF DONE

- [ ] Model access configured (HF token OR open model)
- [ ] Smoke test (1 epoch) completes successfully
- [ ] Documentation created for users
- [ ] ORDER 42 UI can trigger functional training

---

## 📝 NOTES

**Out of Scope:**
- Multi-GPU training
- Custom dataset integration
- Advanced LoRA configuration
- Model fine-tuning optimization

**Dependencies:**
- ✅ ORDER 42 complete (UI/Backend pipeline works)

---

**Created:** 01.12.2025  
**Next Step:** Choose Option A, B, or C for 43.1
