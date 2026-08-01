---
name: orchestrate-develop
description: Forma C O3: one Task subagent per PLAN step (sdd-develop contract); parent never writes app code. Updates CONTINUITY; handoff to code-review. Use when invoking /orchestrate-develop.
---

## STOP - Read before ANY tool call

1. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/rules/guardrails.mdc`
2. Read `_shared/sdd-artifacts/SESSION.md`; load session-state for `$Cwd`
3. If the relevant gate is not approved: **STOP** - ask user **(pt-BR)** - do **NOT** Write/Shell
4. SDD/develop skills: after **ONE** step/task, **STOP** session - handoff only
5. This skill body is **English**; user-facing prompts may be **(pt-BR)**

### Step -1 - Gate check (report in chat before continuing)

```
Gate check:
[ ] guardrails.mdc read
[ ] SESSION.md read; session-state loaded
[ ] PIPELINE.md read (required for orchestrate-*)
[ ] User confirmed current action (sim)
-> If any unchecked: STOP
```

---

# Skill: orchestrate-develop

## Trigger

Invoke when the user asks for: `/orchestrate-develop`, `orchestrate develop`, `/orchestrate-develop`, or Forma C O3 after O2 handoff.

Required: full feature path **or** a specific `PLAN/PLAN_NNN_*.md` path under a story.

## Outcome

1. Pending PLAN step(s) executed via Task children when `subagents=native` (`SPAWN.md`), each following the **`sdd-develop` contract** (one PLAN step per child / session); when `subagents=none` or Task unavailable → **fallback** handoff to manual `/sdd-develop` (parent never writes app code; never hard-fail)
2. Feature `CONTINUITY.md` updated (phase `develop`, progress, typed next invoke, **Memory-bank** path + status)
3. Handoff to `code-review` (`- single` or `- multi-angle`; skill asks if omitted) and/or next step / next story

**Step 0 (required):** Memory Bank Gate (`MEMORY-BANK.md`, policy `auto`) **before** building the step queue / spawning children. Resolve `bank_root` via `STORAGE.md`. CONTINUITY stays the feature phase/handoff source.

**Step N (after code changes):** when at least one develop child succeeded with app file changes, run `memory-bank-init` mode **`refresh-light`** at `bank_root` before final handoff (`MEMORY-BANK.md` Step N). Confirm (pt-BR) first.

**Parent orchestrator never** writes application code, never marks multiple PLAN steps done in one child, and never bypasses `sdd-develop` gates (`step_confirmed`, tests before complete).

**Alternative (always valid):** user runs manual `/sdd-develop - <full-plan-path> - Step N` without this skill (RF05 / CA5). Manual Forma A does **not** require memory-bank (CA7).

## Lazy-load

| When | Path |
|------|------|
| Caveman Mode (if active) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/caveman/CAVEMAN.md` - **Full cap** |
| Pipeline Forma C, paths | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/sdd-artifacts/PIPELINE.md` |
| Storage | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/sdd-artifacts/STORAGE.md` |
| Step 0 Memory Bank Gate | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/sdd-artifacts/MEMORY-BANK.md` |
| Memory-bank create/refresh | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/memory-bank-init/SKILL.md` |
| Develop contract (source of truth) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/sdd-develop/SKILL.md` + `reference.md` |
| SESSION gates | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/sdd-artifacts/SESSION.md` |
| CONTINUITY template | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/templates/features/CONTINUITY.md` |
| Anti-bypass, parallelism, handoffs | `skills/orchestrate-develop/reference.md` |
| Spawn native vs fallback (capability `subagents`) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/agents/SPAWN.md` |
| Task subagent model (default omit; rare premium gate) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/agents/SUBAGENT-MODEL.md` |
| Code review (ask mode) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/code-review/SKILL.md` |
| Context pressure | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/rules/context-management.mdc` |

## Process

### Step -1b - Caveman Mode (Full cap)
1. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/sdd/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full" }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/caveman/CAVEMAN.md`; apply **Full** participation cap + prefs `caveman_level` (Lite skills never escalate); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) during the session.
5. Auto-Clarity + never-compress gates/drafts/paths per `CAVEMAN.md`.

### 1. Gate check

Report the Step -1 gate checklist in chat. Load `PIPELINE.md` (Forma C) and `SESSION.md`. **STOP** if any gate unchecked. Ask user **sim** before spawning the first develop child.

### 2. Resolve feature / PLAN set

Load `STORAGE.md` (`$Workflow = classic`). Resolve feature root and `bank_root` (repository vs global per `STORAGE.md` / `MEMORY-BANK.md`).

**Path sanitize (required):** normalize invoke paths; reject `..` and any resolved path outside `$Cwd/features/` (repository) or `<classic.path>/features/` (global). For a single PLAN path, it must remain under that features root. Ask again in pt-BR if invalid.

Repository mode: ensure SDD `.gitignore` per `STORAGE.md` before any bank write. **Global:** do not edit `.gitignore`.

| Invoke | Action |
|--------|--------|
| Feature path | Glob `**/PLAN/PLAN_*.md` under that feature; build story/PLAN queue |
| Single PLAN path | Work that PLAN only; still update feature `CONTINUITY.md` if present |
| Missing PLAN | **STOP** - suggest O2 or Forma A |

```text
Não encontrei PLAN sob `{path}`.

1) /orchestrate-deliver - <full-feature-path>
2) /sdd-plan - <full-prd-path>
3) cancelar
```

`Read` `FEATURE.md` + `CONTINUITY.md` when under a feature. Prefer O2-approved stories; if PLAN exists but approval unclear, ask once (pt-BR) before spawning.

### 3. Step 0 - Memory Bank Gate

Follow `MEMORY-BANK.md` (policy default **`auto`**). Bank root = resolved `bank_root` - **not** under `features/`.

Confirm (pt-BR) before create/refresh; healthy -> selective read only. Update CONTINUITY Memory-bank fields when create/refresh runs. Pass **`bank_path`** into every develop child prompt as read-only Prior context (selective files - never dump).

### 4. Build step queue (deps)

For each PLAN:

1. Parse pending steps (`⏳` / Status Pendente / unchecked).
2. Respect **Deps:** only enqueue a step when dependency steps are **Concluídos** / **Completed**.
3. Default order: one story at a time (finish story A before story B) unless user asks otherwise **and** stories are independent.

Present queue summary (pt-BR): story, PLAN path, next step id/title, deps. Confirm:

```text
Fila O3: próximo = `{plan-path}` Step {N} - {title}.

Posso spawnar o subagente (contrato sdd-develop)?
(sim / ajustar / cancelar)
```

Silence ≠ approval (RN01).

### 5. Spawn exactly one step child (CA5)

**SPAWN first:** load `SPAWN.md`; consult capability `subagents`. Prefer Task when `native`. If `subagents=none` or Task unavailable → **fallback** handoff to `/sdd-develop - <full-plan-path> - Step N` (note in CONTINUITY / chat) — never hard-fail; parent still must not write app code.

**Hard rule (native path):** one Task = one PLAN step = full `sdd-develop` contract.

**Model (`SUBAGENT-MODEL.md`):** omit Task `model` by default (inherit parent / Auto). Ask about a premium slug **only** for very hard PLAN steps per that contract; on **não** / silence, spawn without `model`. Never pick a costlier model alone.

Child must:

1. Load and follow `sdd-develop/SKILL.md` (gates, validate step, git branch, implement, tests, update PLAN, report)
2. Receive **only** that PLAN path + step number + lean Prior context paths (PRD, STORY, CONTINUITY, FEATURE, **`memory-bank/` path**) - not full guideline dumps or full bank body
3. Use **PLAN-scoped SESSION** per `SESSION.md` (`plan-{planHash}.json`, or `plan-{planHash}-step-{N}.json` when this spawn is parallel on the same PLAN)
4. Return: `{ planPath, step, status, files[], testsSummary, nextStep?, blockedReason? }`
5. **STOP** after that step - must not start Step N+1 in the same child

**Parent must not:**

- Edit `*.cs` / app sources / tests itself
- “Help finish” the child’s implementation
- Spawn a child with instructions to do Steps N and N+1
- Mark PLAN checkboxes for steps the child did not complete
- Skip `tests_run` / treat silence as step approval inside the child
- Share one flat `{repo-hash}.json` develop gate across parallel children

After child returns: parent updates `CONTINUITY.md` only (synthesis + paths; keep Memory-bank fields). Then either hand off to a **new chat** for the next step, or ask **sim** again before the next spawn in this conversation - never auto-chain without a gate.

### 6. Safe parallelism (optional)

Default: **serial** - one step in flight (lower context risk).

Parallel Task children **when all** of:

| Condition | Required |
|-----------|----------|
| Distinct PLAN files **or** PLAN explicitly marks steps as independent / parallel-safe | Yes |
| No shared files in step scopes (parent Grep/diff intent) | Yes |
| Deps of each parallel step already complete | Yes |
| User explicitly chose parallel after being asked | Yes |
| **Distinct develop session files** (PLAN-scoped, or PLAN+step when same PLAN) | Yes |

Ask (pt-BR) before any parallel spawn:

```text
Steps {A} e {B} parecem independentes. Executar em paralelo?
(sim / série / cancelar)
```

| Parallel case | Session file per child (`SESSION.md`) |
|---------------|----------------------------------------|
| Different PLANs | `sessions/{repoHash}/plan-{planHash}.json` each |
| Same PLAN, parallel-safe steps | `sessions/{repoHash}/plan-{planHash}-step-{N}.json` each |

Child prompt **must** include: `planPath`, `step`, `memoryBankPath` (read-only), and “load develop SESSION scoped per SESSION.md (PLAN or PLAN+step)”.

If unsure about file independence -> **série**. Concurrent parallel Task cap **≤4** per `SPAWN.md` (wave ≤4 or stay serial; do not invent a new cap). No git worktrees multi-US in MVP (RNF04). Parallelism is supported via scoped sessions - do **not** disable parallel as the only safe path. If `subagents=none` or Task unavailable → **fallback** serial handoff to manual `sdd-develop` (never hard-fail).

**Same-PLAN scope rule:** if any `plan-{planHash}-step-*.json` exists for the PLAN, every spawn for that PLAN (including later serial ones) **must** use PLAN+step session files - do not mix with `plan-{planHash}.json`.

### 7. Stop conditions

Stop spawning and emit handoff when any of:

| Event | Action |
|-------|--------|
| Story PLAN all steps complete | Offer next story or code-review |
| Feature all PLANs complete | Phase -> review; code-review handoff |
| Context pressure (TE02) | Persist CONTINUITY per `context-management.mdc`; resume invoke |
| Context hard-stop | Hard stop; new chat required |
| Child blocked / tests fail | Do not mark step done; report; wait for user |
| User **cancelar** | Leave CONTINUITY with pending next step |

Resume string:

```text
/orchestrate-develop - <full-feature-path>
```

Or per PLAN:

```text
/orchestrate-develop - <full-plan-path>
```

### 8. CONTINUITY

On each meaningful milestone (before/after child, pause, story done):

| Field | Rule |
|-------|------|
| **Phase** | `develop` (or `review` when all done) |
| **Last agent** | `orchestrate-develop` |
| **Memory-bank** | Path + status from Step 0 (`fresh` / `refreshed` / `created`) |
| **Estado atual** | Short per CONTINUITY template: active PLAN, last step done, next step |
| **Handoff tipado** | Exact next `/…` with **full paths** |

Do not paste full diffs, guideline bodies, or memory-bank body into CONTINUITY. CONTINUITY owns phase/handoff; bank does not replace it.

### 9. Step N - Memory Bank refresh-light (after code changes)

When this O3 run had at least one successful develop child that changed application files, **before** the final review handoff:

1. Resolve `bank_root` (same as Step 0).
2. Ask (pt-BR): `Posso atualizar o memory-bank (refresh-light) em '{bank_root}'? (sim / pular / cancelar)`
3. On **sim**: follow `memory-bank-init` mode **`refresh-light`** (inventory + GENERATED + `tech-stack.json` only).
4. Update CONTINUITY Memory-bank status to `refreshed` (or note skipped).
5. On **pular**: log and continue handoff without bank write.

If no app code changed this run, skip Step N.

### 10. Handoff - code-review + manual alternative

When a story or feature develop pass completes (or user asks to review mid-way):

```text
## Handoff O3 -> review

/code-review
/code-review - single
/code-review - multi-angle

## Continuar develop manual (alternativa a O3)
/sdd-develop - <full-plan-path> - Step {N}

## Continuar O3
/orchestrate-develop - <full-feature-path>

## Memory-bank (manual)
/memory-bank-init - refresh-light
```

Suggest `/code-review` (user may pass `- single` or `- multi-angle`; if omitted, **code-review asks**). Never require a mode. O3 does **not** auto-block the pipeline on review.

## Anti-bypass checklist (must enforce)

Parent and children **must not**:

- [ ] Parent implements application/production code or tests
- [ ] One child executes multiple PLAN steps
- [ ] Parent marks steps complete without child success + tests
- [ ] Skip SESSION / user **sim** for the next step spawn
- [ ] Share one flat `{repo-hash}.json` for `step_confirmed` / `tests_run` across parallel children (must use PLAN-scoped or PLAN+step files)
- [ ] Rewrite `sdd-develop` into a looser “fast path”
- [ ] Call `*-developer` from parent to implement the PLAN step (route only via sdd-develop contract in the child)
- [ ] Silence treated as approval

Full copy in `reference.md`.

## Must not

- Skip Step 0 Memory Bank Gate (unless explicit user `skip-memory-bank`)
- Create `memory-bank/` under `features/` or dump bank into CONTINUITY / child prompts
- Parent writes application/production code or tests
- Merge N PLAN steps into one Task / one session context
- Bypass or weaken `sdd-develop` one-step-per-session contract
- Auto-commit / auto-push
- Create external work-item tracker or org-only compliance content
- Force multi-angle code-review
- Introduce git worktrees for multi-US parallelism (MVP)
- Write new PRD/PLAN (O2 / sdd-spec / sdd-plan own that)
- Require memory-bank for manual Forma A `sdd-develop` (CA7)
- Pass Task `model` without `SUBAGENT-MODEL.md` gate + user **sim** (or user-named slug); ask model on routine PLAN steps
- Hard-fail when `subagents` is `none` or Task is unavailable (use **fallback** handoff to `/sdd-develop` per `SPAWN.md`)
- Exceed orchestrate ≤4 concurrent Tasks without user-approved wave/série (`SPAWN.md`)
- Paste guideline packs into Task child prompts

## Handoff

| Situation | Next |
|-----------|------|
| Next PLAN step | New chat -> `orchestrate-develop` **or** `sdd-develop - <plan> - Step N` |
| Story/feature done | `/code-review` (pass `- single` / `- multi-angle`, or let skill ask) |
| Missing PLAN | `orchestrate-deliver` / `sdd-plan` |
| Prefer no orchestrator | Manual `sdd-develop` only |

### Canonical strings

```text
/orchestrate-develop - <full-feature-path>
```

```text
/sdd-develop - <full-plan-path> - Step N
```

```text
/code-review
/code-review - multi-angle
```
