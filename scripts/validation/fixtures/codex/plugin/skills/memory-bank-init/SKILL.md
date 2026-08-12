---
name: memory-bank-init
description: Create or refresh workspace memory-bank/ (MVP contract + read-only inventory). Path follows STORAGE manifest. No app code; no uv/specify. Use when invoking /memory-bank-init or Forma C Step 0 / Step N needs create/refresh/refresh-light.
---

## STOP - Read before ANY tool call

1. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/rules/guardrails.md`
2. Read `_shared/sdd-artifacts/SESSION.md`; load session-state for `$Cwd`
3. If the relevant gate is not approved: **STOP** - ask user **(pt-BR)** - do **NOT** Write/Shell
4. After create **or** refresh / refresh-light completes: **STOP** - handoff only (do not start O1/O2/O3 in this skill)
5. This skill body is **English**; user-facing prompts may be **(pt-BR)**

### Step -1 - Gate check (report in chat before continuing)

```
Gate check:
[ ] guardrails.mdc read
[ ] SESSION.md read; session-state loaded
[ ] MEMORY-BANK.md read
[ ] STORAGE.md read (bank_root resolution)
[ ] User confirmed current action (sim)
-> If any unchecked: STOP
```

---

# Skill: memory-bank-init

Credits: memory-bank ideas inspired in part by [github/spec-kit](https://github.com/github/spec-kit); this skill does **not** run Spec Kit / uv / specify. See `docs/CREDITS.md`.

## Trigger

Invoke when the user asks for: `/memory-bank-init`, `init memory bank`, `refresh memory bank`, or when Forma C Step 0 / Step N (`MEMORY-BANK.md`) requires create/refresh/refresh-light.

Optional args: `create` (default if missing), `refresh`, `refresh-light`, path to consumer repo.

## Outcome

Under the resolved **`bank_root`** (`STORAGE.md` + `MEMORY-BANK.md`):

```text
memory-bank/
  project-context.md
  tech-stack.json
  architecture.md
  domain-knowledge.md
  conventions.md
  known-risks.md
  database-schema.md      # phase 2 — when relevant / BLOCKING
  api-contracts.md        # phase 2 — when relevant / BLOCKING
  component-catalog.md    # phase 2 — when relevant / BLOCKING
  .inventory/
    sources.json
    gaps.md
    refresh-history.jsonl
```

MVP files are always required. Phase 2 files: write from templates when Prior/cited content or inventory signals make them relevant. If Prior already has DDL, OpenAPI, or a UI component map, the matching file is **BLOCKING** (or promote immediately) — empty `gaps.md` phase 2 is not “optional forever” (`MEMORY-BANK.md`).

| `storage_mode` | `bank_root` |
|----------------|-------------|
| **repository** | `$Cwd/memory-bank/` |
| **global** | `<classic.path>/memory-bank/` |

**Does not** write application code. **Does not** install Python/uv/specify. **Does not** place the bank under `features/NNN-slug/`. **Commit bank when product knowledge; never commit secrets.** Do **not** add `/memory-bank/` as a required SDD gitignore entry.

## Lazy-load

| When | Path |
|------|------|
| Caveman Mode (if active) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/caveman/CAVEMAN.md` - **Lite cap** |
| Narrative compact (optional) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/caveman/COMPACT.md` — CONTINUITY / known-risks only; requires user **sim** |
| Gate policies, stale, versioning, Step N | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/sdd-artifacts/MEMORY-BANK.md` |
| Manifest, `bank_root`, `.gitignore` | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/sdd-artifacts/STORAGE.md` |
| Templates | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/templates/memory-bank/` |
| Inventory script | toolkit `scripts/inventory/Invoke-MemoryBankInventory.ps1` (or synced copy if present) |
| Fill patterns, markers | `skills/memory-bank-init/reference.md` |
| Context pressure | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/rules/context-management.mdc` |

## Process

### Step -1b - Caveman Mode (Lite cap)
1. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/sdd/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full" }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/caveman/CAVEMAN.md`; apply **Lite** participation cap + prefs `caveman_level` (Lite skills never escalate); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) during the session.
5. Auto-Clarity + never-compress gates/drafts/paths per `CAVEMAN.md`.

### 1. Gate check

Report Step -1 checklist. Load `MEMORY-BANK.md` and `STORAGE.md`. **STOP** if unchecked.

### 2. Resolve target

1. Confirm **consumer** repo (not toolkit unless explicit).
2. Resolve storage with `$Workflow = classic` (`STORAGE.md`).
3. `bank_root`:
   - **repository** -> `$Cwd/memory-bank/`
   - **global** -> `<classic.path>/memory-bank/`
4. Never under `features/`.
5. Mode:
   - **create** if bank missing/incomplete
   - **refresh** if user asked or Step 0 marked stale
   - **refresh-light** if user asked or O3 Step N after code changes

### 3. Gitignore (repository only)

If `storage_mode` is **repository**: ensure SDD `.gitignore` block per `STORAGE.md` (**`/features/`** and safety-net patterns only — **do not** add or require `/memory-bank/`) **before** the first bank Write. Commit bank when product knowledge; never commit secrets.

If **global**: do **not** edit or suggest SDD patterns in the consumer `.gitignore`.

### 4. Confirm before write

Show (pt-BR): mode, full `bank_root`, files to create/update. Ask:

`Posso gravar o memory-bank em '{path}'? (sim / ajustar / cancelar)`

Write only after **sim**.

### 5. Inventory (read-only scan of consumer)

Prefer script (always scan `$Cwd`; write inventory under `bank_root`):

```powershell
.\scripts\inventory\Invoke-MemoryBankInventory.ps1 -RepoPath "<consumer>" -BankPath "<bank_root>" -AllowCreateInventory
```

If script path unavailable, run equivalent Glob/Grep from `reference.md` and write **only** under `<bank_root>/.inventory/`.

### 6. Scaffold or refresh files

| Mode | Action |
|------|--------|
| create | Copy templates from `templates/memory-bank/`; fill GENERATED regions + obvious fields from inventory/README/AGENTS |
| refresh | Re-run inventory; update GENERATED regions and `tech-stack.json`; preserve human prose outside markers |
| refresh-light | Re-run inventory; update GENERATED regions and `tech-stack.json` only; do not rewrite human prose sections; append history with `action: refresh-light`. If `caveman_mode` ON and narrative files are large, **offer** (do not auto-run) compact via `COMPACT.md` for `known-risks.md` / feature `CONTINUITY.md` after inventory. |

Rules:

- Preserve `<!-- BEGIN GENERATED: … -->` / `<!-- END GENERATED: … -->` discipline (`reference.md`)
- **No secrets** - env names / `***` only
- Evidence-based domain/architecture; unknowns -> `gaps.md`
- Phase 2 (`database-schema.md`, `api-contracts.md`, `component-catalog.md`): write from templates when relevant; if Prior/cited already has DDL/OpenAPI/UI map, those files are **BLOCKING** (promote immediately or `- [ ] BLOCKING:` until written)

### 7. Report + handoff

Report paths written, stack hints, blocking gaps (if any), storage mode.

Handoff examples:

```text
/orchestrate-analyze
/memory-bank-init - refresh
/memory-bank-init - refresh-light
```

## Must not

- Write application / test source
- Create bank under `features/NNN-slug/`
- Require external CLI tooling (uv, specify, Spec Kit installers)
- Skip confirm-before-write
- Dump entire bank into orchestrator parent context
- Auto-commit
- Edit consumer `.gitignore` when `storage_mode` is **global**
- Add or require `/memory-bank/` in `.gitignore`
- Commit secrets into the bank (keys, tokens, connection strings, raw `.env`)
- Leave phase 2 as gaps-only when Prior/cited already has DDL, OpenAPI, or a UI component map (those files are **BLOCKING** — write/promote or `- [ ] BLOCKING:`)
