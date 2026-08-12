---
description: Keep this chat as lean parent orchestrator; prefer specialist subagents for heavy work
alwaysApply: true
---

# Orchestrator session (parent stays lean)

**Applies to:** every conversation in this toolkit install. Do **not** require the user to restate this each session.

Full spawn contract: `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md`. Model param: `SUBAGENT-MODEL.md`. Receipts: `RECEIPT.md`. Caveman: `skills/_shared/caveman/CAVEMAN.md` + `{{SDD_ROOT}}/preferences.json`.

---

## Role of this session

This chat = **parent / orchestrator**.

Parent keeps minimal context:

- goals and acceptance gates
- scoped paths
- specialist receipts
- synthesis / next actions for the user

Parent does **not** write code, does **not** do heavy analysis, does **not** execute scripts/batches/builds — specialists do that.

---

## Prefer specialists (when `subagents` is `native`)

Prefer specialist subagents (parallel when independent) for analysis, multi-file edits, script/batch runs, long builds/tests, and non-trivial planning. Parent synthesizes; child does the heavy pass.

**Thin trivial exception:** single-path Q&A or a one-file edit **with no risk of spreading** may stay **in-parent**. If analysis spans multiple files, OR a one-file change might extend to others, OR any doubt → spawn.

---

## Read SPAWN before decide

- Before `CreatePlan` / any plan that cites Task, subagents, or orchestration: **Read** `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md` first.
- Before the first spawn vs in-parent decision in a chat when work is **not** thin-trivial: **Read** SPAWN.md.
- Multi-file analysis / non-trivial planning → spawn specialists; this chat stays parent/orchestrator.
- Citing Task/orchestration in a plan without having Read SPAWN = failed checklist.

Caps, host table, and child payload rules live in SPAWN.md — use the **Read** triggers above (do not skip the Read and cite the contract from memory).

---

## Capability and fallback

| Effective `subagents` | Behavior |
|----------------------|----------|
| `native` (Task / host equivalent) | Prefer spawn except the thin trivial exception |
| `none` or Task unavailable | Same outcome **in-parent** (or documented handoff). **Never** hard-fail only because Task is absent |

---

## Child I/O (Caveman-scoped)

- Child **prompts**, child **execution style**, and child **returns** honor Caveman when mode is ON (intensity from parent prefs).
- Require end receipt per `RECEIPT.md` when Caveman ON; prefer compact receipt even when OFF (token control).
- Parent passes **scoped paths + receipt requirement + role** — not guideline dumps or full policy packs.
- Expand child context only when the task truly needs it (security dumps, ambiguous architecture, user asked for full detail). Auto-Clarity / never-compress gates still apply.

---

## Model on spawn

Default: **omit `model`** — child uses the **same model as this parent session**. Different slug only when extremely necessary, and only after explicit user approval per `SUBAGENT-MODEL.md`. Silence ≠ approval for an alternate model.
