# 08 — Git and repository docs

`commit`, `push`, and `open-github-pr` never use chat compression. They do not open a pull request except through `open-github-pr`. None of them force-push `main`, `master`, or `develop`.

Allowed heads: `feature/<slug>` or `feat/<id>` (one segment). Blocked: `main`, `master`, `develop`, nested `feature/a/b`.

## `commit`

Drafts a Conventional Commit and **waits**. Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`. Subject and body in English. Approve the exact text before `git commit`. Prefer explicit paths over `git add -A`.

Before staging, if not already answered in this turn:

| Present | Ask |
|---------|-----|
| `memory-bank/` | refresh-light? **sim** / **pular** |
| `docs/documentation-plan/plan.md` or `docs/overview.md` or `docs/domains/` | update project docs? **sim** / **pular** |

**sim** on the bank runs `/memory-bank-init` refresh-light. **sim** on docs runs `/document-implement` if a plan step is pending, otherwise `/document-plan`.

After every commit, read `git log -1`. A `Co-authored-by` trailer (any agent) is stripped with amend until it is gone. Do not finish while that trailer remains. Do not add `--author` or `--trailer` for an agent.

Push only when asked: that is `/push`. A pull request is `/open-github-pr`, not a web compare link from this skill.

## `push`

`git push -u origin HEAD` after the branch check. On success, if this conversation already asked for a pull request, load `open-github-pr` immediately. Otherwise ask whether to open one. **sim** enters that skill. The GitHub web UI is not offered from `/push`.

## `open-github-pr`

This skill owns `gh pr create`. Ad-hoc `gh pr create` is out of contract.

| Mode | Head | Base | Auto-merge method |
|------|------|------|-------------------|
| `feature` (default only if the operator accepts that default) | current `feature/*` or `feat/*` | `develop` | `--squash` |
| `release` | `develop` | `master` or `main` (ask if both exist on `origin`) | `--rebase` |

Ask once if the mode was omitted.

Content confirmation is separate from auto-merge. Show title, base, head, full body, and template path. **sim** / **ajustar** / **cancelar** on the content. Then, every time, including “full flow”: enable auto-merge? **sim** / **não**. Do not infer auto-merge from the earlier request to open a PR.

If the repository disallows auto-merge, still create the PR and say auto-merge cannot be enabled. If the required method (squash or rebase) is disabled, stop and ask. Do not switch methods silently.

Needs authenticated `gh`. If the branch is not on `origin`, hand off to `/push` first.

## `help-skills`

Read-only. Presents `core/skills/_shared/skills-catalog/CATALOG.md` and, when the question is about confirmations or quirks, `OPERATOR.md`. It does not load every `SKILL.md` and does not invent ids. Shared packs and the architect role are not skills. There is no `open-pr` id; the id is `open-github-pr`.

No write gate for a catalog answer. Invoke forms: `/help-skills`, `$help-skills`, `use skill help-skills`, or the host’s skill tool.

## `document-plan` and `document-implement`

These write repository documentation for retrieval. They do not write feature `PLAN/PLAN_*.md`.

`document-plan` asks once: product `docs/` in **pt-BR** or **English**. For this toolkit the answer is English. It writes `docs/overview.md` and `docs/documentation-plan/plan.md`. Domain pages are steps on that plan, executed later.

`document-implement` requires that plan. It runs **one** pending step per session, then stops. Language comes from the plan header. Missing language: ask before writing. Verification is “the files named in the step exist and match the code”, not an application test suite. Session gates for that plan path are `step_confirmed` and `tests_run` on `plan-{hash}.json`.

Next pending step is a new chat of `/document-implement`. All steps done: optional `/code-review` or `/commit`.
