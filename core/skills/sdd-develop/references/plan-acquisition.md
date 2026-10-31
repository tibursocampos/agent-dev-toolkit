# plan-acquisition (canonical PLAN obtain + validate)

Contract id: `plan-acquisition`. Load **before** mutating application code or marking a PLAN step Completed. Applies to direct `/sdd-develop` and to every O3 child that implements a step.

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

1. **Resolve path and context** from the current invocation / parent handoff (exact path preferred). An explicit `invocation_context=direct|orchestrated` wins over execution shape and host preference; resolve it once and retain it for the run. Generic parent coordination, a parent role named `orchestrator`, an Agent used for bounded delegation, `orchestrator_mode=always`, or an O3-related change in the PLAN do not select `orchestrated`. If explicit invocation/handoff context declarations disagree, stop with `invocation_context_conflict` rather than silently selecting a mode. A canonical PLAN plus an explicit step is a complete request to execute that step in the current session; do not require a new session or ask the operator to repeat it. Continue through that context's dependency and confirmation gates.
2. **Normalize** (`\` → `/`, trim trailing `/`). Reject `..` and escapes outside features root.
3. **Validate shape** — must match canonical table above. Flat/root PLAN → **STOP**; ask migrate via `/sdd-plan`.
4. **Read** that file in place (update **that** path only).
5. **Resolve step** (`Step N` / `PASSO N`). Confirm step heading exists; deps are **Completed** / **Concluídos**. When `invocation_context=direct` is explicit, the canonical approved PLAN is sufficient: do not inspect siblings to infer context, require/create `REFINE/tasks.md`, or ask the operator to select O3. A checklist may affect direct execution only when the invocation explicitly adopts it and its relationship to the PLAN is explicit and consistent; otherwise the PLAN remains the sole execution unit. When `invocation_context=orchestrated`, require the O3 parent's explicit scoped checklist input and validate its applicable task rows/IDs against this step; absent or inconsistent required rows block/return to O2. Preserve O3 preflight and claim gates; never use the direct fallback to bypass them. If the invocation genuinely omits both step or route/context, ask whether the operator wants manual execution (one explicit invocation per step) or Orchestrated Delivery O3. Present localized labels and map clear semantic answers to stable ids `manual` and `orchestrated`. This per-invocation route is independent of `preferences.json` `orchestrator_mode` (`always` | `adaptive`) and pacing (`continuous` | `step_by_step`). Do not infer a route or implement before the answer.
6. **Resolve Classic external access scope**, when the active step declares it, per `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/CLASSIC-EXTERNAL-ACCESS.md`: preserve the approved portable target and operation set. A supported host boundary must accept the alias-to-root mapping only from trusted invocation context, separate from PRD/PLAN/receipt. Do not treat O3 `files[]` as a grant. The validation-only fixture `{{TOOLKIT_ROOT}}/scripts/validation/fixtures/Invoke-ClassicExternalAccessFixture.ps1` is never a production authorization boundary and must not be used for implementation I/O. Because no host-controlled boundary currently provides trusted per-step grants and intercepts all filesystem and shell operations, block before external access (`BLOCKED`); do not substitute structural checks, fixture calls, or direct filesystem operations for enforcement.
7. **Load develop SESSION** scoped by PLAN (or PLAN+step) per `SESSION.md` — never use flat repo JSON for `step_confirmed` / `tests_run`.
8. **Honor develop mode** (`continuous` \| `step_by_step`) from `references/develop-modes.md` — does **not** waive one-step-per-session.
9. Only then: analyze / implement / tests. Execute only the resolved step in the current session; after reporting it, stop and hand off without auto-advancing.

### Observable route question

Use an adapter-native question component only when its selected answer is returned to the agent as observable input. Otherwise ask in localized text with numbered choices and accept semantically equivalent replies, not only fixed tokens such as `manual`, `O3`, or `sim`. Missing or ambiguous answers remain blocking. Route selection does not approve the step: retain normal confirmation, `step_confirmed`, dependency, scoped-session, and any context-required PLAN-ledger checks.

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
- Weaken SESSION / PLAN-LEDGER
- Embed duration/effort estimates while acquiring (`REQ-010` / `plan-contract.md`)
