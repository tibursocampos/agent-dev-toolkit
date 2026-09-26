# Mode playbook: tech

**Load only when refine mode = `tech`.** Do not load `feature.md` or `split.md` in the same session step. Isolation matrix: `references/mode-isolation.md`.

Packing inspiration (structure only — paraphrase; no remote tracker): clarify-style mode playbook — local markdown refine for technical work. **Do not** create a parallel clarify skill (REQ-007).

## Scope

**Technical Story** only (`TSnn`). Problem → solution → scope; repositories/areas; technical specificity (types, endpoints, events when relevant).

**Envelope:** `mode: tech` — see `references/interaction-envelope.md`. Chat prefix: `[Refine · tech]`.

## Steps

### 1. Confirm Technical Story

Default type = Technical Story. Load `_shared/backlog-item-types/technical-story.md` only.

Do **not** load `user-story.md`, `bug.md`, or `persona-context.md` in this mode unless the user explicitly switches to `feature`.

Map persistence to `features/NNN-slug/TSnn/STORY.md` when saving under features.

Open/refresh skeleton envelope (`item_type: Technical Story`, `status: NEEDS_CLARIFICATION` until READY).

### 2. Collect description

Ask for technical problem, proposed direction, affected areas, constraints, and known dependencies. Use collection questions from `technical-story.md` when thin — no placeholder `[...]` sections.

When clarifying: append Q&A history (`references/qa-history.md`); severity **B** \| **I** \| **MINOR**.

### 3. Generate documentation

Follow `technical-story.md` **Output template** and **Writing guidelines**.

**Steps:** one responsibility per step; infinitive verbs; behavior titles (not file/class only — `story-sizing.md` / `anti-task-shatter.md`); layer order; explicit `Depends on:`; mark parallel-safe steps.

**BDD:** technical acceptance as Given/When/Then with observable Then; cover **happy + rule/edge + failure** (`gherkin-budget.md`). Challenge vague language.

**Selective retrieval:** paths + short summaries only (`SR-NO-FULL-DUMP`). Do not invent architecture that belongs to O1 specialists (`references/boundary.md`).

### 4. Quality scorecard

Score per `references/scorecard-rubric.md` + `references/scorecard-template.md`. Lazy-load Product-depth norms at score time. For Technical Story, Who/Job/Outcome is **`n/a`** — still score Product depth via Valuable + AC budget (`invest-and-story-quality.md`). Evidence omit OK (`product-evidence-lite.md`).

Refresh envelope `status` from open B/I (`interaction-envelope.md` + `readiness-severity.md`).

### 5. Validation (chat-only)

Check `references/guardrails.md` (Technical Story rows).

### 6. Optional persistence

Follow `references/persistence.md`. Prefer `features/.../TSnn/STORY.md`. Persist Q&A history when saving. File-based only — never Azure WI / external tracker (`references/exclusions.md`).

### 7. Handoff

| Situation | Next |
|-----------|------|
| Dependency-aware checklist | Offer mode `split` or `/split-story-checklist - <portable-story-path>` |
| Multi-story / needs specialists | `/orchestrate-analyze - <portable-feature-path>` |
| READY for PRD (no unanswered question at the open-question gate, including `MINOR`) | `/sdd-spec - <portable-story-path>` |
| `open_question` | Answer every open question; cite `qa_history` — do **not** claim ready-for-PRD |
| Isolated implementation | stack `*-developer` / `/developer` |

Portable paths only (REQ-006 / RNF-002).

## Story PRD contestation

Apply this section to a story PRD after `sdd-spec` writes it. Do not apply it to a feature-level spec. The Technical Story playbook above stays in force for `mode=tech`. This section does not replace it.

Inspect the PRD for API, events, database, and domain, and for coherence across those four. Record findings with `finding-format.md`.

Then run one contestation pass, isolated from the first:

- Already answered by another section or by repository evidence you can cite.
- Severity inflated by asking for implementation detail the PRD does not owe.
- A recommendation that would break an existing contract or duplicate a surface.
- A contradiction between two of the four areas that the first pass missed.

An open question after contestation means the PRD is not accepted. Stop code `open_question`. Do not call `sdd-plan`. Ask every open question. The cap of 3 gap questions does not apply.
