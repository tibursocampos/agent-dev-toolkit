# Invocation contexts (SDD pipeline)

Install path after sync: `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/INVOCATION-CONTEXTS.md`

**Language:** This guideline is **English**. Operator chat mirrors the **user chat language** (`LANGUAGE.md`). Child prompts / receipts stay **en-US**.

Companion: `PIPELINE.md`, `SELECTIVE-RETRIEVAL.md`, `SESSION.md`, `SPAWN.md`, `STORAGE.md` § Portable path.

**Rule ID:** `IC-DIRECT-ORCHESTRATED`

---

## Purpose

Pipeline skills must apply **observable** behavior for two invocation contexts:

| Context id | Meaning |
|------------|---------|
| `direct` | Consumer invokes the skill via slash / skill name in the operator session (Classic SDD or standalone). |
| `orchestrated` | Skill runs under Orchestrated Delivery (`adt-orchestrate-*` parent) or as an Agent/spawn child whose current handoff explicitly sets `invocation_context=orchestrated` or identifies the active `adt-orchestrate-*` stage. A generic scoped Agent handoff does not select this context. |

Do **not** invent a third context. Do **not** treat host IDE mode (Agent/Plan/Ask) as an invocation context — that is `PIPELINE.md` host session mode.

## In-scope pipeline skills

| Skill | Typical default when slash-invoked |
|-------|-------------------------------------|
| `adt-orchestrate-analyze` | `orchestrated` (skill **is** the O1 orchestrator) |
| `adt-orchestrate-prepare` | `orchestrated` (O2) |
| `adt-orchestrate-implement` | `orchestrated` (O3 parent) |
| `adt-sdd-spec` | `direct` unless parent handoff marks `orchestrated` |
| `adt-sdd-plan` | `direct` unless parent handoff marks `orchestrated` |
| `adt-sdd-develop` | `direct` unless O3 child / plan-scoped develop session from orchestrator |
| `adt-refine-story` | `direct` unless parent handoff marks `orchestrated` |
| `adt-requirement-review` | `direct` unless parent handoff marks `orchestrated` |
| `adt-memory-bank` | `direct` unless explicitly invoked for a bounded bank operation |

## Detection (deterministic)

Resolve context **once** at skill start (after gate check). Prefer the explicit current invocation/handoff over execution-shape defaults:

1. **Explicit current invocation** — a `invocation_context: direct|orchestrated` field provided by the current caller/handoff wins and is recorded once for this skill run.
2. **Orchestrated execution** — absent an explicit field, an Agent child whose current parent handoff identifies an `adt-orchestrate-*` stage, or execution of an `adt-orchestrate-*` skill itself, resolves to `orchestrated`.
3. **Default** — otherwise resolve to `direct`.

Do not infer or change the resolved context from the presence, absence, freshness, completeness, path proximity, or contents of FEATURE, STORY, CONTINUITY, REFINE/tasks, Memory Bank, PRD, PLAN, or any other sibling artifact. A sibling may be used only when the active skill contract authorizes it as an input and its relationship/authority is explicit; it does not set invocation context. Host preference such as `orchestrator_mode` is not an invocation signal. Resolve once at skill start and keep that context for the run; a conflicting sibling is reported as a conflict, not used as a fallback.

Generic parent coordination, a parent role named `orchestrator`, use of an Agent for bounded delegation, `orchestrator_mode=always`, or a PLAN that targets O3 contracts are not invocation-context signals. A Classic/direct `adt-sdd-develop` run stays `direct` when it edits O3 instructions or delegates its own bounded step. Only an explicit `invocation_context=orchestrated`, execution of an `adt-orchestrate-*` skill, or an unambiguously identified `adt-orchestrate-*` parent handoff selects `orchestrated` when no explicit context is provided. If multiple explicit context declarations in the current invocation/handoff disagree, stop with `invocation_context_conflict`; do not silently pick one or fall back to preferences or artifact contents.

Record the resolved id in the session report / child receipt when one is produced (en-US field name: `invocation_context`).

## Observable behavior

### Shared (both contexts)

| Rule | Behavior |
|------|----------|
| Selective retrieval | Paths + short summaries only; **must not** dump entire `memory-bank/` or paste full PRD |
| Portable paths | Artifact cross-refs use portable paths (`STORAGE.md`); no OS absolute / InstallRoot embeds in written artifacts |
| Secrets in examples | Env var **names** or `***` only — never real tokens |
| Authorization | Honor the user's authorized scope, material decisions, dependency/acceptance criteria, and required validation; Classic/O1/O2/O3 do not require SESSION flags or claims |
| Model on spawn | Omit `model` by default (same as parent); a different pair only via the session choice (`SUBAGENT-MODEL.md`) |

### `direct`

| Observable | Required behavior |
|------------|-------------------|
| Approval | Spec/plan drafts may be written during preparation; the complete PLAN receives one explicit approval before implementation |
| Memory-bank | Classic `adt-sdd-*` does **not** require Step 0 bank gate; `adt-memory-bank` may run alone |
| CONTINUITY | Do **not** assume a parent CONTINUITY owner; update CONTINUITY only when this skill's contract says so |
| Scope | Full skill Process for the invoked skill; do **not** silently start sibling orchestrate stages |
| Handoff | After one skill outcome, stop; suggest next slash invoke (portable path) |
| Cadence | The approved PLAN's selected `step_by_step` or `continuous` cadence applies; dependencies, acceptance, required validation, and material scope decisions still govern advancement |

### `orchestrated`

| Observable | Required behavior |
|------------|-------------------|
| Parent owns wave | Parent `adt-orchestrate-*` owns its one live progress table and multi-story / multi-step queue; Memory Bank and CONTINUITY are optional context |
| Child scope | O3 dispatch is serial: one PLAN step per child, never multiple concurrent implementation children |
| Handoff input | Prefer scoped paths + receipt; when `source_context` is present, reuse its verified identity (`adt-read-sdd-artifact` / `RSA-SOURCE-CONTEXT`). Read current PLAN instructions or progress when the task needs their content |
| No parent duties | Child **must not** re-run O1/O2/O3 parent orchestration or expand the approved step scope; parent reconciles the result into PLAN before dispatching another child |
| Chat vs receipt | Operator-facing prompts mirror user chat language; child receipts / Agent summaries stay **en-US** (`LANGUAGE.md`) |
| Spawn (Eixo A) | Parent decides spawn vs in-parent per `SPAWN.md`; children do not flip that policy |

## Examples (no secrets)

### Env / redaction

```text
# OK — env var name only
Authorization: Bearer $env:MY_API_TOKEN
Authorization: Bearer ***

# Forbidden — real token material
Authorization: Bearer eyJhbGciOi***real*** 
```

### Direct slash (shape)

```text
User: /adt-sdd-develop - features/004-export-profile/US01/PLAN/PLAN_004_export_profile.md - Step 2
→ invocation_context=direct
→ skill follows the PLAN's selected cadence; no SESSION gate or O3 CONTINUITY ownership
```

### Orchestrated child (shape)

```text
Parent O3 Agent prompt includes:
  invocation_context: orchestrated
  plan_path: features/004-export-profile/US01/PLAN/PLAN_004_export_profile.md
  step: 2
  # optional: source_context envelope from adt-read-sdd-artifact (RSA-SOURCE-CONTEXT)
→ child applies orchestrated rules; one step; receipt back to parent
```

## Wiring requirement

Each in-scope skill **must**:

1. Cite this file in Lazy-load (pointer only — do not paste this body into `SKILL.md`).
2. Resolve `invocation_context` at start and apply the matching table above.
3. Restate or cite `IC-DIRECT-ORCHESTRATED` in Must-not / Process so context cannot be ignored.

## Enforcement

| Check | How |
|-------|-----|
| Documented | This file + pipeline skill Lazy-load / Must-not pointers |
| Smoke | Contract file exists; each in-scope `SKILL.md` contains `INVOCATION-CONTEXTS` and `IC-DIRECT-ORCHESTRATED` |

Automated Assert may be added later; missing wire → do not mark REQ-001 / CA1 done.

## Must not

- Collapse `direct` and `orchestrated` into identical Process when the tables differ
- Dump this contract body into child Agent prompts (cite portable path + context id only)
- Put real API tokens, passwords, or private keys in examples
- Use invocation context to remove Eixo A spawn vs in-parent choice
- Treat Plan/Ask vs Agent as `direct` / `orchestrated`
- Add a separate file-write confirmation or SESSION gate to a child when the approved plan already authorizes its bounded implementation work.
