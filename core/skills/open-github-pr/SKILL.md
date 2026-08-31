---
name: open-github-pr
description: >
  Create a GitHub pull request with gh CLI (feature → develop or release develop → master/main),
  template resolution, mandatory title/body confirmation, and mandatory auto-merge ask.
  Use whenever the user wants a PR opened — including /open-github-pr, open PR, create pull request,
  abrir PR, criar PR, abrir o PR, faça o PR, fazer o PR, open the PR, open a pull request,
  fluxo completo (when PR is in scope), commit+push+PR, push and open PR, release PR,
  or any handoff from /commit or /push that implies opening a pull request.
  Never create a PR with ad-hoc gh commands outside this skill; follow this SKILL.md end-to-end.
---

## STOP - Read before ANY tool call

1. Read `{{GUARDRAILS_PATH}}`
2. Read `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/SESSION.md`; load session-state for `$Cwd`
3. If the relevant gate is not approved: **STOP** - ask user **(pt-BR)** - do **NOT** Write/Shell
4. SDD/develop skills: after **ONE** step/task, **STOP** session - handoff only
5. This skill body is **English**; user-facing prompts may be **(pt-BR)**

### Step -1 - Gate check (report in chat before continuing)

```
Gate check:
[ ] guardrails.mdc read
[ ] SESSION.md read; session-state loaded
[ ] PIPELINE.md read (SDD skills only)
[ ] User confirmed current action (sim)
-> If any unchecked: STOP
```

---

# Skill: open-github-pr

## Trigger

Invoke when **any** of these apply (slash, English, or pt-BR — including bundled “full flow” requests):

| Kind | Examples |
|------|----------|
| Slash | `/open-github-pr` |
| Explicit EN | `open PR`, `open the PR`, `create pull request`, `create a PR`, `open a pull request`, `make a PR` |
| Explicit pt-BR | `abrir PR`, `abrir o PR`, `criar PR`, `criar o PR`, `faça o PR`, `fazer o PR`, `abre o PR`, `abra o PR` |
| Bundled flow | `fluxo completo`, `faça o fluxo completo`, `commit push e PR`, `commit + push + PR`, `depois abra o PR`, `push and open PR` — after `/commit`/`/push` finish, **this** skill owns the PR step |
| Handoff | User answers **sim** to `/push`’s “Abrir pull request com /open-github-pr?” prompt; or `/commit`/`/code-review` hand off for PR |

### Agent routing (mandatory)

1. **Before** any `gh pr create`, `gh pr merge`, or web Compare & pull request steps: **Read this entire `SKILL.md`** and follow Steps -1 → 8 in order.
2. Do **not** invent a shortcut PR (raw `gh pr create` from `/commit`, `/push`, or ad-hoc chat). Those skills only **hand off** here.
3. If the user already said they want a PR in the same message as commit/push (“fluxo completo”, “abra o PR”, etc.): after push succeeds, **enter this skill immediately** (do not skip confirmation or the auto-merge question).
4. Step 6 is **never optional**: always present title/base/head/body **and** ask auto-merge (`sim` / `não`), including when `allow_auto_merge` is false (then report unavailable after create if they said sim).

## Outcome

One GitHub pull request created via `gh pr create` (feature → `develop`, or release `develop` → `master`/`main`), using the resolved template, after user confirmation. Optional `gh pr merge --auto` when allowed and approved. No PR without content confirmation **and** an explicit auto-merge answer.

## Lazy-load (only when needed)

| When | Path (after `scripts/sync-cursor.ps1`) |
|------|----------------------------------------|
| Branch rules | `{{TOOLKIT_ROOT}}/rules/branch-validation.mdc` |
| Commit / PR flow | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-4-commits-pr.md` |
| Feature body fallback | `{{TOOLKIT_ROOT}}/skills/open-github-pr/templates/feature-pr.md` |
| Release body fallback | `{{TOOLKIT_ROOT}}/skills/open-github-pr/templates/release-pr.md` |
| Reference index (routing only) | `{{TOOLKIT_ROOT}}/skills/open-github-pr/reference.md` |
| Process step detail (lazy) | `{{TOOLKIT_ROOT}}/skills/open-github-pr/references/<section>.md` |

**Never by default:** do not preload all templates or all `references/*.md`. Load **one** section per Process step (`SKILL-REFERENCE-RETRIEVAL.md`). Never load `CAVEMAN.md` for this skill.

## Reference routing

| Situation | Path |
|-----------|------|
| Guards / mode | `references/guards-and-mode.md` |
| Validate branch | `references/validate-branch.md` |
| Preflight (gh) | `references/preflight.md` |
| Ensure pushed | `references/ensure-pushed.md` |
| Resolve template | `references/resolve-template.md` |
| Draft title/body | `references/draft-title-body.md` |
| Confirm and create | `references/confirm-and-create.md` |
| Must not (full) | `references/must-not.md` |
## Process

Read `references/<section>.md` for procedural detail — **not** full `reference.md`. Do not skip gates.

### -1 / 0. Guards and mode
Follow `references/guards-and-mode.md` (Caveman **NEVER**; re-check guardrails; resolve `feature` vs `release` mode).

### 1. Validate branch (blocker)
Follow `references/validate-branch.md`. If blocked, stop — do not create a PR.

### 2. Preflight - GitHub CLI
Follow `references/preflight.md`. Prefer authenticated `gh`; STOP with install help if unavailable.

### 3. Ensure branch is pushed
Follow `references/ensure-pushed.md`. Hand off to `/push` when needed. Never force-push protected branches.

### 4. Resolve PR body template
Follow `references/resolve-template.md`.

### 5. Draft title and body
Follow `references/draft-title-body.md`.

### 6–8. Confirm, create, report
Follow `references/confirm-and-create.md`. Step 6 confirmation **and** auto-merge ask are **mandatory** every time. Always ask (pt-BR): **Habilitar auto-merge após criar?** (`sim` / `não`) — including after **fluxo completo**.
## Must not

Enforce the full list in `references/must-not.md`. Critical always-on: no PR without gate + content `sim` + auto-merge ask; no invalid branch; no force-push; no Caveman compression of title/body; no skipping this `SKILL.md` for ad-hoc `gh pr create`.
## Handoff

| Situation | Next |
|-----------|------|
| Branch not pushed | `/push` then re-invoke `/open-github-pr` |
| Review after PR (optional) | `/code-review` |
| Continue SDD step | New session → `/sdd-develop - <full-plan-path> - Step N` |
| Future unified orchestrator | `/open-pr` — **out of scope** for this skill |
