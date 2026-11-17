# Format Validators

Optional output-format diagnostics and authoring guidance for consistent, reviewable artifacts.

## Purpose

Help authors compare generated documents and messages with toolkit templates. These checks do not define universal handoff or implementation gates; each workflow's active contract remains authoritative.

## Available validators

| Validator | File | Description |
|-----------|------|-------------|
| **PRD content checklist** | `feature-validator.md` | Maps optional authoring guidance to `templates/sdd/PRD.md`; `scripts/validation/validate-prd.ps1` is an optional structural diagnostic |
| **Commit message validator** | `commit-message-validator.md` | Conventional Commits (Git-only) |
| **PR comment validator** | `pr-comment-validator.md` | Inline review comment structure (GitHub/generic) |

Deferred (not in MVP): ADR validator, tech-details validator, README validator.

## How to use

When generating an output, consult the guidance or run a diagnostic when useful or explicitly requested:

1. Consult matching guidance when useful; run a diagnostic only when useful or explicitly requested.
2. Check relevant content and placeholders. Do not require exact headings, fixed counts, or optional fields unless the active workflow or user explicitly requires them.
3. For a diagnostic mismatch, inspect whether behavior, acceptance, scope, or a relevant contract is actually unclear. Equivalent content does not need rewriting to satisfy document grammar.

## Validation levels

### Level 1: Structure (optional diagnostic)

- Required sections present
- Section order matches template
- Correct markdown heading levels (`##`, `###`)

### Level 2: Content (recommended)

- Required fields filled (no bracket placeholders)
- Field formats (dates, IDs, enums)
- Lists and checkboxes in expected shape

### Level 3: Quality (optional)

- Minimum description length
- Well-formed acceptance criteria
- Actionable, specific tasks

## Skill integration

| Skill | Validator | When |
|-------|-----------|------|
| **spec** | `scripts/validation/validate-prd.ps1` | Optional diagnostic when requested or useful for a concrete issue; not a handoff prerequisite |
| **commit** | `commit-message-validator.md` | Before `git commit` |
| **code-review** | `commit-message-validator.md`, `pr-comment-validator.md` | When summarizing commits or drafting review comments |

See `INTEGRATION-GUIDE.md` for step-by-step wiring.

## Troubleshooting

- Too strict: use level `structure` only.
- False positives: interpret them against the active workflow and the content; do not treat a diagnostic as authorization to block handoff.
- Auto-fix broke content: review preview before applying.

**Version:** 1.0.0 (agent-dev-toolkit)
