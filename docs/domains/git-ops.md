# Domain: Git ops

Day-to-day Git flow after code changes: Conventional Commits, push, and optional GitHub PR via `gh`. Skills live under `core/skills/` (`commit`, `push`, `open-github-pr`) and share branch rules plus the shared handoff in `core/skills/_shared/developer-common/step-4-commits-pr.md`.

Public catalog: [SKILLS.md](../SKILLS.md). Operator notes: installed `OPERATOR.md` via `help-skills`; human deep dive for git: this file. Also [CONTRIBUTING.md](../../CONTRIBUTING.md).

## Skill chain

```text
/code-review   (optional)
/commit
/push
/open-github-pr   (optional — when opening a PR)
```

| Skill | Slash | Job |
|-------|-------|-----|
| `commit` | `/commit` | Draft Conventional Commits message; commit only after approval; strip AI co-author trailers |
| `push` | `/push` | `git push -u origin HEAD` on a valid feature branch |
| `open-github-pr` | `/open-github-pr` | Create PR with `gh pr create` (feature or release mode), template resolution, optional auto-merge |

Do not invent force-pushes to `main` / `master` / `develop`.  

**Handoff rule:** `/commit` and `/push` must **not** open PRs themselves (`gh pr create` / web compare). After a successful push, `/push` either hands off immediately when PR intent was already clear (`fluxo completo`, `abra o PR`, `commit + push + PR`, …) or asks whether to continue with **`/open-github-pr`**. That skill owns create + **mandatory** auto-merge confirmation. Prefer `/open-github-pr` over the web UI when `gh` is available; web UI remains a fallback only inside that skill (see step-4).

**Agent rule:** never short-circuit with ad-hoc `gh pr create` from chat/`/commit`/`/push`. Always **Read** `core/skills/open-github-pr/SKILL.md` and run its confirmation + auto-merge ask.

## Branch rules

Policy source: `core/policy/branch-validation.md` (published as `branch-validation.mdc` after sync).

| Context | Allowed head | Blocked |
|---------|--------------|---------|
| `/commit`, `/push`, feature PR | `feature/<slug>` or `feat/<id>` (single segment after prefix) | `main`, `master`, `develop`, nested `feature/a/b`, other patterns |
| Release PR | Head must be `develop` | Feature branch into `master`/`main` |

Create a valid branch before staging:

```bash
git checkout -b feature/<slug>
# or
git checkout -b feat/<id>
```

## Confirmation gates

| Skill | Must confirm before |
|-------|---------------------|
| `/commit` | Commit message text (never auto-commit) |
| `/push` | Guardrails/session re-check when missing; then push |
| `/open-github-pr` | Mode (feature vs release if omitted), full title/body, **and** whether to enable auto-merge (ask every time; do not infer from “fluxo completo”) |

User **sim** (or explicit approve) is required for mutating Git and for PR create. Skills ignore Caveman compression for commit/PR prose.

## Feature vs release PR

| Mode | Head → base | When |
|------|-------------|------|
| **Feature** (default) | current `feature/*` or `feat/*` → `develop` (override only if user/PLAN says otherwise) | Day-to-day after push |
| **Release** | `develop` → `master` or `main` (detect which exists on `origin`) | Release train — never feature → release |

Release PRs into `master`/`main` must come from `develop` (CI: [`.github/workflows/enforce-release-source.yml`](../../.github/workflows/enforce-release-source.yml)). Required check for this repo: **validate** ([`validate-toolkit.yml`](../../.github/workflows/validate-toolkit.yml)).

## `/open-github-pr` flow (summary)

1. Resolve mode (`feature` / `release`).
2. Validate head/base for that mode.
3. Preflight: `gh` on `PATH`, then OS fallbacks (Windows Program Files; macOS Homebrew; Linux `/usr/bin` / `~/.local/bin`) and `gh auth status`.
4. Ensure head is pushed (`/push` handoff if no upstream or local commits missing on `origin`).
5. Resolve body template (repo first, then skill fallbacks).
6. Draft title/body; for release, fill Included PRs table and commits (`origin/<base>..origin/develop`).
7. Confirm with user; detect `allow_auto_merge` via GitHub API.
8. `gh pr create --base … --head … --title … --body-file …`; optional `gh pr merge … --auto --merge` when approved and allowed.

### Template resolution

**Feature mode** (first match wins):

1. `.github/PULL_REQUEST_TEMPLATE.md`
2. `.github/pull_request_template.md`
3. Any `.md` under `.github/PULL_REQUEST_TEMPLATE/` — prefer `feature.md` if present
4. Else: `core/skills/open-github-pr/templates/feature-pr.md`

**Release mode** (first match wins):

1. `.github/PULL_REQUEST_TEMPLATE/release.md`
2. Else: `core/skills/open-github-pr/templates/release-pr.md`

In this repository the feature template is [`.github/PULL_REQUEST_TEMPLATE.md`](../../.github/PULL_REQUEST_TEMPLATE.md) and the release template is [`.github/PULL_REQUEST_TEMPLATE/release.md`](../../.github/PULL_REQUEST_TEMPLATE/release.md).

## Failure modes (no secrets)

| Symptom | Action |
|---------|--------|
| Invalid branch for commit/push/feature PR | Stop; create `feature/<slug>` or `feat/<id>` |
| Release head not `develop` / base not `master`\|`main` | Stop; fix checkout and base |
| `gh` missing or not logged in | Install [GitHub CLI](https://cli.github.com/), run `gh auth login`, re-invoke |
| Branch not on `origin` | `/push`, then re-invoke `/open-github-pr` |
| Auto-merge requested but repo disallows it | Create PR; report auto-merge unavailable |
| `Co-authored-by:` after commit | Amend per `/commit` §5.1 (approved message only) |

Never put tokens, org-only credentials, or private URLs in commit messages, PR bodies, or docs.

## Handoffs

| After | Next |
|-------|------|
| `/commit` | `/code-review` (optional), `/push`, or `/open-github-pr` when user asks for a PR |
| `/push` | `/open-github-pr` or `/code-review` |
| Branch not pushed before PR | `/push` → `/open-github-pr` |
| Mid-PLAN | New chat → `/sdd-develop` for the next step |

Shared detail: `core/skills/_shared/developer-common/step-4-commits-pr.md`.

## Related

- [domains/core.md](core.md) — Ops skill group in the core tree
- [guides/02-using-skills.md](../guides/02-using-skills.md) — after-implementation chain
- [guides/README.md](../guides/README.md) — decision tree post-code path
- [overview.md](../overview.md)
