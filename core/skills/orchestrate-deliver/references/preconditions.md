## Preconditions checklist

Before any PRD/PLAN write:

- [ ] Gate check reported; `write_confirmed` / user **sim** for this O2 run (O2 writes PRD/PLAN - not develop `step_confirmed`)
- [ ] Feature path resolved (`STORAGE.md`, `$Workflow = classic`)
- [ ] **Step 0** Memory Bank Gate done (`MEMORY-BANK.md`, policy `auto`; `skip` only with explicit flag)
- [ ] `FEATURE.md` + `CONTINUITY.md` exist (Memory-bank path/status updated if create/refresh)
- [ ] Backlog human-approved (FEATURE/stories `approved`, or explicit **sim** in this session recorded)
- [ ] Story list from `US*/STORY.md` + `TS*/STORY.md`
- [ ] Flag-gated required siblings present (`ANALYSIS/` / `ARCH/` / `SEC/` when FEATURE `needs_*` or brownfield) — else **STOP** / return to O1; do **not** Write PRD/PLAN; max-3 gap questions do not replace this gate
- [ ] Mode chosen: **série** or **paralelo** (user asked; not assumed)

If backlog not approved -> hand off to O1; do not invent approval (RN01).
If required siblings missing -> **STOP** / return to O1; do not Write PRD/PLAN.

---

## Step 0 - Memory Bank Gate (CA4 / CT3)

Same contract as O1 (`MEMORY-BANK.md`). Run after feature resolve, **before** mode selection.

| Check | Pass |
|-------|------|
| Bank path | Resolved `bank_root` via `STORAGE.md` |
| Healthy bank | Selective read; status `fresh` unless style changed / ARCH approved this feature → then `refreshed` (point-promote `architecture.md` if not already); no full inventory rewrite |
| Missing/stale | Confirm -> create/refresh; status `created`/`refreshed` |
| Gitignore | Repository only; global = no `.gitignore` edit |
| CONTINUITY | Path + status only; phase/handoff still CONTINUITY-owned |
| Children | Parallel draft Tasks get `memoryBankPath` read-only |
| Classic SDD | Memory-bank **not** required (CA7) |
| End refresh | **No** full inventory (O2 does not change app code). Do **not** exit `fresh` if style changed / ARCH approved this feature |

---

## Process — Preconditions (approved backlog + siblings)

Verify backlog is human-approved:

| Signal | Accept |
|--------|--------|
| `FEATURE.md` **Status** | `approved` (or stories listed as approved) |
| CONTINUITY | O1 handoff / note that backlog was approved with **sim** |

If still `draft` or approval unclear: **STOP** - do not invent approval:

```text
Backlog ainda não aprovado em `{feature-path}`.

1) Voltar ao O1: /orchestrate-analyze - <portable-feature-path>
2) Você confirma aprovação agora? (sim / cancelar)
```

Only continue after explicit **sim** (then record in CONTINUITY) or O1 re-approval.

Discover stories: Glob `US*/STORY.md` and `TS*/STORY.md` under the feature. Build work list (id, title, path, deps from STORY if present). Skip stories already having both PRD+PLAN unless user asks to refresh.

**Required siblings STOP (flag-gated):** If FEATURE `needs_*` is true (or nature is brownfield) and the story lacks the matching sibling folder/files (`ANALYSIS/` / `ARCH/` / `SEC/` per `ROSTER.md` / `PIPELINE.md` § Feature / story siblings): **STOP**. Return to O1. Do **not** Write PRD/PLAN. Max-3 gap questions do **not** replace this gate. Waive-deps remains for **story order**, not for missing SEC/ARCH/ANALYSIS.

```text
Faltam pastas obrigatórias em `{story-path}` (FEATURE needs_* / brownfield).

O2 não grava PRD/PLAN sem ANALYSIS|ARCH|SEC quando a flag correspondente é true. Max-3 perguntas de gap não substituem este gate.

1) Voltar ao O1: /orchestrate-analyze - <portable-feature-path>
2) cancelar
```

See also § Preconditions checklist.
