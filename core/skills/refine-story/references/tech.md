# Mode playbook: tech

**Load only when refine mode = `tech`.** Do not load `feature.md` or `split.md` in the same session step.

Packing inspiration (structure only — paraphrase; no remote tracker): clarify-style mode playbook — local markdown refine for technical work.

## Scope

**Technical Story** only (`TSnn`). Problem → solution → scope; repositories/areas; technical specificity (types, endpoints, events when relevant).

## Steps

### 1. Confirm Technical Story

Default type = Technical Story. Load `_shared/backlog-item-types/technical-story.md` only.

Do **not** load `user-story.md`, `bug.md`, or `persona-context.md` in this mode unless the user explicitly switches to `feature`.

Map persistence to `features/NNN-slug/TSnn/STORY.md` when saving under features.

### 2. Collect description

Ask for technical problem, proposed direction, affected areas, constraints, and known dependencies. Use collection questions from `technical-story.md` when thin — no placeholder `[...]` sections.

### 3. Generate documentation

Follow `technical-story.md` **Output template** and **Writing guidelines**.

**Steps:** one responsibility per step; infinitive verbs; behavior titles (not file/class only — `story-sizing.md` / `anti-task-shatter.md`); layer order; explicit `Depends on:`; mark parallel-safe steps.

**BDD:** technical acceptance as Given/When/Then with observable Then; cover **happy + rule/edge + failure** (`gherkin-budget.md`). Challenge vague language.

**Selective retrieval:** paths + short summaries only (`SR-NO-FULL-DUMP`). Do not invent architecture that belongs to O1 specialists (`references/boundary.md`).

### 4. Quality scorecard

Score per `references/scorecard-rubric.md` + `references/scorecard-template.md`. Lazy-load Product-depth norms at score time. For Technical Story, Who/Job/Outcome is **`n/a`** — still score Product depth via Valuable + AC budget (`invest-and-story-quality.md`). Evidence omit OK (`product-evidence-lite.md`).

### 5. Validation (chat-only)

Check `references/guardrails.md` (Technical Story rows).

### 6. Optional persistence

Follow `references/persistence.md`. Prefer `features/.../TSnn/STORY.md`. File-based only — never Azure WI / external tracker (`references/exclusions.md`).

### 7. Handoff

| Situation | Next |
|-----------|------|
| Dependency-aware checklist | Offer mode `split` or `/split-story-checklist` |
| Multi-story / needs specialists | `/orchestrate-analyze` |
| Ready for PRD | `/sdd-spec` |
| Isolated implementation | stack `*-developer` / `/developer` |
