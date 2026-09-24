---
description: SDD pipeline order, canonical PRD/PLAN paths, confirm-before-write, Plan/Ask vs Agent phases
alwaysApply: true
---

# SDD pipeline guards

Full detail: `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/skills/_shared/sdd-artifacts/PIPELINE.md` (load when running `sdd-spec`, `sdd-plan`, or `sdd-develop`).

## Operator track choice

Three tracks coexist — **none is a prerequisite for another**. Classic SDD (`sdd-spec` → `sdd-plan` → `sdd-develop`) is valid without `orchestrate-analyze`. The operator may invoke `/sdd-spec` or `/sdd-plan` directly from chat, Plan mode, `.cursor/plans/`, or prior manual analysis. Do **not** block or redirect to Orchestrated Delivery unless the operator chooses it or `invocation_context` is `orchestrated` and O2 gates apply.

## Order

- **Classic SDD**: `sdd-spec` -> `sdd-plan` -> `sdd-develop`. Do not create a PLAN without a canonical PRD (unless "PLAN direto"). Do not implement without a canonical PLAN.
- **Orchestrated Delivery**: `orchestrate-analyze` -> `orchestrate-deliver` -> (`orchestrate-develop` \| `sdd-develop`) after human gates.

## Canonical paths only

### Classic SDD (writes and execution)

- PRD: `features/NNN-slug/USnn/PRD/NNN_*.md` (default story `US01`) or global under `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/sdd/<repo-id>/features/...`.
- PLAN: `features/NNN-slug/USnn/PLAN/PLAN_NNN_*.md` or global equivalent. PLAN `NNN` matches PRD.
- Numbering (`NNN`): from `features/*/` only (workspace + global feature root).
- Root/flat `PRD/` / `PLAN/` / `docs/PRD/` / `docs/PLAN/`: **not** valid Classic SDD paths - do not read, write, or update-in-place for execution. Keep those patterns in `.gitignore` **only as a safety net** (`STORAGE.md`).
- **Portable path cites:** versioned SDD Writes and embedded links use portable paths only (`STORAGE.md` § Portable path). Chat confirmations may show OS absolute paths for the operator; never bake `^[A-Za-z]:/` or InstallRoot home embeds into artifact bodies.

Never save **new** SDD artifacts under `docs/backlog/` or ad-hoc `docs/*.md` for canonical SDD. Prefer feature tree for Backlog Refine stories (`STORY.md`); `docs/backlog/` is a shortcut only.

**Promote (scope by `invocation_context` — `INVOCATION-CONTEXTS.md`):**

- **`direct`** (`sdd-spec` / `sdd-plan` slash): cited `.md` outside `features/` (including `.cursor/plans/`) → `PIPELINE.md` § Classic PRD/PLAN promote: `Read` → synthesize → confirm → `Write` under `features/...`. Do **not** require `orchestrate-analyze` first.
- **`orchestrated`** (O1/O2): mandatory promote before backlog **sim**; pointer-only = fail O1.

**Required siblings (scope by context):**

- **`orchestrated` (O2):** if FEATURE `needs_*` (or brownfield) and matching `ANALYSIS/` / `ARCH/` / `SEC/` is missing → **STOP**; return to O1. Max-3 gap questions do not replace this gate.
- **`direct` (Classic SDD):** if no `FEATURE.md` with `needs_*` → do not require siblings. If flags exist and folders missing → ask (create inline / proceed at operator risk / optional `/orchestrate-analyze`); do **not** hard-block.

PLAN magro requires a canonical path: do not omit SQL/DDL/OpenAPI from PLAN unless bank phase 2 or ARCH/ANALYSIS already holds the body; create that file first, then cite the path.

## Missing PRD or PLAN

Ask structured options in **pt-BR** before a dry handoff (`PIPELINE.md` § Missing canonical artifact): create artifact first vs send details in the next message.

## Confirm before write

For **new** PRD or PLAN: show path + summary (confirm chat **may** show OS absolute; artifact **Writes** and embedded cites use **portable paths** per `STORAGE.md` § Portable path), then ask **"Posso gravar em `{path}`? (sim / ajustar / cancelar)"**. `Write` only after **sim**.

## Cursor mode

- **Plan / Ask:** Phase A - questions and draft in chat only. Do **not** claim files were saved without a successful `Write`.
- **Agent:** Phase B - persist after confirmation; run `sdd-develop` and `test-coverage`.

When Phase A is done but persistence is pending, tell the user to switch to **Agent** and resend `/<name> - gravar`.

## Boundaries

- `sdd-spec` / `sdd-plan`: no production or test code changes.
- `sdd-develop`: **one PLAN step per develop session** (unchanged contract — do not weaken). Handoff to the next step cites the portable PLAN path + step id only. Develop gates (`step_confirmed`, `tests_run`) live in PLAN-scoped files under `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/sdd/sessions/{repo-hash}/` - see `SESSION.md` (supports parallel O3 without sharing one flat session JSON).
- `code-review`: does not write PRD/PLAN; hand off findings with `/sdd-spec`.
