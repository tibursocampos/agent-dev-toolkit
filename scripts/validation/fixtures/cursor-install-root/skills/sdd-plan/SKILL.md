---
name: sdd-plan
description: Create a baby-step PLAN from an existing PRD (agent PLAN .md; language per LANGUAGE.md + preferences). Feeds sdd-develop. Use when creating a plan or invoking /sdd-plan.
---

## STOP - Read before ANY tool call

1. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/rules/guardrails.mdc`
2. Read `_shared/sdd-artifacts/SESSION.md`; load session-state for `$Cwd`
3. If the relevant gate is not approved: **STOP** - ask user **(pt-BR)** - do **NOT** Write/Shell
4. SDD/develop skills: after **ONE** step/task, **STOP** session - handoff only
5. This skill body is **English**; user-facing prompts may be **(pt-BR)**

### Step -1 - Gate check (report in chat before continuing)

```
Gate check:
[ ] guardrails.mdc read
[ ] SESSION.md read; session-state loaded
[ ] PIPELINE.md read (SDD skills only)
[ ] User confirmed current action (sim)
-> If any unchecked: STOP
```

---

# Skill: sdd-plan

## Trigger

Invoke when the user asks for: `/sdd-plan`, `create plan`, `execution plan`.

## Outcome

A **PLAN** in the **user chat language** (or `preferences.json` / manifest `artifact_language` when set) at a **canonical** path under `features/NNN-slug/USnn/PLAN/PLAN_NNN_*.md` (same story as the PRD; global under `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/sdd/<repo-id>/features/...`). Root/flat `PLAN/` is **not** a valid Classic SDD path. Same `NNN` as PRD. Each step = one `sdd-develop` session. Paths and test names in **English**; no code blocks. Include **## Execution policy** from `templates/sdd/PLAN.md` (orchestrator mode, parent/child validation, handoff).

**PLAN magro:** do not paste SQL/DDL/JSON/OpenAPI into the PLAN. Refuse to omit those bodies from PLAN **unless** the canonical path already exists (bank phase 2 `database-schema.md` / `api-contracts.md` / `component-catalog.md`, or story `ARCH/` / `ANALYSIS/`). If missing, O1/O2 must create the canonical file first; PLAN only **cites the path**.

## Lazy-load (only when needed)

| When | Path |
|------|------|
| Pipeline guards, missing PRD dialog | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/skills/_shared/sdd-artifacts/PIPELINE.md` |
| Storage, manifest, `.gitignore` | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/skills/_shared/sdd-artifacts/STORAGE.md` |
| Selective retrieval (`SR-NO-FULL-DUMP`) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/skills/_shared/sdd-artifacts/SELECTIVE-RETRIEVAL.md` |
| PLAN document template | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/skills/_shared/templates/sdd/PLAN.md` |
| Caveman Mode (if active) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/skills/_shared/caveman/CAVEMAN.md` - **Lite cap** |
| SDD language, context, .NET | `sdd-artifact-language-pt-br.mdc`, `context-management.mdc`, `dotnet-guidelines/*.md` |
| Language surfaces (chat vs spawn) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/skills/_shared/agents/LANGUAGE.md` |

## Process

### Step -1b - Caveman Mode (Lite cap)
1. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/sdd/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full", "orchestrator_mode": "always", "artifact_language": null }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/skills/_shared/caveman/CAVEMAN.md`; apply **Lite** participation cap + prefs `caveman_level` (Lite skills never escalate); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) during the session.
5. Auto-Clarity + never-compress gates/drafts/paths per `CAVEMAN.md`.

### -1. Pipeline and mode

Load `STORAGE.md` and `PIPELINE.md`. Use `STORAGE.md` schema v2 and run the dynamic storage resolution algorithm with parameter `$Workflow = classic`. Resolve `storage_mode` and `path` for the active repository. If this is the first run for the repository, execute storage mode selection and persist it in `manifest.json`.
Phase A/B as for `sdd-spec`. No PRD authoring; no production/test code.

### 0. Workspace

Target repo. Read `AGENTS.md` / `README.md` if present.

### 1. Resolve PRD

Glob canonical PRDs under `features/**/PRD/` only (workspace + global feature root). Do **not** resolve or execute against root/flat `PRD/` or `docs/PRD/`.

| Situation | Action |
|-----------|--------|
| User gave canonical PRD path (must be `features/.../PRD/` or global `.../features/.../PRD/`) | `Read`; validate status **Pronto para planejamento** / **Ready for planning** |
| No canonical PRD | `PIPELINE.md` section `sdd-plan` without PRD - options 1 or 2; then collect text or file path |
| "Criar PRD" | Choice **1** -> hand off to `sdd-spec` inputs; do not write PLAN until PRD exists (unless user chose **2**) |
| Non-canonical `.md` (root `PRD/`, `docs/PRD/`, etc.) | Promote under `features/...` via `sdd-spec` or ask for a canonical feature path |
| PRD under feature story | Load Prior context siblings (`PIPELINE.md` § Feature / story siblings) |

Summarize PRD (**cite portable path** — **must not** paste the full PRD body into chat dumps, PLAN, or child prompts; `SELECTIVE-RETRIEVAL.md` / `SR-NO-FULL-DUMP`). Ask to proceed.

### 2-4. Explore, technical questions (<=10), baby steps

Glob/Grep/Read (selective bank paths only — **never dump** entire `memory-bank/`). Steps ~20-45 min each. Map every PRD **REQ-NNN** into **Mapa REQ → passo**. Challenge vague Aceite ("as expected", "funciona"). Doc-update steps: **sdd-develop** asks doc language.

### 5. Context checkpoint

`context-management.mdc`; PLAN draft in chat if >=40%.

### 5.5 PLAN storage

`STORAGE.md`; global PLAN if PRD is global; else manifest or prompt.

### 5.75 Confirm before write

`PIPELINE.md` section Confirm before write - `PLAN_NNN_*`, **portable path** (`STORAGE.md` § Portable path), PRD link, step count. **sim** required before `Write` in Agent. Confirm chat may show OS absolute; artifact Writes use portable paths only.

### 6. Write PLAN (Agent + sim only)

1. Validate canonical PLAN path under same story as PRD (`features/.../PLAN/`); `NNN` **equals** PRD `NNN`. Do **not** write or update PLANs at repo-root `PLAN/`.
2. Repository mode: `.gitignore` per `STORAGE.md` (include `/features/`; keep `/PRD/` `/PLAN/` as safety net only; **do not** add `/memory-bank/` — commit bank when product knowledge; never commit secrets). Global mode: do **not** edit `.gitignore`.
3. Body from `templates/sdd/PLAN.md` (authoring rules in `reference.md`); include **## Execution policy**; PRD header = **portable path** to PRD (`STORAGE.md` § Portable path); steps **Pendente**; `0/N`; REQ→step map complete.
4. **PLAN magro:** if the PLAN would omit SQL/DDL/JSON/OpenAPI, the canonical path (bank phase 2 or `ARCH/` / `ANALYSIS/`) **must already exist**; if missing, **STOP** — O1/O2 creates that file first; PLAN cites the path only.
5. Warn if overwriting PLAN with completed steps.

### 6.5 Structural validate before advance

After a successful `Write`, run structural **`validate-plan`** (and prefer a prior **`validate-prd`** on the source PRD) before handoff:

```
.\scripts\validation\validate-prd.ps1 -Path <source-prd-path>
.\scripts\validation\validate-plan.ps1 -Path <written-plan-path> -PrdPath <source-prd-path>
```

Exit ≠ 0 → **STOP**; fix REQ→step coverage (or PRD structure); re-run until exit 0. Do **not** advance to `/sdd-develop` on failure. Enforcement smoke: `Assert-ValidatePrdPlan.ps1`.

### 7. Validate with user

Present steps, deps, risks. Confirm first sdd-develop step.

## Must not

- Write PLAN in a language other than user chat / `artifact_language` without override; embed implementation code
- Omit SQL/DDL/JSON/OpenAPI from PLAN when no canonical path exists (bank phase 2 or `ARCH/` / `ANALYSIS/`) — O1/O2 must create that file first; PLAN then cites the path
- Paste SQL/DDL/JSON/OpenAPI into PLAN when a canonical path already exists (cite the path only — PLAN magro)
- Create or overwrite PRD; sdd-develop or commit here
- Write PLAN without canonical PRD (except explicit user choice **2** with specs)
- Skip confirm-before-write; claim PLAN saved without `Write`
- `NNN` mismatch vs PRD; new writes outside `features/.../PLAN/`
- Do not dump entire `memory-bank/` or paste full PRD into PLAN/prompts (`SELECTIVE-RETRIEVAL.md` / `SR-NO-FULL-DUMP`)
- Do not omit REQ→step coverage or ship vague Aceite without challenge
- Do not hand off to `sdd-develop` when `validate-plan` (or `validate-prd` on the source) exits ≠ 0
- Write SDD artifacts containing OS absolute paths matching `^[A-Za-z]:/` or user-home InstallRoot embeds (`…/.cursor/sdd/…`, `…/.claude/sdd/…`) — use portable paths per `STORAGE.md` § Portable path

## Handoff

```
/sdd-develop - features/NNN-slug/US01/PLAN/PLAN_NNN_slug.md - Step 1
```

(Global: prefix with `sdd/<repo-id>/` — portable path relative to InstallRoot.)

One session = one PLAN step.
