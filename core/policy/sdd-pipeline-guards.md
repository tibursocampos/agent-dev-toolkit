---
description: SDD pipeline order, canonical PRD/PLAN paths, confirm-before-write, Plan/Ask vs Agent phases
alwaysApply: true
---

# SDD pipeline guards

Full detail: `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/PIPELINE.md` (load when running `sdd-spec`, `sdd-plan`, or `sdd-develop`).

## Order

- **Classic SDD (Forma A)**: `sdd-spec` -> `sdd-plan` -> `sdd-develop`. Do not create a PLAN without a canonical PRD (unless "PLAN direto"). Do not implement without a canonical PLAN.
- **Forma C**: `orchestrate-analyze` -> `orchestrate-deliver` -> (`orchestrate-develop` \| `sdd-develop`) after human gates.

## Canonical paths only

### Classic SDD (writes and execution)

- PRD: `features/NNN-slug/USnn/PRD/NNN_*.md` (default story `US01`) or global under `{{SDD_ROOT}}/<repo-id>/features/...`.
- PLAN: `features/NNN-slug/USnn/PLAN/PLAN_NNN_*.md` or global equivalent. PLAN `NNN` matches PRD.
- Numbering (`NNN`): from `features/*/` only (workspace + global feature root).
- Root/flat `PRD/` / `PLAN/` / `docs/PRD/` / `docs/PLAN/`: **not** valid Classic SDD paths - do not read, write, or update-in-place for execution. Keep those patterns in `.gitignore` **only as a safety net** (`STORAGE.md`).

Never save **new** SDD artifacts under `docs/backlog/` or ad-hoc `docs/*.md` for canonical SDD. Prefer feature tree for Forma B stories (`STORY.md`); `docs/backlog/` is a shortcut only.

## Missing PRD or PLAN

Ask structured options in **pt-BR** before a dry handoff (`PIPELINE.md` § Missing canonical artifact): create artifact first vs send details in the next message.

## Confirm before write

For **new** PRD or PLAN: show full path + summary, then ask **"Posso gravar em `{path}`? (sim / ajustar / cancelar)"**. `Write` only after **sim**.

## Cursor mode

- **Plan / Ask:** Phase A - questions and draft in chat only. Do **not** claim files were saved without a successful `Write`.
- **Agent:** Phase B - persist after confirmation; run `sdd-develop` and `test-coverage`.

When Phase A is done but persistence is pending, tell the user to switch to **Agent** and resend `/<name> - gravar`.

## Boundaries

- `sdd-spec` / `sdd-plan`: no production or test code changes.
- `sdd-develop`: **one PLAN step per develop session** (unchanged contract). Develop gates (`step_confirmed`, `tests_run`) live in PLAN-scoped files under `{{SDD_ROOT}}/sessions/{repo-hash}/` - see `SESSION.md` (supports parallel O3 without sharing one flat session JSON).
- `code-review`: does not write PRD/PLAN; hand off findings with `/sdd-spec`.
