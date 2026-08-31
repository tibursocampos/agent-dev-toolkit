## Guards and mode

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
