## Confirm with user (mandatory)

Detect whether the repo allows auto-merge:

```bash
gh api repos/{owner}/{repo} --jq .allow_auto_merge
```

Present title, base, head, full body, template source path, and auto-merge availability. Ask in the user chat language:

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

### Merge method (the repository decides)

This skill does not pick a merge method. Use the one the repository requires:

1. Its rulesets, if any: `gh api repos/{owner}/{repo}/rulesets`.
2. Its docs or PR template, if they state one.
3. If none of them states a method, ask the operator which one to use. Do not guess.

Auto-merge with the chosen method:

```bash
gh pr merge <number-or-url> --auto --<method> --subject "<approved PR title>"
```

If the repository disables the chosen method, **STOP**, report which method is blocked, and ask the operator. Do not silently fall back to another method.

Report the PR URL.

## Report

- Base and head
- PR URL and number
- Merge method used and auto-merge status (enabled / skipped / unavailable)
- Template source path used
