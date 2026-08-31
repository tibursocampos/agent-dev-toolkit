# FEATURE: {{TITLE}}

| Campo | Valor |
|-------|--------|
| **Id** | `{{NNN}}-{{slug}}` |
| **Path** | `features/{{NNN}}-{{slug}}/` (repository) or `sdd/<repo-id>/features/{{NNN}}-{{slug}}/` (global; portable path — see `STORAGE.md` § Portable path) |
| **Scope** | backend \| frontend \| fullstack |
| **Nature** | greenfield \| brownfield \| operational |
| **Complexity** | trivial \| medium \| complex |
| **Status** | draft \| approved \| in-progress \| done |

## Resumo

{{SUMMARY}}

## Histórias

| Id | Tipo | Título | Rationale | Product intent | Status |
|----|------|--------|-----------|----------------|--------|
| US01 | US | {{STORY_TITLE}} | {{WHY_THIS_STORY}} | {{WHO_JOB_OUTCOME_OR_N_A}} | draft |

`Product intent` = optional Who / Job / Outcome (or `n/a` for pure TS/Bug). See `skills/_shared/backlog-item-types/persona-context.md`. `Rationale` = why this story is separate (sizing).

## Flags (`needs_*`)

| Flag | Valor |
|------|-------|
| needs_api | false |
| needs_domain | false |
| needs_database | false |
| needs_frontend | false |
| needs_security | false |
| needs_devops | false |

## Links

- CONTINUITY: `./CONTINUITY.md`
- CHANGE (brownfield vs current): `./CHANGE.md` — required when **Nature** = `brownfield`; greenfield must not force an empty stub (`CHANGE-CONTRACT.md`)
- Stories: `./US01/STORY.md` (ajustar ids)
