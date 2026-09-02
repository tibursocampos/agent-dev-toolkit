# Invocation contexts (SDD pipeline)

Install path after sync: `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/INVOCATION-CONTEXTS.md`

**Language:** This guideline is **English**. Operator chat stays **pt-BR** per toolkit policy (`LANGUAGE.md`).

Companion: `PIPELINE.md`, `SELECTIVE-RETRIEVAL.md` (`SR-NO-FULL-DUMP`), `SESSION.md`, `SPAWN.md`, `STORAGE.md` § Portable path.

**Rule ID:** `IC-DIRECT-ORCHESTRATED`

---

## Purpose (REQ-001 / CA1)

Pipeline skills must apply **observable** behavior for two invocation contexts:

| Context id | Meaning |
|------------|---------|
| `direct` | Consumer invokes the skill via slash / skill name in the operator session (Classic SDD or standalone). |
| `orchestrated` | Skill runs under Orchestrated Delivery (`orchestrate-*` parent) or as a Task/spawn child with a scoped handoff. |

Do **not** invent a third context. Do **not** treat host IDE mode (Agent/Plan/Ask) as an invocation context — that is `PIPELINE.md` Cursor mode.

## In-scope pipeline skills

| Skill | Typical default when slash-invoked |
|-------|-------------------------------------|
| `orchestrate-analyze` | `orchestrated` (skill **is** the O1 orchestrator) |
| `orchestrate-deliver` | `orchestrated` (O2) |
| `orchestrate-develop` | `orchestrated` (O3 parent) |
| `sdd-spec` | `direct` unless parent handoff marks `orchestrated` |
| `sdd-plan` | `direct` unless parent handoff marks `orchestrated` |
| `sdd-develop` | `direct` unless O3 child / plan-scoped develop session from orchestrator |
| `refine-story` | `direct` unless parent handoff marks `orchestrated` |
| `memory-bank-init` | `direct` unless Step 0 / Step N gate from `orchestrate-*` |

## Detection (deterministic)

Resolve context **once** at skill start (after gate check). Prefer explicit signal over inference:

1. **Explicit** — handoff / Task prompt / CONTINUITY / parent receipt sets `invocation_context: orchestrated` or `direct`.
2. **Spawn child** — running as Task subagent with a parent orchestrate skill → `orchestrated`.
3. **Orchestrate skill body** — any `orchestrate-*` run → `orchestrated`.
4. **Else** — `direct`.

Record the resolved id in the session report / child receipt when one is produced (en-US field name: `invocation_context`).

## Observable behavior

### Shared (both contexts)

| Rule | Behavior |
|------|----------|
| Selective retrieval | Paths + short summaries only; **must not** dump entire `memory-bank/` or paste full PRD (`SR-NO-FULL-DUMP`) |
| Portable paths | Artifact cross-refs use portable paths (`STORAGE.md`); no OS absolute / InstallRoot embeds in written artifacts |
| Secrets in examples | Env var **names** or `***` only — never real tokens (RNF-002) |
| Gates | Honor `SESSION.md` gates before Write / mutating Shell |
| Model on spawn | Omit `model` by default (same as parent); no alternate slug without gate (`SUBAGENT-MODEL.md`) |

### `direct`

| Observable | Required behavior |
|------------|-------------------|
| Operator confirms | This skill owns confirm-before-write / step confirm dialogs for **its** writes |
| Memory-bank | Classic `sdd-*` does **not** require Step 0 bank gate; `memory-bank-init` may run alone |
| CONTINUITY | Do **not** assume a parent CONTINUITY owner; update CONTINUITY only when this skill's contract says so |
| Scope | Full skill Process for the invoked skill; do **not** silently start sibling orchestrate stages |
| Handoff | After one skill outcome, stop; suggest next slash invoke (portable path) |

### `orchestrated`

| Observable | Required behavior |
|------------|-------------------|
| Parent owns wave | Parent `orchestrate-*` owns CONTINUITY phase, Step 0 bank gate, and multi-story / multi-step queue |
| Child scope | One PLAN step / one story stage / one bank mode per child — never multi-step in one child |
| Handoff input | Prefer scoped paths + receipt; when `source_context` is present, **skip** opaque re-read of the same artifact (`read-sdd-artifact` / `RSA-SOURCE-CONTEXT`) |
| No parent duties | Child **must not** re-run O1/O2/O3 parent orchestration, re-approve the feature backlog, or rewrite parent CONTINUITY beyond the child's allowed receipt fields |
| Chat vs receipt | Operator-facing prompts may be pt-BR; child receipts / Task summaries stay en-US identifiers (`LANGUAGE.md`) |
| Spawn (Eixo A) | Parent decides spawn vs in-parent per `SPAWN.md`; children do not flip that policy |

## Examples (no secrets)

### Env / redaction (RNF-002)

```text
# OK — env var name only
Authorization: Bearer $env:MY_API_TOKEN
Authorization: Bearer ***

# Forbidden — real token material
Authorization: Bearer eyJhbGciOi***real*** 
```

### Direct slash (shape)

```text
User: /sdd-develop - features/004-export-profile/US01/PLAN/PLAN_004_export_profile.md - Step 2
→ invocation_context=direct
→ skill owns step_confirmed gate; no O3 CONTINUITY ownership
```

### Orchestrated child (shape)

```text
Parent O3 Task prompt includes:
  invocation_context: orchestrated
  plan_path: features/004-export-profile/US01/PLAN/PLAN_004_export_profile.md
  step: 2
  # optional: source_context envelope from read-sdd-artifact (RSA-SOURCE-CONTEXT)
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
- Dump this contract body into child Task prompts (cite portable path + context id only)
- Put real API tokens, passwords, or private keys in examples
- Use invocation context to remove Eixo A spawn vs in-parent choice
- Treat Plan/Ask vs Agent as `direct` / `orchestrated`
