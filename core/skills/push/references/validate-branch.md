## Validate branch (blocker)

### Caveman Mode
**NEVER** — This skill ignores `caveman_mode`. Use clear prose always. Do not load `CAVEMAN.md` for chat compression.

### -1. Re-check guardrails and session

If missing, ask user (pt-BR):

```text
Antes do push, confirme:
- guardrails.mdc lido
- SESSION.md carregado

Posso seguir? (sim / ajustar / cancelar)
```

### 0. Validate branch

Enforce `branch-validation.mdc`:

- Allowed: `feature/<slug>`, `feat/<id>`
- Blocked: `main`, `master`, `develop`, invalid patterns

If blocked, stop and show how to create a valid branch. Do not push.
