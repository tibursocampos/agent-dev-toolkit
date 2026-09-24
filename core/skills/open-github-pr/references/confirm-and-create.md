## Confirm with user (mandatory)

Detect whether the repo allows auto-merge:

```bash
gh api repos/{owner}/{repo} --jq .allow_auto_merge
```

Present title, base, head, full body, template source path, and auto-merge availability. Ask (pt-BR):

```text
Conteúdo do PR acima está ok?
- sim — criar o PR
- ajustar — diga o que mudar
- cancelar — não criar

Habilitar auto-merge após criar? (sim / não)
(Disponível no repositório: <sim|não>)
```

Only proceed on **sim** for content. Apply adjustments and re-confirm if requested.

**Auto-merge question is mandatory every time** — including when the user already said “fluxo completo”, “abra o PR”, or similar. Do not infer auto-merge from those phrases. Ask even when unavailable; if user says **sim** but `allow_auto_merge` is false, create the PR and report that auto-merge cannot be enabled.

## Create PR (and optional auto-merge)

Write the approved body to a temp file, then:

```bash
gh pr create --base <base> --head <head> --title "<approved title>" --body-file <path-to-approved-body.md>
```

If the user approved auto-merge **and** `allow_auto_merge` is true, enable auto-merge with the **mode-required** merge method below (do **not** default to `--merge`).

### Merge method by mode (mandatory)

| Mode | Base ← Head | `gh pr merge` method | Why |
|------|-------------|----------------------|-----|
| `feature` | `develop` ← `feature/*` \| `feat/*` | **`--squash`** | One general commit on `develop`; use PR title as squash subject (and PR body as squash body when useful) |
| `release` | `main`/`master` ← `develop` | **`--rebase`** (FF-compatible / linear) | Feature squashes on `develop` are already organized; replay them linearly onto release without a second squash or noisy merge commit |

**Feature (squash) — preferred flags:**

```bash
gh pr merge <number-or-url> --auto --squash --subject "<approved PR title>"
```

Optional: add `--body-file <approved-body.md>` (or `--body`) so the squash commit message carries the PR summary. Never use `--merge` or `--rebase` for feature → `develop`.

**Release (linear / fast-forward compatible) — preferred flags:**

```bash
gh pr merge <number-or-url> --auto --rebase
```

Never use `--squash` for release (`develop` → `main`/`master`) — that would collapse already-organized develop history. Prefer `--rebase` over `--merge` so history stays linear (GitHub “rebase and merge”; equivalent intent to fast-forward when `develop` is strictly ahead).

If the repo disables the required method (API/settings), **STOP**, report which method is blocked, and ask the operator — do not silently fall back to another method.

Report the PR URL.

## Report

- Mode (`feature` / `release`)
- Base and head
- PR URL and number
- Merge method used (`squash` / `rebase`) and auto-merge status (enabled / skipped / unavailable)
- Template source path used
