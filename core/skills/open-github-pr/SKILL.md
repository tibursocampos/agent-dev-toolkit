---
name: open-github-pr
description: >
  Create a GitHub pull request with gh CLI against the repository's base branch,
  template resolution, mandatory title/body confirmation, and mandatory auto-merge ask.
  Use whenever the user wants a PR opened — including /open-github-pr, open PR, create pull request,
  abrir PR, criar PR, abrir o PR, faça o PR, fazer o PR, open the PR, open a pull request,
  fluxo completo (when PR is in scope), commit+push+PR, push and open PR, release PR,
  or any handoff from /commit or /push that implies opening a pull request.
  Never create a PR with ad-hoc gh commands outside this skill; follow this SKILL.md end-to-end.
---

## STOP - Read before ANY tool call

Read `_shared/skill-boilerplate.md` first. It holds the guardrails read, the session gate rule, the user `sim` rule, the one-step rule, the gate check, and the user chat language rule. The steps below are skill-specific only.

---

# Skill: open-github-pr

## Trigger
**Negative signal:** applies as defined in `_shared/skill-boilerplate.md`; the skill-specific signals are listed below.

Invoke when **any** of these apply (slash, English, or pt-BR — including bundled “full flow” requests):

| Kind | Examples |
|------|----------|
| Slash | `/open-github-pr` |
| Explicit EN | `open PR`, `open the PR`, `create pull request`, `create a PR`, `open a pull request`, `make a PR` |
| Explicit pt-BR | `abrir PR`, `abrir o PR`, `criar PR`, `criar o PR`, `faça o PR`, `fazer o PR`, `abre o PR`, `abra o PR` |
| Bundled flow | `fluxo completo`, `faça o fluxo completo`, `commit push e PR`, `commit + push + PR`, `depois abra o PR`, `push and open PR` — after `/commit`/`/push` finish, **this** skill owns the PR step |
| Handoff | User answers `confirm` to `/push`’s “Abrir pull request com /open-github-pr?” prompt; or `/commit`/`/code-review` hand off for PR |

### Agent routing (mandatory)

1. **Before** any `gh pr create`, `gh pr merge`, or web Compare & pull request steps: **Read this entire `SKILL.md`** and follow Steps -1 → 8 in order.
2. Do **not** invent a shortcut PR (raw `gh pr create` from `/commit`, `/push`, or ad-hoc chat). Those skills only **hand off** here.
3. If the user already said they want a PR in the same message as commit/push (“fluxo completo”, “abra o PR”, etc.): after push succeeds, **enter this skill immediately** (do not skip confirmation or the auto-merge question).
4. Step 6 is **never optional**: always present title/base/head/body **and** ask auto-merge (`confirm` / `decline`), including when `allow_auto_merge` is false (then report unavailable after create if they answered `confirm`).

## Outcome

One GitHub pull request created via `gh pr create` against the repository's base branch, using the resolved template, after user confirmation. Optional `gh pr merge --auto` when allowed and approved, with the merge method the repository requires (see `references/confirm-and-create.md`). No PR without content confirmation **and** an explicit auto-merge answer.

## Lazy-load (only when needed)

| When | Path (after syncing the active adapter) |
|------|----------------------------------------|
| Branch rules | `{{TOOLKIT_ROOT}}/rules/branch-validation.mdc` |
| Commit / PR flow | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-4-commits-pr.md` |
| Feature body fallback | `{{TOOLKIT_ROOT}}/skills/open-github-pr/templates/feature-pr.md` |
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
Follow `references/guards-and-mode.md` (Caveman **NEVER**; re-check guardrails; resolve the base and the head).

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
Follow `references/confirm-and-create.md`. Step 6 confirmation **and** auto-merge ask are **mandatory** every time. Gate ids and render rule: `core/skills/_shared/agents/QUESTIONS.md`. Always ask the content gate and the auto-merge gate in the user's chat language, including after **fluxo completo**. The auto-merge question asks whether to enable auto-merge after the PR is created, with the `confirm` (enable) and `decline` (do not enable) choices.
## Must not

Enforce the full list in `references/must-not.md`. Critical always-on: no PR without gate + content `confirm` + auto-merge ask; no invalid branch; no force-push; no Caveman compression of title/body; no skipping this `SKILL.md` for ad-hoc `gh pr create`.
## Handoff

| Situation | Next |
|-----------|------|
| Branch not pushed | `/push` then re-invoke `/open-github-pr` |
| Review after PR (optional) | `/code-review` |
| Continue SDD step | New session → `/sdd-develop - <full-plan-path> - Step N` |
| Future unified orchestrator | `/open-pr` — **out of scope** for this skill |
