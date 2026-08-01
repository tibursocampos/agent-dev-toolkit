# Commit Message Format Validator

Validates messages against **Conventional Commits** (Git-only - no work-item tracker APIs).

**Related:** `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/grok/rules/conventional-commits.mdc`, `skills/_shared/developer-common/step-4-commits-pr.md`.

## Expected format

```
<type>(<scope>): <description>

[optional body]

Refs: #<issue>    # optional - GitHub issue or slug
```

| Element | Required | Notes |
|---------|----------|-------|
| `<type>` | Yes | See valid types below |
| `(<scope>)` | Optional | Context of the change |
| `<description>` | Yes | Imperative, concise English |
| `Refs: #…` | Optional | GitHub issue reference in footer |

Do **not** use ticket id as the type prefix (e.g. avoid `feat(42):`).

## Valid types

`feat` | `fix` | `refactor` | `test` | `docs` | `ci` | `chore` | `perf` | `style` | `build` | `revert`

## Validation rules

### Rule 1: Type validation

- **Regex:** `/^(feat|fix|refactor|test|docs|ci|chore|perf|style|build|revert)(\(.+\))?:/`
- **Severity:** Suggestion
- **Common fixes:** `added` -> `feat`, `fixed` -> `fix`, `update` -> `refactor`, `bugfix` -> `fix`, `feature` -> `feat`

### Rule 2: Description present

- First line must have non-empty description after `:`
- **Severity:** Error

### Rule 3: Description quality (optional - `--strict` only)

- **Severity:** Nitpick
- Minimum ~10 characters; avoid generic-only text (`changes`, `updates`, `fixes`)

### Rule 4: No Cursor co-author attribution

- **Forbidden:** `Co-authored-by:` lines naming Cursor (any email/domain), Antigravity, or any AI agent - in body or footers
- **Forbidden:** `git commit --trailer` / `--trailer=…` (or equivalent) used to add co-author trailers
- **Severity:** Error
- **Fix:** Remove the trailer/footer; commit with approved Conventional Commits text only (`-F` preferred)
- **Post-commit:** if the IDE injects `Co-authored-by: Cursor`, amend with the same approved file; re-check `git log -1 --format=%B`

### Rule 5: Exceptions (auto-skip - do not validate)

- Merge commits: `Merge branch …` / `Merge pull request …`
- Initial commits: `Initial commit` / `First commit`
- Revert commits (auto-generated): `Revert …`

## Validation result

Per commit: `{ isValid, isException, issues[], suggestedFix? }`

- `isValid = true` when there are no non-nitpick issues
- `isException = true` -> skip validation
- `suggestedFix` = corrected first line with proper type/scope

## Context modes

| Context | Check type | Check description | Check footer |
|---------|------------|-----------------|--------------|
| PR review (default) | Yes | No | Warn if malformed |
| PR review (`--strict`) | Yes | Yes | Yes |
| PR review (`--blockers-only`) | No | No | No |
| Pre-commit | Yes | No | Optional |

## Report template (final summary)

```markdown
### Commit messages

**Commits reviewed:** 5
**Valid:** 4 (80%)
**With issues:** 1 (20%)

| Commit | Status | Issues |
|--------|--------|--------|
| `abc123` | Valid | - |
| `def456` | Invalid | Missing type prefix |

**Suggestion** - commit `def456`:
**Current:** `added export endpoint`
**Suggested:** `feat(export): add export endpoint`
```

---

**Version:** 1.0.0 (agent-dev-toolkit)
