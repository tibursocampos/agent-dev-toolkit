---
description: SDD pipeline order, canonical paths, approval and execution boundaries
alwaysApply: true
---

# SDD pipeline guards

Full detail: `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/PIPELINE.md` (load when running `sdd-spec`, `sdd-plan`, or `sdd-develop`).

## Operator track choice

Three tracks coexist — **none is a prerequisite for another**. Classic SDD (`sdd-spec` → `sdd-plan` → `sdd-develop`) is valid without `orchestrate-analyze`. The operator may invoke `/sdd-spec` or `/sdd-plan` directly from chat, the host's planning mode, a host plan file, or prior manual analysis. Do **not** block or redirect to Orchestrated Delivery unless the operator chooses it or `invocation_context` is `orchestrated` and O2 gates apply.

## Order

- **Classic SDD**: `sdd-spec` -> `sdd-plan` -> `sdd-develop`. Do not create a PLAN without a canonical PRD (unless "PLAN direto"). Do not implement without a canonical PLAN.
- **Orchestrated Delivery**: `orchestrate-analyze` -> `orchestrate-deliver` -> (`orchestrate-develop` \| `sdd-develop`); one complete PLAN approval precedes implementation.

## Canonical paths only

The canonical paths below apply to Classic SDD only; ADT Delivery uses one evolving `features/NNN-slug/PLAN.md` under its own skill contracts and must not be validated against the Classic path format.

### Classic SDD (writes and execution)

- PRD: `features/NNN-slug/USnn/PRD/NNN_*.md` (default story `US01`) or global under `{{SDD_ROOT}}/<repo-id>/features/...`.
- PLAN: `features/NNN-slug/USnn/PLAN/PLAN_NNN_*.md` or global equivalent. PLAN `NNN` matches PRD.
- Numbering (`NNN`): from `features/*/` only (workspace + global feature root).
- Root/flat `PRD/` / `PLAN/` / `docs/PRD/` / `docs/PLAN/`: **not** valid Classic SDD paths - do not read, write, or update-in-place for execution. Keep those patterns in `.gitignore` **only as a safety net** (`STORAGE.md`).
- **Portable path cites:** versioned SDD Writes and embedded links use portable paths only (`STORAGE.md` § Portable path). Chat confirmations may show OS absolute paths for the operator; never bake `^[A-Za-z]:/` or InstallRoot home embeds into artifact bodies.

Never save **new** SDD artifacts under `docs/backlog/` or ad-hoc `docs/*.md` for canonical SDD. Prefer feature tree for Backlog Refine stories (`STORY.md`); `docs/backlog/` is a shortcut only.

**Cited material and supporting artifacts:** use relevant, authorized cited Markdown directly; no promotion copy is required. FEATURE, STORY, CONTINUITY, CHANGE, TASKS, Memory Bank, ANALYSIS, ARCH, and SEC are optional unless a concrete material decision or the approved plan explicitly requires a supporting artifact. Brownfield classification alone does not require mirrored architecture notes. Keep detailed technical evidence in the most useful source and cite it from the PLAN when appropriate; do not create a sidecar solely to satisfy a format gate.

## Approval and execution boundary

Classic SDD and Orchestrated Delivery may write and revise draft FEATURE/STORY/PRD/PLAN artifacts while preparing the plan; do not ask for separate write authorization for each document. Obtain one explicit approval of the complete plan before implementation. That approval authorizes only its stated scope and cadence. Ask again only when a proposed change materially alters the approved behavior, acceptance, scope, access, or execution decision. A missing answer to a material decision blocks only affected work; minor questions and optional improvements remain visible without stopping independent work. The PLAN is the canonical implementation progress record. CONTINUITY, CHANGE, and TASKS are optional context and never prerequisites solely because a flow is Classic or orchestrated. Details and unaffected-consumer exceptions: `PIPELINE.md` § Simplified Delivery contract.

## Host session mode

- **Read-only host mode** (planning or ask-only): Phase A. Questions and draft in chat only. Do not claim files were saved without a successful `Write`.
- **Edit-capable host mode**: Phase B. Persist within the authorized task scope. Run `sdd-develop`, `run-tests`, and `test-coverage` when that skill applies.

When Phase A is done and persistence is still pending, explain that the current host mode cannot write and continue the already authorized task when an edit-capable mode is available; do not ask for redundant write approval.

## Boundaries

A canonical, approved PLAN starts in the current session when its dependencies and required inputs are ready; do not require a new session. Resolve direct vs O3 route or cadence only when the invocation leaves a real choice unresolved. Reuse the approved PLAN's cadence on resumption; no per-step SESSION reset is required.

- `sdd-spec` / `sdd-plan`: no production or test code changes.
- `sdd-develop`: use the cadence selected for the approved plan (`step_by_step` or `continuous`); in step-by-step mode stop after one completed step, and in continuous mode advance through eligible steps until completion or a real blocker. O3 dispatch is serial, one child per step. The PLAN alone records implementation progress; session files and claims are not prerequisites for these affected flows. ADT Delivery follows its own contract.
- `code-review`: does not write PRD/PLAN; hand off findings with `/sdd-spec`.
