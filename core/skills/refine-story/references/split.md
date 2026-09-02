# Mode playbook: split

**Load only when refine mode = `split`.** Do not load `feature.md` or `tech.md` in the same session step.

Packing inspiration (structure only — paraphrase; no remote tracker): clarify-style mode playbook — prepare dependency-aware steps for local checklist split (not Azure WI decomposition).

## Scope

Produce or reshape a refined item so **implementation steps** are ready for `/split-story-checklist`: one responsibility per step, explicit deps, parallel-safe notes, outcome-shaped titles.

May start from: pasted draft, existing `STORY.md` / `docs/backlog/` path, or a short description. Item type may be Bug, User Story, or Technical Story — load **one** matching type file only.

## Steps

### 1. Resolve source + type

Ask once if missing:

```
[Refine · split] Fonte e tipo?

1) Colar / descrever agora
2) Path STORY.md ou docs/backlog/
Tipo: Bug | User Story | Technical Story
```

Load **one** type template from `_shared/backlog-item-types/`. For User Story persona only when Who/Job/Outcome helps (`references/product-persona.md`). Do **not** run the full `feature` or `tech` playbooks — stay on split-focused shaping.

### 2. Collect or read existing body

If path given: Read that file. If thin: ask targeted questions for missing Objective, AC, or steps — do not invent full product context beyond what split needs.

### 3. Generate / reshape documentation

Ensure sections required by the type template exist. **Primary focus — Steps:**

- One responsibility per step; infinitive verbs
- Behavior titles — not file/class/layer-only (`story-sizing.md`, `anti-task-shatter.md`)
- Explicit `Depends on:` (or clear “none”) for topological grouping
- Mark independent steps as parallel-safe when true
- Layer order when applicable

**BDD:** keep or add Given/When/Then with AC budget **happy + rule/edge + failure** and observable Then. Challenge vagueness.

**Selective retrieval:** do not dump bank/PRD (`SR-NO-FULL-DUMP`).

This mode does **not** call `split-story-checklist` internals — it prepares input and hands off.

### 4. Quality scorecard

Score per `references/scorecard-rubric.md` + `references/scorecard-template.md`. Lazy-load Product-depth norms. Emphasize **Implementation steps** and **Story scope** notes for checklist readiness. Product depth wiring preserved (US03).

### 5. Validation (chat-only)

Check `references/guardrails.md` — especially deps and outcome-shaped step titles.

### 6. Optional persistence

Follow `references/persistence.md`. File-based only — never Azure WI / external tracker (`references/exclusions.md`).

### 7. Handoff (required offer)

Always offer:

```
/split-story-checklist - <story-or-backlog-path>
```

Detail: `references/split-handoff.md`. Other paths: O1 / `sdd-spec` / stack developer per `references/boundary.md`.
