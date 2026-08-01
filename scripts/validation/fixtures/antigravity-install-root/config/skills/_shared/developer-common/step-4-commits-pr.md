# Step 4: Commits and pull request (Git-only)

**Goal:** Atomic conventional commits, push, and optional GitHub PR - no work-item tracker APIs.

Rules: `{{TOOLKIT_ROOT}}/rules/conventional-commits.mdc`, `{{TOOLKIT_ROOT}}/rules/branch-validation.mdc`.  
Validator (when installed): `{{TOOLKIT_ROOT}}/skills/_shared/format-validators/commit-message-validator.md`.

---

## 4.1. Commit message format

```
<type>(<scope>): <description>

[optional body]

Refs: #<issue>    # optional - GitHub issue or slug
```

| Element | Required | Examples |
|---------|----------|----------|
| Type | Yes | `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `perf`, `style` |
| Scope | Optional | `(auth)`, `(orders)` |
| Description | Yes | Imperative, concise English |
| Footer | Optional | `Refs: #42` |

**Examples:**

```text
feat(orders): add cancellation endpoint

Refs: #42
```

Do not use `feat(42):` or ticket id as the **title** type prefix.

---

## 4.2. Atomic commits

One logical change per commit.

Suggested order: domain -> interfaces -> application -> infrastructure -> API -> tests -> config.

**Never (unless user explicitly requests):**

- `git add -A` / `git add .` without review
- `git commit --amend` on shared/pushed history
- `git push --force` to `main` / `master` / `develop`
- Cursor co-author attribution: `Co-authored-by: Cursor …` in the message, or `git commit --trailer` / `--trailer=…` (or any trailer flag) for co-author lines
- Leaving a commit with `Co-authored-by:` in `git log -1` after the agent ran commit (amend with approved message only; `--no-verify` on amend only to strip IDE-injected trailers)

Stage explicit paths:

```bash
git add path/to/changed/files
git commit -F path/to/approved-message.txt
git log -1 --format=%B    # must not contain Co-authored-by:
git push -u origin HEAD
```

---

## 4.3. Before commit

1. Branch passes `branch-validation.mdc`.
2. Run step 3.5 (or user skipped with acknowledgment).
3. Validate message format (validator or rule).

Ask user to approve message before committing when the skill is interactive.

---

## 4.4. Pull request (optional, user-driven)

Create a PR only when the user asks. Use the repository’s template if present (`.github/pull_request_template.md`).

Default integration base is **`develop`**. Release PRs are **`develop` → `master`/`main`** (not feature → release).

**Open the PR in the GitHub web UI** (no CLI required):

1. Push the feature branch (`git push -u origin HEAD`) after user confirmation.
2. Open the repository on GitHub → **Compare & pull request** (or **Pull requests** → **New**).
3. Set base to `develop` (or the base the user/PLAN specifies) and head to the current feature branch.
4. Fill title/body from the template; include Summary and Test plan.

| Element | Guidance |
|---------|----------|
| Base branch | Default `develop`; release PR uses `master`/`main` with head `develop`. Override only if user or PLAN says otherwise |
| Title | Conventional summary or repo convention - not tracker `id - title` only |
| Body | Summary, test plan, breaking changes |
| Links | `Refs #42` / `Fixes #42` in body when applicable |

No MCP work-item linking, no corporate PR template APIs, no mandatory `pr-analyzer` step.

---

## 4.5. After commit

- Confirm `git status` clean (or only intentional untracked files).
- For SDD: update PLAN via `sdd-develop` skill before starting the next step in a new chat.

---

## Step 4 checklist

- [ ] Commits follow Conventional Commits
- [ ] Branch valid and pushed (if push requested)
- [ ] No secrets in committed files
- [ ] PR created only if user requested, with sensible base branch
- [ ] Optional issue reference in footer, not in type prefix
