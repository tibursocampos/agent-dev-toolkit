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

## Task child prompt skeleton

**SPAWN gate:** spawn Task only when `subagents=native`. Else **fallback** handoff — skip this skeleton.

Give each child:

1. Exact PLAN path + step number/title
2. Instruction: execute `/sdd-develop` contract for **this step only** - load `sdd-develop/SKILL.md`
3. Instruction: load develop SESSION scoped per `SESSION.md` - `plan-{planHash}.json`, or `plan-{planHash}-step-{N}.json` if this is a same-PLAN parallel spawn
4. Prior-context paths only (PRD, STORY, CONTINUITY, FEATURE, **`ARCH|SEC|ANALYSIS` when present**, **`memoryBankPath`**) - do not paste bodies; selective bank read only
5. Must stop after updating PLAN for this step; must run targeted tests before complete
5b. When level ≥ `cheap`: update `features/NNN-slug/EVD/` + `STATE.md` and run `validate-evidence` before Completed (**Verifier ≠ O3** — sequential only; do not spawn nested Task children for verification)
5c. When closing the feature wave: append `features/NNN-slug/TRACE.jsonl` living loop (**converge → sync_current → archive**) and run `validate-trace -RequireArchiveComplete` (**Verifier ≠ O3**; `TRACE-ARCHIVE-CONTRACT.md`)
6. Return: `{ planPath, step, status: done|blocked, files[], testsSummary, nextStep?, blockedReason? }`
7. Must not: other PLAN steps; weaken gates; skip tests; auto-commit unless user asked inside that child session; write develop gates to the flat repo session when PLAN path is known; write under `memory-bank/` unless this child is explicitly running memory-bank-init (normal develop children: read-only)

Parent: merge return -> CONTINUITY -> gate for next spawn.
