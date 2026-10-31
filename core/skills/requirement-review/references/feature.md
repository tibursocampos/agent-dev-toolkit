# Mode playbook: --feature

**Load only when mode = `--feature`.** Do not load `tech.md` in the same run. Shared rules (severity, question format, atomization, Q&A, report, handoff) live in `SKILL.md`; they are not repeated here.

## Scope

Functional review of one item (User Story or Bug) or of a FEATURE.md-level set of requirements. Product-facing: actor, flow, rules, criteria, states. The source and the Q&A history are the only inputs. Repository search belongs to `--tech`.

## Steps

### F1. Identify the item

- Item type: User Story, Bug, or Feature (FEATURE.md).
- Actor (named role), goal, and value.
- For FEATURE.md: list each macro acceptance criterion and the story id it maps to, if the source states one.
- Missing actor or goal: open question, severity **B**, owner **Product**.

### F2. Structure check

Check each element. Mark it `present`, `missing`, or `contradictory`.

| Element | What to find |
|---------|--------------|
| Scope | In-scope list and an explicit out-of-scope list |
| Preconditions | State and data required before the flow starts |
| Main flow | Ordered, observable steps |
| Alternate flows | Each valid variation and where it returns |
| Error flows | Each failure case and the visible response |
| Permissions | Who may act, and what a denied actor sees |
| Data ownership | Which actor or system owns each data item the flow creates or changes |
| State transitions | Allowed states and transitions; forbidden transitions |
| Integrations | External systems in the flow, their failure behavior, and who owns the contract |
| Non-functional needs | Only the ones the source implies: latency, volume, audit, privacy, accessibility, availability |
| Rollout and rollback | Flag or phase, and the condition that triggers rollback |

- Record a `GAP` finding for each `missing` element that changes implementation or tests.
- Ask only when the answer changes what gets built or tested. Do not ask for every row.

### F3. Acceptance criteria check

For each criterion in the source:

- Has Given / When / Then, or an explicit observable result.
- Its Then names an observable result on a user-visible surface, a persisted value, or an emitted message.
- Has a boundary case where the domain has one (empty, limit, duplicate, repeated submit).
- Has failure behavior: what the user sees and what is persisted or not.

A criterion that fails a check is an `ACCEPTANCE_GAP` finding (evidence: the criterion's portable path and section).

### F4. Atomize

Apply the atomization rules in `SKILL.md` section 4. Report as a table that lists every criterion and every atom, with no row omitted or summarized:

| Parent | Atom | Given / When / Then | Observable Then | Status |
|--------|------|---------------------|-----------------|--------|
| CA-002 | CA-002.a | Given … When … Then … | <the observable result> | ok \| gap |
| CA-002 | CA-002.b | … | … | ok \| gap |

Keep the source wording of a criterion that already passes. Mark the atom `gap` when the observable result is missing; the gap becomes a question or a finding.

### F5. Questions and decision owners

- **Product:** value, scope, business rules, priority, who may act, what counts as success.
- **Engineering:** feasibility, integration contracts, performance and volume targets, data model constraints.
- **UX:** flow shape, visible states, empty and error screens, copy that a rule depends on.

Severity: **B** if a wrong guess would make the PRD, PLAN, or implementation likely wrong; **I** for a material gap that makes the next stage unsafe; **MINOR** for a clarification that still needs an answer but changes little.

A product decision is never filled in by assumption, even when the default looks obvious.

### F6. Handoff

Follow the status table in `SKILL.md` section 6. For a story that touches a repository, name `requirement-review --tech` as the next step before `sdd-spec`.

## Checklist before the report is final

- [ ] Every criterion has an atom table row or a finding
- [ ] Every open question has severity, owner, and one answerable question
- [ ] Status matches the open questions (any unanswered B, I, or MINOR means NEEDS_CLARIFICATION)
- [ ] Q&A entries appended before the wait; prior history consulted first
- [ ] No vague Then; no default written for a product decision
