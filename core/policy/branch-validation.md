---
description: Block commit and push from integration branches; the repository defines its own branch names and flow
alwaysApply: true
---

# Branch validation before commit/push

## Rule

Before any `git add`, `git commit`, or `git push`, verify the current branch name.

Branch names and the branch flow belong to each repository. Follow the repository's own conventions (its `.github/`, `CONTRIBUTING`, or docs) and the operator's explicit branch request.

### Blocked branches

Do not commit or push from the integration branches `main`, `master`, or `develop`, or from the repository's default branch when it has another name.

## How to verify

**PowerShell (Windows)**

```powershell
$branch = git rev-parse --abbrev-ref HEAD
$blocked = @('main', 'master', 'develop')
if ($branch -in $blocked) {
  Write-Error "Blocked: do not commit or push from integration branch '$branch'"
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
```

## If blocked

1. Choose a slug or id for the work (PRD/PLAN name, issue id, or short topic).
2. Create a work branch using the repository's convention or the operator's name, for example `git checkout -b <branch-name>`.
3. Re-run the commit flow (`commit` skill or your git commands).

## Integration-branch stop before code changes

This stop applies only to `orchestrate-develop`, `sdd-develop`, `developer`, and `*-developer`. Those skills show the current branch and, when it is `main`, `master`, or `develop`, stop before changing code. They propose a work branch and create it only after **sim**.

`sdd-spec`, `sdd-plan`, `orchestrate-analyze`, `orchestrate-deliver`, and every other skill write on the current branch. They do not show the branch and do not ask for a branch switch.

## Where commit and push still apply

- `commit` skill - before staging or committing
- `sdd-develop`, `developer`, and `*-developer` - same stop as `developer-common` step 3, before code changes
- Any agent-initiated commit or push from a development skill

Commit and push remain refused on an integration branch. That refusal does not move the stop into spec, plan, analyze, or deliver.

## Install path

After `scripts/sync-agent.ps1`: `{{TOOLKIT_ROOT}}/rules/branch-validation.mdc` (see `docs/INSTALL.md`)
