# orchestrate-develop - reference

Anti-bypass checklist, step queue, safe parallelism, CONTINUITY, Task child prompt, and handoffs for `skills/orchestrate-develop/SKILL.md`. Keep `SKILL.md` lean.

---

## Preconditions checklist

- [ ] Gate check reported; user **sim** for this O3 run / next spawn
- [ ] Feature and/or PLAN path resolved (`STORAGE.md`, classic)
- [ ] **Step 0** Memory Bank Gate done (`auto`; explicit `skip-memory-bank` only to bypass)
- [ ] At least one `features/**/PLAN/PLAN_*.md` under story folders (or global `.../features/**/PLAN/`)
- [ ] Next step deps **Completed** / **Concluídos**
- [ ] Parent will **not** implement app code
- [ ] Child prompts include `memoryBankPath` (read-only, selective)

If no PLAN -> hand off to O2 / `sdd-plan`. If user prefers no orchestrator -> document manual `sdd-develop` and stop (Forma A: no memory-bank gate - CA7).

---

## Step 0 - Memory Bank Gate (CA4 / CT3)

| Check | Pass |
|-------|------|
| Bank path | Resolved `bank_root` (`STORAGE.md`) - not under `features/` |
| Fresh healthy bank | No rewrite; CONTINUITY status `fresh` |
| Refresh this run | CONTINUITY status `refreshed` |
| Children | Receive bank path; selective read; no bank dump |
| CONTINUITY vs bank | CONTINUITY = phase/handoff; bank = workspace map |
| 1-step contract | Unchanged - one child = one PLAN step |

## Step N - refresh-light (after code changes)

| Check | Pass |
|-------|------|
| Trigger | At least one child changed app files this O3 run |
| Mode | `memory-bank-init` **`refresh-light`** only (not full prose rewrite) |
| Confirm | pt-BR `sim` / `pular` / `cancelar` before write |
| Skip | No code changes, or user chose `pular` |
| CONTINUITY | Status `refreshed` when Step N ran |

---

## Anti-bypass checklist (CA5) - copy into enforcement

Use before every spawn and before marking any step done.

| # | Rule | Violates if |
|---|------|-------------|
| 1 | Parent writes **no** app/test source | Parent `Write`/`Edit` on `*.cs`, `*.tsx`, migrations, etc. |
| 2 | One Task = **one** PLAN step | Child prompt lists Steps N and N+1 |
| 3 | Child follows full `sdd-develop` contract | “Quick implement without gates/tests” |
| 4 | Tests before complete | PLAN marked done with failing/skipped tests |
| 5 | User **sim** before next spawn | Auto-chain N steps after one **sim** |
| 6 | Silence ≠ approval | Proceeding without explicit **sim** |
| 7 | Manual `sdd-develop` always allowed | Skill claims O3 is mandatory |
| 8 | No contract fork | Parallel undocumented “O3 implement” process |
| 9 | No `*-developer` from parent for PLAN steps | Parent implements via stack skill instead of child sdd-develop |
| 10 | CONTINUITY only in parent after child | Parent pastes full diffs as “implementation” |

Any violation -> **STOP**, fix process, do not mark step complete.

---

## Step queue algorithm

```text
1. Collect PLANs under feature (or single PLAN from invoke).
2. For each PLAN, list steps with status + deps.
3. Ready set = pending steps whose deps are all completed.
4. Default pick = first ready in PLAN order within current story.
5. Present pick; wait for sim; spawn one child.
6. On success: refresh queue; update CONTINUITY; ask sim for next OR hand off new chat.
7. On failure: keep step pending; report blockedReason; do not advance.
```

Story preference: finish one story’s PLAN before starting another unless user explicitly reorders and deps allow.

---

## Safe parallelism rules

Parallel O3 is **supported**. Root cause of gate races is fixed by PLAN-scoped (or PLAN+step) develop sessions in `SESSION.md` - not by disabling parallel, not by worktrees.

| Allowed | Not allowed |
|---------|-------------|
| Two ready steps on **different** PLANs with disjoint file scopes + distinct `plan-{hash}.json` + user **sim** | Two children sharing one flat `{repo-hash}.json` for `step_confirmed` / `tests_run` |
| Same PLAN steps marked parallel-safe + disjoint files + `plan-{hash}-step-{N}.json` each | Guessing independence without asking |
| Serial default when unsure; **cap 4** concurrent children (wave if more) | Worktrees / multi-checkout for multi-US (out of MVP) |
| After any `plan-{hash}-step-*.json` exists for a PLAN, keep using PLAN+step for that PLAN | Mixing `plan-{hash}.json` and `plan-{hash}-step-N.json` on the same PLAN |

Ask before parallel:

```text
Steps {A} e {B} parecem independentes. Executar em paralelo?
(sim / série / cancelar)
```

Each child prompt must include `planPath`, `step`, Prior-context paths (`ARCH|SEC|ANALYSIS` when present), and instruction to use the matching scoped SESSION file.

---

## Contract reuse (RN05)

| Concern | Source of truth |
|---------|-----------------|
| One step per session | `sdd-develop/SKILL.md` |
| PLAN update protocol | `sdd-develop/reference.md` |
| SESSION gates | `SESSION.md` (repo + PLAN-scoped develop) + guardrails |
| Branch rules | `branch-validation.mdc` via sdd-develop |
| Native Task vs **fallback** | `SPAWN.md` (capability `subagents`; never hard-fail) |

O3 **orchestrates invocation**; it does **not** replace those documents. When `subagents=none` or Task unavailable → **fallback** handoff to manual `/sdd-develop` (parent never writes app code).

---

## Task child prompt skeleton

**SPAWN gate:** spawn Task only when `subagents=native`. Else **fallback** handoff — skip this skeleton.

Give each child:

1. Exact PLAN path + step number/title
2. Instruction: execute `/sdd-develop` contract for **this step only** - load `sdd-develop/SKILL.md`
3. Instruction: load develop SESSION scoped per `SESSION.md` - `plan-{planHash}.json`, or `plan-{planHash}-step-{N}.json` if this is a same-PLAN parallel spawn
4. Prior-context paths only (PRD, STORY, CONTINUITY, FEATURE, **`ARCH|SEC|ANALYSIS` when present**, **`memoryBankPath`**) - do not paste bodies; selective bank read only
5. Must stop after updating PLAN for this step; must run targeted tests before complete
6. Return: `{ planPath, step, status: done|blocked, files[], testsSummary, nextStep?, blockedReason? }`
7. Must not: other PLAN steps; weaken gates; skip tests; auto-commit unless user asked inside that child session; write develop gates to the flat repo session when PLAN path is known; write under `memory-bank/` unless this child is explicitly running memory-bank-init (normal develop children: read-only)

Parent: merge return -> CONTINUITY -> gate for next spawn.

---

## CONTINUITY checklist

Update when:

- [ ] Queue presented / mode (série default)
- [ ] After each child returns
- [ ] Story complete / feature complete
- [ ] Context ≥40% pause
- [ ] Before code-review handoff

| Field | Rule |
|-------|------|
| **Phase** | `develop` until all planned work done -> `review` |
| **Last agent** | `orchestrate-develop` |
| **Memory-bank** | Path + status from Step 0 |
| **Estado atual** | ≤10 lines |
| **Handoff tipado** | Portable path `/…` (`STORAGE.md` § Portable path) |
| **What not to write** | Full code diffs, guideline dumps, memory-bank body |

---

## Example - serial two steps then review

Feature: `features/004-nuget-extract/`  
PLAN: `features/004-nuget-extract/TS01/PLAN/PLAN_004_nuget_package.md`

```text
## O3 run

1) sim -> Task(sdd-develop Step 1) -> CONTINUITY update
2) new chat or sim -> Task(sdd-develop Step 2) -> …
3) TS01 complete -> handoff:

/code-review
/code-review - single
/code-review - multi-angle

# Manual alternative anytime:
/sdd-develop - features/004-nuget-extract/TS01/PLAN/PLAN_004_nuget_package.md - Step 3
```

---

## Handoff copy (pt-BR / strings)

```text
## Handoff O3 -> review

/code-review
/code-review - single
/code-review - multi-angle

## Continuar develop manual (alternativa a O3)
/sdd-develop - <portable-plan-path> - Step {N}

## Continuar O3
/orchestrate-develop - <portable-feature-path>
```

Handoff `/code-review` (user may pass `- single` / `- multi-angle`; if omitted, skill asks). Never required; does not auto-block pipeline.

---

## Boundaries

| Aspect | O2 | O3 | Manual `sdd-develop` |
|--------|----|----|----------------------|
| Writes | PRD/PLAN | CONTINUITY + spawns implementers | Code + PLAN progress |
| App code | No | Children only | Yes (the skill itself) |
| Steps per session | N/A | **One** per child | **One** |
| Required? | After O1 for Forma C | **Optional** | Always valid |

---

## Canonical invoke strings

```text
/orchestrate-develop - <portable-feature-path>
```

```text
/orchestrate-develop - <portable-plan-path>
```

```text
/sdd-develop - <portable-plan-path> - Step N
```

```text
/code-review
/code-review - single
/code-review - multi-angle
```

```text
/orchestrate-deliver - <portable-feature-path>
```

---

## Process — Caveman (Full cap)

1. Read `{{SDD_ROOT}}/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full" }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md`; apply **Full** participation cap + prefs `caveman_level` (Lite skills never escalate); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) during the session.
5. Auto-Clarity + never-compress gates/drafts/paths per `CAVEMAN.md`.

---

## Process — Resolve feature / PLAN set

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

1) /orchestrate-deliver - <portable-feature-path>
2) /sdd-plan - <portable-prd-path>
3) cancelar
```

`Read` `FEATURE.md` + `CONTINUITY.md` when under a feature. Prefer O2-approved stories; if PLAN exists but approval unclear, ask once (pt-BR) before spawning.

---

## Process — Build step queue

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

Silence ≠ approval (RN01). See also § Step queue algorithm.

---

## Process — Spawn one step child (CA5)

**SPAWN first:** load `SPAWN.md`; consult capability `subagents`. Prefer Task when `native`. If `subagents=none` or Task unavailable → **fallback** handoff to `/sdd-develop - <portable-plan-path> - Step N` (note in CONTINUITY / chat) — never hard-fail; parent still must not write app code.

**Hard rule (native path):** one Task = one PLAN step = full `sdd-develop` contract.

**Model (`SUBAGENT-MODEL.md`):** omit Task `model` by default (inherit parent / Auto). Ask about a premium slug **only** for very hard PLAN steps per that contract; on **não** / silence, spawn without `model`. Never pick a costlier model alone.

Child must:

1. Load and follow `sdd-develop/SKILL.md` (gates, validate step, git branch, implement, tests, update PLAN, report)
2. Receive **only** that PLAN path + step number + lean Prior context paths (PRD, STORY, CONTINUITY, FEATURE, **`ARCH|SEC|ANALYSIS` when present**, **`memory-bank/` path**) - not full guideline dumps or full bank body
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

See also § Task child prompt skeleton + § Anti-bypass checklist.

---

## Process — Safe parallelism (optional)

Default: **serial** - one step in flight (lower context risk).

Parallel Task children **when all** of:

| Condition | Required |
|-----------|----------|
| Distinct PLAN files **or** PLAN explicitly marks steps as independent / parallel-safe | Yes |
| No shared files in step scopes (parent Grep/diff intent) | Yes |
| Deps of each parallel step already complete | Yes |
| User explicitly chose parallel after being asked | Yes |
| **Distinct develop session files** (PLAN-scoped, or PLAN+step when same PLAN) | Yes |

Ask (pt-BR) before any parallel spawn — copy in § Safe parallelism rules.

| Parallel case | Session file per child (`SESSION.md`) |
|---------------|----------------------------------------|
| Different PLANs | `sessions/{repoHash}/plan-{planHash}.json` each |
| Same PLAN, parallel-safe steps | `sessions/{repoHash}/plan-{planHash}-step-{N}.json` each |

Child prompt **must** include: `planPath`, `step`, `memoryBankPath` (read-only), Prior-context paths including `ARCH|SEC|ANALYSIS` when present, and “load develop SESSION scoped per SESSION.md (PLAN or PLAN+step)”.

If unsure about file independence -> **série**. Concurrent parallel Task cap **≤4** per `SPAWN.md` (wave ≤4 or stay serial; do not invent a new cap). No git worktrees multi-US in MVP (RNF04). Parallelism is supported via scoped sessions - do **not** disable parallel as the only safe path. If `subagents=none` or Task unavailable → **fallback** serial handoff to manual `sdd-develop` (never hard-fail).

**Same-PLAN scope rule:** if any `plan-{planHash}-step-*.json` exists for the PLAN, every spawn for that PLAN (including later serial ones) **must** use PLAN+step session files - do not mix with `plan-{planHash}.json`.

See also § Safe parallelism rules.

---

## Process — Stop conditions

Stop spawning and emit handoff when any of:

| Event | Action |
|-------|--------|
| Story PLAN all steps complete | Offer next story or code-review |
| Feature all PLANs complete | Phase -> review; code-review handoff |
| Context pressure (TE02) | Persist CONTINUITY per `context-management.mdc`; resume invoke |
| Context hard-stop | Hard stop; new chat required |
| Child blocked / tests fail | Do not mark step done; report; wait for user |
| User **cancelar** | Leave CONTINUITY with pending next step |

Resume strings: § Canonical invoke strings.

---

## Process — CONTINUITY fields

On each meaningful milestone (before/after child, pause, story done):

| Field | Rule |
|-------|------|
| **Phase** | `develop` (or `review` when all done) |
| **Last agent** | `orchestrate-develop` |
| **Memory-bank** | Path + status from Step 0 (`fresh` / `refreshed` / `created`) |
| **Estado atual** | Short per CONTINUITY template: active PLAN, last step done, next step |
| **Handoff tipado** | Exact next `/…` with **portable paths** (`STORAGE.md` § Portable path) |

Do not paste full diffs, guideline bodies, or memory-bank body into CONTINUITY. CONTINUITY owns phase/handoff; bank does not replace it.

See also § CONTINUITY checklist.

---

## Process — Step N refresh-light

When this O3 run had at least one successful develop child that changed application files, **before** the final review handoff:

1. Resolve `bank_root` (same as Step 0).
2. Ask (pt-BR): `Posso atualizar o memory-bank (refresh-light) em '{bank_root}'? (sim / pular / cancelar)`
3. On **sim**: follow `memory-bank-init` mode **`refresh-light`** (inventory + GENERATED + `tech-stack.json` only).
4. Update CONTINUITY Memory-bank status to `refreshed` (or note skipped).
5. On **pular**: log and continue handoff without bank write.

If no app code changed this run, skip Step N. See also § Step N - refresh-light.

---

## Must not (full)

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
- Write SDD artifacts containing OS absolute paths matching `^[A-Za-z]:/` or user-home InstallRoot embeds (`…/.cursor/sdd/…`, `…/.claude/sdd/…`) — use portable paths per `STORAGE.md` § Portable path

---

## Explicit exclusions

- Parent implementation of app/test code
- Multi-step children or auto-chained steps without **sim**
- Forked develop process that skips sdd-develop gates
- Mandatory multi-angle review
- Git worktrees for multi-US
- external work-item tracker or org-only compliance content
- Spec Kit / `.specify` (removed from toolkit - use Formas A/B/C)
- Weakening `sdd-develop` one-step contract
