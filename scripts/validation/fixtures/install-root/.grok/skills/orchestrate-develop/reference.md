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

If no PLAN -> hand off to O2 / `sdd-plan`. If user prefers no orchestrator -> document manual `sdd-develop` and stop (Classic SDD: no memory-bank gate - CA7).

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

Each child prompt must include `planPath`, `step`, and instruction to use the matching scoped SESSION file.

---

## Contract reuse (RN05)

| Concern | Source of truth |
|---------|-----------------|
| One step per session | `sdd-develop/SKILL.md` |
| PLAN update protocol | `sdd-develop/reference.md` |
| SESSION gates | `SESSION.md` (repo + PLAN-scoped develop) + guardrails |
| Branch rules | `branch-validation.mdc` via sdd-develop |

O3 **orchestrates invocation**; it does **not** replace those documents.

---

## Task child prompt skeleton

Give each child:

1. Exact PLAN path + step number/title
2. Instruction: execute `/sdd-develop` contract for **this step only** - load `sdd-develop/SKILL.md`
3. Instruction: load develop SESSION scoped per `SESSION.md` - `plan-{planHash}.json`, or `plan-{planHash}-step-{N}.json` if this is a same-PLAN parallel spawn
4. Prior-context paths only (PRD, STORY, CONTINUITY, FEATURE, **`memoryBankPath`**) - do not paste bodies; selective bank read only
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
| **Handoff tipado** | Full path `/…` |
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
/sdd-develop - <full-plan-path> - Step {N}

## Continuar O3
/orchestrate-develop - <full-feature-path>
```

Handoff `/code-review` (user may pass `- single` / `- multi-angle`; if omitted, skill asks). Never required; does not auto-block pipeline.

---

## Boundaries

| Aspect | O2 | O3 | Manual `sdd-develop` |
|--------|----|----|----------------------|
| Writes | PRD/PLAN | CONTINUITY + spawns implementers | Code + PLAN progress |
| App code | No | Children only | Yes (the skill itself) |
| Steps per session | N/A | **One** per child | **One** |
| Required? | After O1 for Orchestrated Delivery | **Optional** | Always valid |

---

## Canonical invoke strings

```text
/orchestrate-develop - <full-feature-path>
```

```text
/orchestrate-develop - <full-plan-path>
```

```text
/sdd-develop - <full-plan-path> - Step N
```

```text
/code-review
/code-review - single
/code-review - multi-angle
```

```text
/orchestrate-deliver - <full-feature-path>
```

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
