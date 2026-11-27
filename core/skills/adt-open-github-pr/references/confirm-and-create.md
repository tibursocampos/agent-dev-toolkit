## Confirm with user (mandatory)

Detect whether the repo allows auto-merge:

```bash
gh api repos/{owner}/{repo} --jq .allow_auto_merge
```

Present title, base, head, full body, template source path, and auto-merge availability. Ids and render rule: `core/skills/_shared/agents/QUESTIONS.md`. Ask two questions in the user's chat language:

1. Content gate: `confirm` (create the PR), `adjust` (the user says what to change), `cancel` (do not create it).
2. Auto-merge gate: `confirm` (enable auto-merge after create) or `decline` (do not enable). State whether the repository allows auto-merge, from the `allow_auto_merge` check above.

Only a `confirm` on the content gate creates the PR. Apply `adjust` changes and re-confirm. Silence, an ambiguous or unrelated reply, or a lone emoji is not approval; a clear affirmative reply in any language is.

**Auto-merge question is mandatory every time** — including when the user already said “fluxo completo”, “abra o PR”, or similar. Do not infer auto-merge from those phrases. Ask even when unavailable; if the answer is `confirm` but `allow_auto_merge` is false, create the PR and report that auto-merge cannot be enabled.

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
