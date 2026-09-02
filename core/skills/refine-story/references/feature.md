# Mode playbook: feature

**Load only when refine mode = `feature`.** Do not load `tech.md` or `split.md` in the same session step.

Packing inspiration (structure only — paraphrase; no remote tracker): clarify-style mode playbook — local markdown refine.

## Scope

Product-facing backlog: **User Story** or **Bug**. Prefer User Story when value/outcome is primary; Bug when defect reproduction is primary.

## Steps

### 1. Select item type (within feature)

```
[Refine · feature] Tipo?

1) User Story
2) Bug
```

Load **one** matching file from `_shared/backlog-item-types/` (`user-story.md` or `bug.md`). Map: User Story → `USnn`; Bug → prefer `USnn` or note under existing story.

For User Story when who/job/outcome helps: load `references/product-persona.md` (points at `persona-context.md`). Do **not** load `technical-story.md` in this mode unless the user explicitly switches to `tech`.

### 2. Collect description

Ask for free-form description (problem, goal, context, constraints). Wait for enough detail; if thin, use collection questions from the type file — do not ship placeholder `[...]` sections.

### 3. Generate documentation

Follow the type file **Output template** and **Writing guidelines**. Combine user input with structure from the template — calibrate depth, not copy corporate examples.

**Steps:** one responsibility per step; infinitive verbs; layer order when applicable; explicit dependencies; note parallel steps when independent (feeds later `split` mode / `split-story-checklist`).

**BDD:** **Given / When / Then / And**; verifiable outcomes; **challenge vagueness** — avoid "works correctly", "as expected", "properly", "funciona corretamente". When handing off to `sdd-spec`, note that PRD will require stable **REQ-IDs**, OOS, and verifiable CA (`templates/sdd/PRD.md`).

**Selective retrieval:** paths + short summaries only (`SR-NO-FULL-DUMP`).

### 4. Quality scorecard

Immediately after the markdown, score per `references/scorecard-rubric.md` + `references/scorecard-template.md`. Lazy-load `gherkin-budget.md` + `invest-and-story-quality.md` (and `product-evidence-lite.md` when Evidence is discussed). Score **Product depth** and verify AC budget (**happy + rule/edge + failure**, observable Then). Show total / 100, strengths, and specific improvements. Map Product depth → STORY 1–5 per rubric.

### 5. Validation (chat-only)

Before presenting as final, check `references/guardrails.md`.

### 6. Optional persistence

Follow `references/persistence.md`. File-based only — never Azure WI / external tracker (`references/exclusions.md`).

### 7. Handoff

| Situation | Next |
|-----------|------|
| Break into implementation checklist | Offer mode `split` or `/split-story-checklist` |
| Multi-story / complex | `/orchestrate-analyze` |
| Ready for PRD | `/sdd-spec` |
| Small isolated change | `/developer` / stack `*-developer` |

Boundary detail: `references/boundary.md`.
