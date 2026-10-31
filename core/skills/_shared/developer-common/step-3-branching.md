# Step 3: Branch management

**Goal:** Work on a work branch before editing tracked files.

This integration-branch stop applies only to `developer`, `*-developer`, `sdd-develop`, and `orchestrate-develop`. Those skills show the current branch and apply the stop before changing code. `sdd-spec`, `sdd-plan`, `orchestrate-analyze`, and `orchestrate-deliver` do not use this step and do not propose a branch switch.

Canonical rule: `{{TOOLKIT_ROOT}}/rules/branch-validation.mdc` (overrides this file if they differ).

---

## 3.1. Branch name

The repository defines its branch naming and flow. Use its convention (its `.github/`, `CONTRIBUTING`, or docs). When the repository says nothing, use a short kebab-case name that describes the work, for example `feature/add-oauth-login`, and confirm it with the user.

---

## 3.2. Blocked branches

Do **not** commit or implement on:

- `main`, `master`, `develop` (or the repository's default integration branch)

---

## 3.3. Create or checkout branch

Open workspace only - no clone into `projects/{repo}`.

```bash
git fetch origin
git checkout <baseline>          # the baseline the user or PLAN names; confirm with the user
git pull origin <baseline>       # if team uses pull before branch

git checkout -b <work-branch>    # name from 3.1
# first push when ready:
git push -u origin HEAD
```

If the branch already exists locally or on remote, checkout and pull/rebase per team practice.

**PowerShell check** (same rule as `branch-validation.mdc`):

```powershell
$branch = git rev-parse --abbrev-ref HEAD
$blocked = @('main', 'master', 'develop')
if ($branch -in $blocked) {
  Write-Error "Blocked: do not implement on integration branch '$branch'"
  exit 1
}
```

---

## 3.4. Critical rules

| Never | Always |
|-------|--------|
| Edit on `main` / `master` / `develop` | Branch from the baseline the user or PLAN names |
| Force-push without explicit user request | Confirm branch before first file edit |

---

## 3.5. Error handling

| Situation | Action |
|-----------|--------|
| Branch already exists | Checkout existing branch |
| Dirty working tree | Resolve with user (stash, commit, or discard) before switching |
| Permission denied on push | Report; user fixes credentials or permissions |

---

## Step 3 checklist

- [ ] Current branch is not an integration branch (`main`, `master`, `develop`)
- [ ] Branch name follows the repository convention, or the user confirmed it
- [ ] Baseline branch confirmed with user when PLAN is silent
- [ ] Remote tracking set after first push (if pushing)
