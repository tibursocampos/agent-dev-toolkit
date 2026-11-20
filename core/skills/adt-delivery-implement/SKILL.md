---
name: adt-delivery-implement
description: Execute one approved ADT delivery plan step by step or continuously, run final validation and the existing code review, and record the evidence. Use when invoking adt-delivery-implement (host examples /adt-delivery-implement, $adt-delivery-implement, use skill adt-delivery-implement) or when routed by adt-delivery-flow.
---

## STOP - Read before ANY tool call

Read `_shared/skill-boilerplate.md` first. It holds the guardrails read, the session gate rule, the user `sim` rule, the one-step rule, the gate check, and the user chat language rule. The steps below are skill-specific only.

Every file, comment, identifier, log line, child prompt and message this skill writes follows `{{TOOLKIT_ROOT}}/rules/ai-stealth.mdc`.

ADT exceptions to the Classic gates: this flow keeps one evolving `features/NNN-slug/PLAN.md`, one explicit plan approval (`{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/PLAN-LIFECYCLE.md`) instead of per-step `step_confirmed`, and its own cadence. The draft `PLAN.md` may be created and refined before approval. Everything else in the boilerplate still applies.

**Step 0 is blocking.** When run directly (not routed by `adt-delivery-flow` in this same run), run Step 0 first: `{{TOOLKIT_ROOT}}/skills/adt-delivery-flow/references/step0.md`. When routed, Step 0 was already done.

# Skill: adt-delivery-implement

## Trigger

Invoke `adt-delivery-implement` (host forms: `/adt-delivery-implement`, `$adt-delivery-implement`, `use skill adt-delivery-implement`).

**Negative signal:** applies as defined in `_shared/skill-boilerplate.md`; the skill-specific signals are listed below.
- Invoke when the operator asks to implement an approved ADT delivery plan, or when `adt-delivery-flow` routes to implementation after approval.

## Outcome

- Approved steps are implemented within planned paths; criterion tests exist for every acceptance criterion; `PLAN.md` Progress and Closeout hold status and evidence; final validation and the existing `adt-code-review` ran; `CODE-REVIEW.md` sits next to the plan.
- Nothing is committed, pushed, merged or published automatically.

Stage preconditions: Step 0 passed, ledger `plan=approved` and `Mode: full`, approval line present; checked in prose at Step 1, item 3.

## Terminal outcomes

Apply the shared `Flow terminal contract` in `skills/_shared/skills-catalog/CATALOG.md`, as mapped for this skill in `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/HANDOFF.md`: `done`, `blocked`, `failed`, `open_question`. Never report `done` without evidence.

## Flow contract: reads, writes, where, when

- **Reads:** the selected `PLAN.md` (and the feature-root primary plan for a split plan), its `Guidelines:` line, repository state, instructions.
- **Writes:** code and tests for the planned steps, the `PLAN.md` Operational record, and `CODE-REVIEW.md`.
- **Where:** the repository working tree and the feature directory.
- **When to use:** the plan has a valid approval; implement one approved plan.

## Lazy-load (only when needed)

| When | Path |
|------|------|
| Command playbook (step discovery after Step 0) | `{{TOOLKIT_ROOT}}/skills/adt-delivery-implement/references/command.md` |
| Language surfaces | `{{TOOLKIT_ROOT}}/skills/_shared/agents/LANGUAGE.md` |
| Caveman Mode (if active) | `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md` - **Full cap** |
| Plan check, branch, cadence, review mode, baseline | `{{TOOLKIT_ROOT}}/skills/adt-delivery-implement/references/start-choices.md` |
| Executing steps, child prompts, criterion tests, scope control | `{{TOOLKIT_ROOT}}/skills/adt-delivery-implement/references/execution.md` |
| Final validation, review, rerun, security pass, quality checks, AI-trace scan, report | `{{TOOLKIT_ROOT}}/skills/adt-delivery-implement/references/closeout.md` |
| Guideline map (only for a path the plan lacks) | `{{TOOLKIT_ROOT}}/skills/adt-delivery-refine/references/clarify.md` ("Guidelines to read") |
| Plan selection | `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/STORAGE-FEATURE.md` |
| Approval validity, amendment, resume | `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/PLAN-LIFECYCLE.md` |
| Progress table rows | `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/DISPLAY.md` |
| Terminal outcomes and handoff | `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/HANDOFF.md` |
| Final validation | `{{TOOLKIT_ROOT}}/skills/adt-run-tests/SKILL.md` |
| Final review | `{{TOOLKIT_ROOT}}/skills/adt-code-review/SKILL.md` |
| Domain skill named by a step (only that skill) | its own `SKILL.md` under `{{TOOLKIT_ROOT}}/skills/` |
| Memory-bank offer at the end | `{{TOOLKIT_ROOT}}/skills/adt-memory-bank/SKILL.md`; `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/MEMORY-BANK.md` |
| Delegating when available | `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md` |
| Selecting specialists when warranted | `{{TOOLKIT_ROOT}}/skills/_shared/agents/ROSTER.md` |

**Never by default:** do not preload `references/command.md` before the gates; load one reference per step.

## Process

After gates: **Read `references/command.md`** for ordered step discovery; then load one reference per step.

### Step -1b - Caveman Mode (Full cap)
1. Read `{{SDD_ROOT}}/preferences.json` (create `{ "caveman_mode": true, "caveman_level": "full", "orchestrator_mode": "adaptive", "artifact_language": null, "verify_mode": false }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md`; apply the **Full** participation cap with the prefs `caveman_level` (the cap never escalates); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) during the session; keep Auto-Clarity and never-compress gates per `CAVEMAN.md`.

### Step 1 - Select plan, check approval
1. Resolve storage and select the plan per `STORAGE-FEATURE.md`; an absent selected plan blocks implementation. Details: `references/start-choices.md`.
2. Confirm approval is still valid per `PLAN-LIFECYCLE.md`; material changes need renewed approval. Inspect branch, working tree, progress and evidence; on resume reconcile with the actual tree and preserve unrelated changes.
3. **Entry check (prose).** The Stage ledger of the selected plan reads `plan=approved`, `Mode: full` is recorded and the one-line approval note is present. If any is missing, report what is missing and stop. Otherwise set `Stage ledger` to `implement=in_progress` in the Operational record.

### Step 2 - Guidelines, choices and baseline
1. **Guidelines (mandatory, before the first edit).** Use `Guidelines:` in the plan's Evidence as an index. Resolve and read the references for the current scope, including when an earlier session listed them. Inspect the target repository's instructions and nearby conventions. Use `adt-delivery-refine/references/clarify.md` to find applicable references missing from the index. Pass only the applicable pointers to each child, which reads them for its own scope.
2. Ask the operator for branch (current or new, at each start), cadence (`step_by_step` or `continuous`), review mode (`single` or `multi-angle`), base and focus. Never infer from silence; reuse recorded cadence and review mode.
3. Record choices, observed branch and baseline (branch, HEAD, existing staged and unstaged changes) in `PLAN.md` per `references/start-choices.md`.
4. Draw the PLAN-step table at display point 1 (`DISPLAY.md`) before the first edit. When invoked by `adt-delivery-flow`, the flow's table is the only one drawn.

### Step 3 - Show progress and execute approved steps
1. Redraw the PLAN-step table at each display point of `DISPLAY.md` (never written into `PLAN.md`). Execute steps within planned paths per `references/execution.md`, delegating per `SPAWN.md` and `ROSTER.md` when warranted; child prompts follow `references/execution.md` ("Child prompts"). Children never edit `PLAN.md`.
2. Update `PLAN.md` after each step with status, evidence, blockers and next action. `step_by_step`: stop after each non-final step. `continuous`: run until complete or blocked. The last step proceeds directly to Step 4.

### Step 4 - Criterion tests and closeout
1. After the last approved step, write or adjust the criterion tests and record the `criterion -> test` map in Progress (`references/execution.md`, "Criterion tests").
2. Run the closeout in the order of `references/closeout.md`: criterion map, final validation (`adt-run-tests`), `adt-code-review` with the resolved plan path, review mode, focus, base and diff scope, rerun after review changes, security pass when needed, quality checks, and the AI-trace scan. Save findings in `CODE-REVIEW.md` next to the plan. Once that evidence is recorded, set `Stage ledger` to `implement=done`.

### Step 5 - Report, outcome and memory-bank offer
1. Report results, evidence and remaining limitations, never claiming completion without evidence; map the result to a terminal outcome per `HANDOFF.md`.
2. Memory-bank offer (last action, after the report): ask ONCE, in the user's chat language, whether to run `adt-memory-bank` on `bank_root` (`STORAGE-FEATURE.md`, "Memory bank root"): create when `memory-bank/` is absent, `refresh-light` when present. Options `confirm` / `skip` per `{{TOOLKIT_ROOT}}/skills/_shared/agents/QUESTIONS.md`. Wait for the answer. `confirm` runs `adt-memory-bank`; `skip` ends here. The offer does not change the outcome and is not a gate.

## Must not

- Start without a valid plan approval.
- Infer an answer from silence.
- Silently expand scope or touch an unplanned file or step, including a new test file outside the plan's paths.
- Let children edit `PLAN.md` (the coordinator is its only writer).
- Claim completion without evidence, or present failed, unavailable or partial validation or review as success.
- Commit, push, merge or publish automatically.
- Set `implement=done` before the validation, review and AI-trace evidence is recorded.
- Modify the `adt-run-tests` or `adt-code-review` skills (call them as other flows do).
- Fall back from global to local storage.
- Use cold reviewers (cold-critic, cold-reader) or impose a token budget.
- Write the chat progress table into `PLAN.md`.

## Handoff

| Situation | Next |
|-----------|------|
| Implement done | Report the result; commit, push and PR only on the operator's specific request (`adt-commit`, `adt-push`, `adt-open-github-pr`) |
| Blocked or failed | State the cause and the exact input or change that resolves it; no automatic retry of the same transition |
| Open question (branch, cadence, review mode, scope change, approval, memory-bank offer) | Ask once and wait |

Example, only when the operator asks for it: `adt-commit`. Paths in handoffs are portable: `features/NNN-slug/PLAN.md` (global: prefix `sdd/<repo-id>/`).
