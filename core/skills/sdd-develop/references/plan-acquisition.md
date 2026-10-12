# plan-acquisition (canonical PLAN obtain + validate)

**REQ-008 / CA3 / CT3.** Contract id: `plan-acquisition`. Load **before** mutating application code or marking a PLAN step Completed. Applies to direct `/sdd-develop` and to every O3 child that implements a step.

**Language:** English identifiers and reason codes. Operator chat may be pt-BR. Portable paths only (`STORAGE.md` § Portable path).

Companions: `SESSION.md`, `references/develop-modes.md`, `references/plan-contract.md`, `PIPELINE.md` (missing PLAN).

---

## Purpose

Obtain and validate the **canonical PLAN** path and step before implement. Reject non-canonical paths. Do **not** invent a second session or ledger SoT.

## Canonical path shape

| Valid | Invalid (STOP) |
|-------|----------------|
| `features/NNN-slug/USnn/PLAN/PLAN_NNN_*.md` (or `TSnn`) | Root/flat `PLAN/` |
| Global classic: `sdd/<repo-id>/features/.../PLAN/PLAN_*.md` | Paths outside resolved features root |
| Absolute resolve OK for Read — **cite portable** in receipts/handoffs | OS absolute embeds in SDD artifact bodies |

## Acquisition algorithm (observable)

1. **Resolve path** from invoke / parent handoff (exact path preferred). A canonical PLAN plus an explicit step is a complete request to execute that step in the current session; do not require a new session or ask the operator to repeat it. Continue through the normal dependency and confirmation gates.
2. **Normalize** (`\` → `/`, trim trailing `/`). Reject `..` and escapes outside features root.
3. **Validate shape** — must match canonical table above. Flat/root PLAN → **STOP**; ask migrate via `/sdd-plan`.
4. **Read** that file in place (update **that** path only).
5. **Resolve step** (`Step N` / `PASSO N`). Confirm step heading exists; deps are **Completed** / **Concluídos**. If the invocation identifies a PLAN but omits the step, or the PLAN omits an execution route, ask whether the operator wants manual execution (one explicit invocation per step) or Orchestrated Delivery O3. Present localized labels and map clear semantic answers to stable ids `manual` and `orchestrated`. This per-invocation route is independent of `preferences.json` `orchestrator_mode` (`always` | `adaptive`) and pacing (`continuous` | `step_by_step`). Do not infer a route or implement before the answer.
6. **Load develop SESSION** scoped by PLAN (or PLAN+step) per `SESSION.md` — never use flat repo JSON for `step_confirmed` / `tests_run`.
7. **Honor develop mode** (`continuous` \| `step_by_step`) from `references/develop-modes.md` — does **not** waive one-step-per-session.
8. Only then: analyze / implement / tests. Execute only the resolved step in the current session; after reporting it, stop and hand off without auto-advancing.

### Observable route question

Use an adapter-native question component only when its selected answer is returned to the agent as observable input. Otherwise ask in localized text with numbered choices and accept semantically equivalent replies, not only fixed tokens such as `manual`, `O3`, or `sim`. Missing or ambiguous answers remain blocking. Route selection does not approve the step: retain normal confirmation, `step_confirmed`, dependency, scoped-session, and PLAN-ledger checks.

If path missing: Glob `features/**/PLAN/PLAN_*.md` (workspace + global feature root); if none → `PIPELINE.md` § sdd-develop without PLAN (options 1–3). **Do not** create PRD/PLAN here.

## STOP reasons (English codes)

| Code | When |
|------|------|
| `plan_path_non_canonical` | Flat/root or non-`features/.../PLAN/` shape |
| `plan_path_outside_features` | Resolved path escapes features root |
| `plan_step_missing` | Step id not found in PLAN |
| `plan_deps_incomplete` | Deps not Completed |
| `plan_session_unscoped` | Attempt to use flat repo session for develop gates |

## Skill wiring

| Consumer | When to load |
|----------|----------------|
| `sdd-develop` | Process § Workspace (step 0) — before validate/implement |
| O3 child | Parent must pass portable PLAN path + step; child re-runs this contract |
| `orchestrate-develop` parent | Resolve PLAN set via `process-common.md`; children still run `plan-acquisition` |

## Must not

- Bypass acquisition and mutate code from memory of an old PLAN path
- Weaken SESSION / PLAN-LEDGER (`RNF-003`)
- Embed duration/effort estimates while acquiring (`REQ-010` / `plan-contract.md`)
