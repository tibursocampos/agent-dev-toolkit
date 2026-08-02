---
name: open-github-pr
description: Create a GitHub pull request with gh CLI (feature or release mode), template resolution, and optional auto-merge. Use when opening a PR or invoking /open-github-pr.
---

## STOP - Read before ANY tool call

1. Read `{{GUARDRAILS_PATH}}`
2. Read `{{TOOLKIT_ROOT}}/skills/_shared/sdd-opcodes/SESSION.md`; load session-state for `$Cwd`
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

Invoke when the user asks for: `/open-github-pr`, `open PR`, `create pull request`, `abrir PR`.

## Outcome

One GitHub pull request created via `gh pr create` (feature → `develop`, or release `develop` → `master`/`main`), using the resolved template, after user confirmation. Optional `gh pr merge --auto` when allowed and approved. No PR without content confirmation.

## Lazy-load (only when needed)

| When | Path (after `scripts/sync-cursor.ps1`) |
|------|----------------------------------------|
| Branch rules | `{{TOOLKIT_ROOT}}/rules/branch-validation.mdc` |
| Commit / PR flow | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-4-commits-pr.md` |
| Feature body fallback | `{{TOOLKIT_ROOT}}/skills/open-github-pr/templates/feature-pr.md` |
| Release body fallback | `{{TOOLKIT_ROOT}}/skills/open-github-pr/templates/release-pr.md` |

## Process

### Caveman Mode
**NEVER** - This skill ignores `caveman_mode`. Use clear prose always. Do not load `CAVEMAN.md` for chat compression. PR title/body stay normal English.

### -1. Re-check guardrails and session

If missing, ask user (pt-BR):

```text
Antes de abrir o PR, confirme:
- guardrails.mdc lido
- SESSION.md carregado

Posso seguir? (sim / ajustar / cancelar)
```

### 0. Resolve mode

Modes:

| Mode | Meaning | Default base | Head |
|------|---------|--------------|------|
| `feature` | Feature/fix PR into integration | `develop` (or user override) | current `feature/*` or `feat/*` |
| `release` | Promote develop to release | `master` or `main` | `develop` |

Detect from args (`feature` / `release`, aliases `feat`, `release-pr`). If omitted, ask once (pt-BR) and wait — default is **feature** only when the user accepts the default or says nothing after you present it:

```text
Modo do PR?
1) feature (padrão) - feature/*|feat/* → develop
2) release - develop → master|main
```

### 1. Validate branch (blocker)

Enforce mode-specific rules (also respect `branch-validation.mdc` for feature heads):

**Feature mode**

- Head (current branch) must be `feature/<slug>` or `feat/<id>` (single segment after prefix)
- Blocked head: `main`, `master`, `develop`, nested `feature/a/b`, or any other pattern
- Default base: `develop` (override only if user or PLAN says otherwise)

**Release mode**

- Head must be `develop` (checkout `develop` if needed and user confirms)
- Base must be `master` or `main` (detect which exists on `origin`; ask if both)

If blocked, stop and show how to fix the branch. Do not create a PR.

### 2. Preflight - GitHub CLI

1. Resolve `gh` (cross-platform):
   - **Always first:** `gh` on `PATH` (`Get-Command gh` / `command -v gh` / `which gh`)
   - **Windows** (PATH miss only): try `C:\Program Files\GitHub CLI\gh.exe`
   - **macOS** (PATH miss only): try Homebrew locations `/opt/homebrew/bin/gh` (Apple Silicon) and `/usr/local/bin/gh` (Intel)
   - **Linux** (PATH miss only): try `/usr/bin/gh`, `/usr/local/bin/gh`, and `$HOME/.local/bin/gh` (user installs / some package layouts)
   - Do **not** invent other OS-specific paths; if still missing, go to the STOP help below (official install docs cover apt/dnf/brew/etc.)
2. Run `gh auth status` (or equivalent with the resolved absolute path)
3. If `gh` is unavailable or not authenticated:
   - Note (optional): an MCP GitHub server may work as a **fallback** for create/list when configured in the host — prefer `gh` for this skill
   - If neither `gh` (authenticated) nor a working MCP GitHub fallback is available: **STOP** and help the user (pt-BR):

```text
GitHub CLI (gh) não encontrado ou sem login.

Instalar (todas as plataformas): https://cli.github.com/
  - Windows: MSI / winget / scoop (ou PATH + "GitHub CLI")
  - macOS: brew install gh
  - Linux: pacote da distro / instruções em cli.github.com (apt, dnf, etc.)

Login: gh auth login

Depois rode /open-github-pr de novo.
```

### 3. Ensure branch is pushed

```bash
git status -sb
git rev-parse --abbrev-ref HEAD
git rev-parse --abbrev-ref @{u} 2>/dev/null || true
```

If the head branch has no upstream, or local commits are not on `origin`:

- **STOP** and hand off to `/push` (do not invent a force-push)
- After a successful push, the user may re-invoke `/open-github-pr`

Never `git push --force` to `main`, `master`, or `develop`.

### 4. Resolve PR body template

Search the **target repository** (cwd), then fall back to this skill’s templates.

**Feature mode** (first match wins):

1. `.github/PULL_REQUEST_TEMPLATE.md`
2. `.github/pull_request_template.md`
3. Any `.md` under `.github/PULL_REQUEST_TEMPLATE/` — prefer `feature.md` if it exists; otherwise the first sensible template file
4. Else: `{{TOOLKIT_ROOT}}/skills/open-github-pr/templates/feature-pr.md`

**Release mode** (first match wins):

1. `.github/PULL_REQUEST_TEMPLATE/release.md`
2. Else: `{{TOOLKIT_ROOT}}/skills/open-github-pr/templates/release-pr.md`

Do not invent org-only template APIs. Fill placeholders from git/`gh` data.

### 5. Draft title and body

**Feature**

- Title: Conventional Commits–style summary of the branch intent (English), not tracker `id - title` only
- Body: filled template (Summary, Base branch, Test plan, Notes)
- Base: `develop` unless overridden
- Head: current feature branch

**Release**

- Title: e.g. `release: promote develop to <base>` (or repo convention)
- Body: filled `release-pr.md` (or repo `release.md`)
- **Included PRs table:** list PRs merged into `develop` since the last merge of `develop` into `master`/`main`:

```bash
gh pr list --base develop --state merged --limit 100
```

Filter/annotate to those merged after the last release merge (compare merge timestamps or merge-base with `origin/<base>`). Format as a markdown table (`Number | Title | Merged at` or equivalent).

- **Commits:**

```bash
git fetch origin
git log --oneline origin/<base>..origin/develop
```

Insert the log under the Commits section.

### 6. Confirm with user (mandatory)

Detect whether the repo allows auto-merge:

```bash
gh api repos/{owner}/{repo} --jq .allow_auto_merge
```

Present title, base, head, full body, and auto-merge availability. Ask (pt-BR):

```text
Conteúdo do PR acima está ok?
- sim — criar o PR
- ajustar — diga o que mudar
- cancelar — não criar

Habilitar auto-merge após criar? (sim / não)
(Disponível no repositório: <sim|não>)
```

Only proceed on **sim**. Apply adjustments and re-confirm if requested. Auto-merge question: ask even when unavailable; if user says **sim** but `allow_auto_merge` is false, create the PR and report that auto-merge cannot be enabled.

### 7. Create PR (and optional auto-merge)

Write the approved body to a temp file, then:

```bash
gh pr create --base <base> --head <head> --title "<approved title>" --body-file <path-to-approved-body.md>
```

If the user approved auto-merge **and** `allow_auto_merge` is true:

```bash
gh pr merge <number-or-url> --auto --merge
```

(Use `--squash` / `--rebase` only if the user or repo convention explicitly requires it.)

Report the PR URL.

### 8. Report

- Mode (`feature` / `release`)
- Base and head
- PR URL and number
- Auto-merge status (enabled / skipped / unavailable)
- Template source path used

## Must not

- Create a PR without Step -1 gate approval and content confirmation (`sim`)
- Open a feature PR from `main` / `master` / `develop` or an invalid branch name
- Open a release PR unless head is `develop` and base is `master` or `main`
- Force-push protected branches
- Skip push handoff when the branch is not on `origin`
- Use Caveman Mode or compress PR title/body
- External work-item tracker APIs or mandatory org-only PR analyzers
- Implement or invoke a future `/open-pr` orchestrator (out of scope)

## Handoff

| Situation | Next |
|-----------|------|
| Branch not pushed | `/push` then re-invoke `/open-github-pr` |
| Review after PR (optional) | `/code-review` |
| Continue SDD step | New session → `/sdd-develop - <full-plan-path> - Step N` |
| Future unified orchestrator | `/open-pr` — **out of scope** for this skill |
