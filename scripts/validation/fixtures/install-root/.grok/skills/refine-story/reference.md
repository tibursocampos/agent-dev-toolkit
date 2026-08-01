# refine-story - reference

Scorecard, guardrails, and boundaries for `skills/refine-story/SKILL.md`. Keep `SKILL.md` under 500 lines; use this file for extended detail.

---

## Boundary: refine vs O1 vs sdd-spec

| Aspect | `refine-story` (Forma B) | `orchestrate-analyze` (O1) | `sdd-spec` (Forma A) |
|--------|----------------------------------|----------------------------|----------------------|
| Purpose | Fast intake - one backlog item + scorecard | Multi-agent triage + US/TS backlog for a feature | Full PRD for one story/feature |
| Output | Structured markdown + scorecard | `FEATURE.md`, `CONTINUITY.md`, `STORY.md` × N | PRD under `features/.../PRD/` |
| Persistence | Prefer `features/.../STORY.md`; shortcut `docs/backlog/` | Feature tree only | Canonical PRD path |
| Specialists | None | Conditional Task (`needs_*`) | None (consumes Prior context) |
| When to use | Informal idea, bug, single TS/US | Complex / multi-story / brownfield package | Ready to write PRD for one path |
| Tracker | Never (no external tracker/`az`) | Never | Never |

Escalate to **O1** when: multiple stories, unclear flags (`needs_*`), brownfield impact needs parallel specialists.

Escalate to **sdd-spec** when: single story is clear enough for a PRD (or after refine approval).

Do **not** expand refine into a full PRD inline.

Handoff wording:

```
Item grande / multi-história: /orchestrate-analyze
Item único pronto para PRD: /sdd-spec
Checklist local: /split-story-checklist
```

Before suggesting `sdd-spec`, optionally Glob `features/**/PRD/` (workspace + global feature root) per `STORAGE.md`. Do **not** glob root/flat `PRD/` for execution.

`sdd-spec` owns storage choice, manifest, `.gitignore`, and confirm-before-write. Refine does **not** write PRD/PLAN. Promote `docs/backlog/` via `sdd-spec` or O1 - never treat backlog files as PRD.

---

## Scorecard rubric

Score immediately after generating the markdown. Maximum **100** points. Portable backlog refinement style (no external work-item fields).

### Universal criteria (all types)

| Criterion | Max | Scoring guide |
|-----------|-----|----------------|
| Objective | 15 | 15: affirmative, ≤3 sentences, correct perspective, specific / 8: correct but long or generic / 3: vague or wrong perspective / 0: missing |
| Acceptance criteria (BDD) | 25 | 25: all Given/When/Then, covers happy path + error + edge / 15: BDD present but incomplete / 8: no BDD or intent language / 0: missing |
| Implementation steps | 20 | 20: baby steps, infinitive verbs, layer order, explicit deps / 12: steps ok but weak granularity or deps / 5: generic steps / 0: missing |
| No vague language | 10 | 10: none / 5: 1-2 vague phrases / 0: multiple |

### Type-specific criteria (30 points total)

**Technical Story:**

| Criterion | Max |
|-----------|-----|
| Technical context (problem -> solution -> scope) | 10 |
| Repositories / areas listed | 5 |
| Technical specificity (types, endpoints, events when relevant) | 10 |
| Dependencies declared or N/A justified | 5 |

**User Story:**

| Criterion | Max |
|-----------|-----|
| Context + current vs expected flow | 10 |
| Repositories / areas listed | 5 |
| Business AC vs technical AC separated | 10 |
| Dependencies declared or N/A justified | 5 |

**Bug:**

| Criterion | Max |
|-----------|-----|
| Repro steps + evidence | 10 |
| Frequency and impact | 5 |
| Suggested fix steps with files and deps | 10 |
| Non-regression BDD scenario | 5 |

### Scorecard output format

```markdown
---

## Quality scorecard

| Criterion | Score | Max | Note |
|-----------|-------|-----|------|
| Objective | [x] | 15 | [specific note] |
| Acceptance criteria (BDD) | [x] | 25 | [specific note] |
| Implementation steps | [x] | 20 | [specific note] |
| No vague language | [x] | 10 | [specific note] |
| [type-specific 1] | [x] | [max] | [specific note] |
| [type-specific 2] | [x] | [max] | [specific note] |
| [type-specific 3] | [x] | [max] | [specific note] |
| [type-specific 4] | [x] | [max] | [specific note] |

### Total: [sum] / 100

### Strengths
- [specific]

### Improvements
- **[Criterion]**: [what is missing and how to fix]

---
```

Rules: notes must be specific (not "OK"); improvements name exact gaps; incomplete user input reflected honestly.

When persisting as `STORY.md`, copy a short scorecard summary into the template `Scorecard (resumo)` table (1-5 scale mapped from /100 bands: 80+ = 5, 60-79 = 4, 40-59 = 3, else ≤2).

---

## Guardrails (before marking output final)

**Universal:**

- [ ] No empty or placeholder sections
- [ ] No vague phrases: "works correctly", "as expected", "properly"
- [ ] BDD uses **Given / When / Then / And**
- [ ] No unit-test scenarios in acceptance criteria
- [ ] No "verify environment variable X" as acceptance criteria
- [ ] Section icons/headings match the type template when saving chat form

**Technical Story / User Story:**

- [ ] Steps ordered by layer when applicable
- [ ] Dependencies section omitted when none (not "N/A" filler)
- [ ] Each step has explicit `Depends on:` for topological breakdown

**User Story:**

- [ ] Business AC without implementation jargon
- [ ] Technical AC as checkboxes, not BDD

**Bug:**

- [ ] Reproduction steps are actionable
- [ ] Expected result describes positive behavior

If guardrails fail, ask for missing detail - do not publish incomplete docs.

---

## Optional save: feature STORY (preferred)

```markdown
# STORY: US01 - [title]
...
```

Use `skills/_shared/templates/features/story/STORY.md`. Place under `features/NNN-slug/USnn/STORY.md`. Optional raw refine dump: `features/NNN-slug/USnn/REFINE/refine.md`.

Do **not** create `REFINE/` at repo root.

---

## Optional save: `docs/backlog/<slug>.md` (shortcut)

Prefix file with metadata:

```markdown
# Backlog: [title]

| Field | Value |
|-------|--------|
| **Type** | Bug \| User Story \| Technical Story |
| **Doc language** | pt-BR \| English |
| **Refined** | YYYY-MM-DD |
| **Repository** | [folder or remote name] |
| **Preferred promote** | features/NNN-slug/USnn/STORY.md |

[generated body]
```

Do not create `docs/backlog/` in **cursor-dev-toolkit** during toolkit porting - only in consumer repos at runtime.

---

## Relationship to split-story-checklist

| Skill | Use |
|-------|------|
| `refine-story` | Produces steps under `### Steps` (or Bug suggested fix) with deps |
| `split-story-checklist` | Groups those steps with topological / layer grouping into a checklist |

After refine, offer:

```
/split-story-checklist - <story-or-backlog-path>
```

---

## Explicit exclusions

Do **not** introduce:

- External work-item tracker CLI/API commands
- External work-item tracker or org-only compliance fields
- Remote PATCH of work items
