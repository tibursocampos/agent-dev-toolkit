## Guards and base

### Caveman Mode
**NEVER** - This skill ignores `caveman_mode`. Use clear prose always. Do not load `CAVEMAN.md` for chat compression. PR title/body stay normal English.

### -1. Re-check guardrails and session

If missing, ask user in the user chat language:

```text
Antes de abrir o PR, confirme:
- guardrails.mdc lido
- SESSION.md carregado

Posso seguir? (sim / ajustar / cancelar)
```

### 0. Resolve base and head

- **Head:** the current branch. It must not be `main`, `master` or `develop`, because development skills do not run on integration branches. Full check in `references/validate-branch.md`.
- **Base:** the repository's default branch, unless the user names another. Detect it with `gh repo view --json defaultBranchRef --jq .defaultBranchRef.name`. If the repository's PR template or docs name a different base, follow them.
- The skill does not assume a release or feature flow. The repository defines it.

If the base is unclear, ask once in the user chat language:

```text
Base do PR? (<default-branch> / outra)
```
