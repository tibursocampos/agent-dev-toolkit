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

If the user approved auto-merge **and** `allow_auto_merge` is true:

```bash
gh pr merge <number-or-url> --auto --merge
```

(Use `--squash` / `--rebase` only if the user or repo convention explicitly requires it.)

Report the PR URL.

## Report

- Mode (`feature` / `release`)
- Base and head
- PR URL and number
- Auto-merge status (enabled / skipped / unavailable)
- Template source path used
