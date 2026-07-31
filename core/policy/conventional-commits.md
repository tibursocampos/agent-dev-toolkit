---
description: Require Conventional Commits for every git commit message
alwaysApply: true
---

# Conventional Commits

Every `git commit` must follow [Conventional Commits](https://www.conventionalcommits.org/).

## Format

```
<type>[optional scope][!]: <description>

[optional body]

[optional footer(s)]
```

## Valid types

| Type | Use |
|------|-----|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting, no logic change |
| `refactor` | Refactor without fix or feat |
| `perf` | Performance improvement |
| `test` | Add or fix tests |
| `build` | Build system or dependencies |
| `ci` | CI/CD configuration |
| `chore` | Maintenance without production code impact |
| `revert` | Revert a previous commit |

## Rules

- Subject line: lowercase description, no trailing period
- Use `!` after type/scope for **BREAKING CHANGE** (e.g. `feat!:` or `feat(api)!:`)
- Optional scope in parentheses: `feat(auth):`
- Separate body and footers from the subject with a blank line

## Forbidden (commit command and message)

**Never** attribute Cursor, Antigravity, or any AI agent as a co-author - not in the message, not via Git trailers:

- Under NO circumstances should you include `Co-authored-by: Cursor <cursoragent@cursor.com>`, `Co-authored-by: Antigravity`, or any other AI agent attribution in the commit message or body. The commit message must contain JUST the commit message.
- No `git commit --trailer` / `--trailer=…` for co-author attribution
- No extra `-m` blocks or `--author` overrides added for Cursor attribution
- **Agents:** after `git commit`, run `git log -1 --format=%B`. If `Co-authored-by:` appears (often injected by the IDE), amend immediately with the approved message only - see `/commit` §5.1. Use `--no-verify` on amend **only** when needed to drop an unauthorized co-author trailer.

Allowed footers: `Refs: #…`, `BREAKING CHANGE:`, `Fixes: #…` - per project convention only. **Not** `Co-authored-by:` for AI tools.

## Examples

```
feat: add OAuth authentication
fix(api): correct request timeout
docs(readme): update install steps
refactor(db): extract connection module
feat!: remove Node 14 support

BREAKING CHANGE: /login endpoint removed
```

## Install path

After `scripts/sync-cursor.ps1`: `{{TOOLKIT_ROOT}}/rules/conventional-commits.mdc` (see `docs/INSTALL.md`)
