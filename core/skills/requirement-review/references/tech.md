# Mode playbook: --tech

**Load only when mode = `--tech`.** Do not load `feature.md` in the same run. Shared rules (severity, question format, Q&A, report, handoff) live in `SKILL.md`; they are not repeated here.

## Scope

Repository-grounded technical review of a Technical Story (`TSnn`), or of a User Story whose contracts, data, or flows touch the target repository. Read-only. The review checks what the source assumes against what the repository shows. It does not design the solution.

## Steps

### T1. Confirm repository and technical scope

- Target repository: the workspace, confirmed once in the user chat language when unclear.
- From the source, list the named technical items: components, endpoints, events or messages, entities or tables, configuration keys, external systems.
- Nothing named and no area identifiable: `blocked`. Ask one question (severity **B**, owner **Engineering**) for the area to review.

### T2. Ground each named item (search, do not guess)

For each named item:

1. Search with Glob and Grep for its name and close variants (route templates, DTO or type names, event names, table names, configuration keys).
2. Record the term, the search pattern used, and the hits as portable paths.
3. Read only the matched excerpts. Do not dump whole modules.
4. No hit: record `not-found`. A source that asserts the item exists and finds no hit is a `CONTRADICTION`. An item the source introduces as new is not a finding.

Never state a repository fact that has no hit in the record.

### T3. Affected surfaces

Build an impact table:

| Surface | Item | Portable path | Known consumers (by search) | Change the source implies |
|---------|------|---------------|-----------------------------|---------------------------|
| API contract \| event \| data model \| background job \| configuration \| UI contract | <name> | <path> | <paths or none found> | add \| modify \| remove |

Identify the surfaces. Do not propose architecture or a design; that work belongs to the O1 specialists and to `sdd-spec`.

### T4. API contracts

When an HTTP or event API contract is affected:

- Read `{{TOOLKIT_ROOT}}/skills/api-standards/SKILL.md`, then only the reference file that matches the concern (naming, errors and pagination, versioning, REST shape, security).
- Check the affected contract against that guidance. Each deviation becomes a finding that cites the reference file by path.
- Do not copy the guidance into the report.

### T5. Data flows

Trace the flow the source describes, from its entry point (caller, handler, consumer) to persistence or egress:

- One line per hop: component, portable path, and the data item crossing the boundary.
- Note where the source is silent about: transaction boundary, retry or idempotency, data ownership, ordering, failure handling.
- A silence that changes behavior is a `GAP`. Two sources that disagree about ownership are a `CONTRADICTION`.

### T6. Classify

| Situation | Output |
|-----------|--------|
| Source conflicts with repository evidence | `CONTRADICTION` finding, with the portable path as evidence |
| Source omits a case the repository shows | `GAP` finding |
| Another team, system, or contract owner is needed | `DEPENDENCY` finding |
| Consequence the source does not acknowledge | `RISK` finding |
| Decision that changes the requirement (which of two contracts is authoritative, which behavior is intended) | Open question with severity **B**, **I**, or **MINOR**, owner **Product** or **Engineering** |
| Implementation detail the PRD must settle (versioning step, migration order, naming within an existing contract) | **Technical follow-up** for `sdd-spec`. Not a question; it does not block READY |

### T7. Technical follow-ups section

List each follow-up as one line: the item, the portable path that raised it, and the decision the PRD must record. Keep the list short. The follow-up list travels with the handoff.

```markdown
## Technical follow-ups for sdd-spec (non-blocking)
- <item> - <portable path> - PRD must record <decision>
```

### T8. Handoff

Follow the status table in `SKILL.md` section 6. Cite the follow-up list in the handoff line; do not paste it into the slash command.

## Checklist before the report is final

- [ ] Each named item has a search record: pattern, hits or `not-found`
- [ ] No repository fact without a hit
- [ ] Affected surfaces listed with portable paths
- [ ] API guidance cited by reference, not copied, and only when an API contract is affected
- [ ] Implementation details recorded as follow-ups, not as questions
- [ ] Status matches the open questions
