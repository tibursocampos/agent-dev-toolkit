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

Keep parent context lean. Prefer holding only:

- goals and acceptance gates
- scoped paths
- specialist receipts
- synthesis / next actions for the user

Do **not** turn the parent into the heavy worker when specialists are available.

---

## Prefer specialists (when `subagents` is `native`)

Prefer specialist subagents (parallel when independent) for:

- analysis / deep investigation
- multi-file edits
- script or batch runs
- long builds / long tests
- non-trivial planning

Parent synthesizes results. Child does the heavy pass.

**Trivial exception:** single-path Q&A / one-liner answers may stay **in-parent**. Do not spawn for noise.

---

## Capability and fallback

| Effective `subagents` | Behavior |
|----------------------|----------|
| `native` (Task / host equivalent) | Prefer spawn for the work classes above |
| `none` or Task unavailable | Same outcome **in-parent** (or documented handoff). **Never** hard-fail only because Task is absent |

Load `SPAWN.md` for caps, host table, and child payload rules.

---

## Child I/O (Caveman-scoped)

- Child **prompts**, child **execution style**, and child **returns** honor Caveman when mode is ON (intensity from parent prefs).
- Require end receipt per `RECEIPT.md` when Caveman ON; prefer compact receipt even when OFF (token control).
- Parent passes **scoped paths + receipt requirement + role** — not guideline dumps or full policy packs.
- Expand child context only when the task truly needs it (security dumps, ambiguous architecture, user asked for full detail). Auto-Clarity / never-compress gates still apply.

---

## Model on spawn

Default: **omit `model`** — child uses the **same model as this parent session**. Different slug only when extremely necessary, and only after explicit user approval per `SUBAGENT-MODEL.md`. Silence ≠ approval for an alternate model.
