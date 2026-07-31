# CONTINUITY: {{NNN}}-{{slug}}

| Campo | Valor |
|-------|--------|
| **Feature** | `features/{{NNN}}-{{slug}}/` |
| **Updated** | {{ISO8601}} |
| **Phase** | analyze \| deliver \| develop \| review |
| **Last agent** | {{AGENT_OR_SKILL}} |
| **Complexity** | trivial \| medium \| complex |
| **Nature** | greenfield \| brownfield \| operational |
| **Memory-bank** | `{{BANK_PATH}}` (resolved via `STORAGE.md`: `$Cwd/memory-bank/` or `<classic.path>/memory-bank/` - never under this feature) |
| **Memory-bank status** | fresh \| refreshed \| created |

## Estado atual

{{CURRENT_STATE}}

## Decisões

- {{DECISION}}

## Flags (`needs_*`)

| Flag | Valor |
|------|-------|
| needs_api | {{BOOL}} |
| needs_domain | {{BOOL}} |
| needs_database | {{BOOL}} |
| needs_frontend | {{BOOL}} |
| needs_security | {{BOOL}} |
| needs_devops | {{BOOL}} |

## Pendências

- [ ] {{OPEN_ITEM}}

## Handoff tipado

```text
{{NEXT_SKILL_INVOKE}}
```

## Contexto enxuto (pai)

Máx. síntese + paths. Detalhes ficam em `STORY.md` / `PRD` / `PLAN` / notas sob a história.

---

## Regras de atualização (agentes)

1. **Who updates:** every O1/O2/O3 stage and any specialist Task that finishes a meaningful note set.
2. **When:** before human approval gates; at ≥40% context pause; before session handoff.
3. **What to write:** phase, last agent, estado atual (≤10 lines), new decisões, open pendências, exact next `/…` string with **full paths**.
4. **What not to write:** full PRD/PLAN bodies, guideline dumps, application code, or the body of `memory-bank/` (path + status only); never secrets, API keys, feed tokens, connection strings, or PII - use `***` / env var names only.
5. **Merge:** append decisões; replace estado atual; never delete unresolved pendências without marking done. Prefer specialist **receipts** (`_shared/agents/RECEIPT.md`) over dumping full specialist chat.
6. **Memory-bank:** update path/status after Step 0 (`fresh` = healthy read; `created` / `refreshed` = init wrote). Also after O3 Step N `refresh-light`. Bank co-locates with `features/` via manifest; never under `features/NNN-slug/`. Commit bank when product knowledge; never commit secrets.
7. **Language:** artifact prose default **pt-BR**; skill names and paths in English.
8. **Compact (optional):** if this file grows large and caveman is ON, offer `_shared/caveman/COMPACT.md` (backup `.original.md` + validators + user **sim**). Never auto-compact.
