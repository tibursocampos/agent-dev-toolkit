# Format Validators

Output-format checks so skills produce consistent, reviewable artifacts.

## Purpose

Ensure generated documents and messages follow the templates defined in this toolkit, regardless of which skill produced them.

## Available validators

| Validator | File | Description |
|-----------|------|-------------|
| **PRD content checklist** | `feature-validator.md` | Maps authoring guidance to `templates/sdd/PRD.md`; executable structural gate is `scripts/validation/validate-prd.ps1` |
| **Commit message validator** | `commit-message-validator.md` | Conventional Commits (Git-only) |
| **PR comment validator** | `pr-comment-validator.md` | Inline review comment structure (GitHub/generic) |

Deferred (not in MVP): ADR validator, tech-details validator, README validator.

## How to use

When generating an output:

1. Load the matching validator.
2. Check required sections and fields (no `[placeholder]` left).
3. On failure: log issues, attempt trivial auto-fix if safe, warn the user.

## Validation levels

### Level 1: Structure (required)

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
| **spec** | `scripts/validation/validate-prd.ps1` | After writing PRD and before handoff; `feature-validator.md` is reference guidance |
| **commit** | `commit-message-validator.md` | Before `git commit` |
| **code-review** | `commit-message-validator.md`, `pr-comment-validator.md` | When summarizing commits or drafting review comments |

See `INTEGRATION-GUIDE.md` for step-by-step wiring.

## Troubleshooting

- Too strict: use level `structure` only.
- False positives: mark optional sections in the validator call.
- Auto-fix broke content: review preview before applying.

**Version:** 1.0.0 (agent-dev-toolkit)
