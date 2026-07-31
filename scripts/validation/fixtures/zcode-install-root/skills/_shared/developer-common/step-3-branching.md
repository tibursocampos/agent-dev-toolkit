# Step 3: Branch management

**Goal:** Work on a valid feature branch before editing tracked files.

Canonical rule: `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/rules/branch-validation.mdc` (overrides this file if they differ).

---

## 3.1. Allowed branch patterns

| Pattern | Example |
|---------|---------|
| `feature/<slug>` | `feature/add-oauth-login` |
| `feat/<id>` | `feat/42`, `feat/issue-123` |

- `<slug>` - kebab-case topic (no extra `/`)
- `<id>` - issue number or short id (no extra `/`)

---

## 3.2. Blocked branches

Do **not** commit or implement on:

- `main`, `master`, `develop` (or other default integration branches)
- `feature/`, `feat/` (empty segment)
- Nested paths such as `feature/parent/child` or `feature/base/123`

---

## 3.3. Create or checkout branch

Open workspace only - no clone into `projects/{repo}`.

```bash
git fetch origin
git checkout <baseline>          # e.g. main or develop - user confirms
git pull origin <baseline>       # if team uses pull before branch

git checkout -b feature/<slug>   # or feat/<id>
# first push when ready:
git push -u origin HEAD
```

If the branch already exists locally or on remote, checkout and pull/rebase per team practice.

**PowerShell check** (same rule as `branch-validation.mdc`):

```powershell
$branch = git rev-parse --abbrev-ref HEAD
$blocked = @('main', 'master', 'develop')
if ($branch -in $blocked -or $branch -notmatch '^(feature|feat)/[^/]+$') {
  Write-Error "Blocked: branch '$branch' must be feature/<slug> or feat/<id>"
  exit 1
}
```

---

## 3.4. Critical rules

| Never | Always |
|-------|--------|
| Edit on `main` / `develop` | Branch from agreed baseline |
| Use nested `feature/a/b` | Use `feature/<slug>` or `feat/<id>` |
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

- [ ] Current branch matches `feature/<slug>` or `feat/<id>`
- [ ] Not on blocked default branch
- [ ] Baseline branch confirmed with user when PLAN is silent
- [ ] Remote tracking set after first push (if pushing)
