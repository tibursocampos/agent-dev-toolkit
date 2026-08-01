---
description: Block commit and push unless the branch matches feature/<slug> or feat/<id>
alwaysApply: true
---

# Branch validation before commit/push

## Rule

Before any `git add`, `git commit`, or `git push`, verify the current branch name.

### Allowed patterns

| Pattern | Example |
|---------|---------|
| `feature/<slug>` | `feature/add-oauth-login` |
| `feat/<id>` | `feat/123`, `feat/issue-42` |

- `<slug>` - kebab-case or alphanumeric segment (no extra `/`)
- `<id>` - ticket, issue number, or short identifier (no extra `/`)

### Blocked branches

Do not commit or push from:

- `main`, `master`, `develop`, or other default integration branches
- Branches that do not match the patterns above

**Valid examples**

```
feature/user-profile-api
feature/fix-null-ref
feat/123
feat/PLAN-001-cursor-toolkit
```

**Invalid examples**

```
main
develop
feature/
feat/
feature/base/extra-segment
hotfix/urgent-fix
```

## How to verify

**PowerShell (Windows)**

```powershell
$branch = git rev-parse --abbrev-ref HEAD
$blocked = @('main', 'master', 'develop')
if ($branch -in $blocked -or $branch -notmatch '^(feature|feat)/[^/]+$') {
  Write-Error "Blocked: branch '$branch' must be feature/<slug> or feat/<id>"
  exit 1
}
```

**Bash**

```bash
BRANCH=$(git rev-parse --abbrev-ref HEAD)
case "$BRANCH" in
  main|master|develop)
    echo "Blocked: do not commit on '$BRANCH'"
    exit 1
    ;;
esac
if [[ ! "$BRANCH" =~ ^(feature|feat)/[^/]+$ ]]; then
  echo "Blocked: branch '$BRANCH' must be feature/<slug> or feat/<id>"
  exit 1
fi
```

## If blocked

1. Choose a slug or id for the work (PRD/PLAN name, issue id, or short topic).
2. Create and switch to a valid branch:
   ```bash
   git checkout -b feature/<slug>
   # or
   git checkout -b feat/<id>
   ```
3. Re-run the commit flow (`commit` skill or your git commands).

## Where this applies

- `commit` skill - before staging or committing
- `sdd-develop` skill - aligns with branching step in `developer-common`
- Any agent-initiated commit or push

## Install path

After `scripts/sync-cursor.ps1`: `{{TOOLKIT_ROOT}}/rules/branch-validation.mdc` (see `docs/INSTALL.md`)
