# PLAN authoring (plan skill)

Authoritative document template: `skills/_shared/templates/sdd/PLAN.md` (toolkit: `core/skills/_shared/templates/sdd/PLAN.md`).

**Default:** section titles and body in **Brazilian Portuguese (pt-BR)**. English only on explicit skill invocation override - see `sdd-artifact-language-pt-br.mdc`.

**File paths** and **test names** in English. No implementation code blocks in the PLAN.

Storage rules: `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/skills/_shared/sdd-artifacts/STORAGE.md`. Pipeline guards: `PIPELINE.md`.  
Selective retrieval: `SELECTIVE-RETRIEVAL.md` (`SR-NO-FULL-DUMP`).

## Filename and numbering

| Part | Rule |
|------|------|
| Folder | Same story as PRD: `features/NNN-slug/USnn/PLAN/` (or global under `<classic.path>/features/...`) |
| Sequence | Same `NNN` (3 digits) as the source PRD |
| Slug | Short ASCII summary (kebab-case or snake_case; Portuguese allowed) |
| Example (repo) | `features/002-exportacao-perfil/US01/PLAN/PLAN_002_exportacao_perfil_usuario.md` |
| Example (global) | `sdd/acme-payments-api/features/002-exportacao-perfil/US01/PLAN/PLAN_002_exportacao_perfil_usuario.md` (portable path relative to InstallRoot) |
| PRD link | **Portable path** to PRD (`STORAGE.md` § Portable path; must be under `features/.../PRD/` or `sdd/<repo-id>/features/.../PRD/`) |

## Storage and `.gitignore` (plan skill)

If PRD is global, PLAN is global unless the user chooses repository storage. Before `Write` in **repository** mode, follow `STORAGE.md` § Repository mode - `.gitignore` (include `/features/`; keep `/PRD/` `/PLAN/` as safety net only; **do not** add `/memory-bank/` — commit bank when product knowledge; never commit secrets). Update manifest (`artifact_language`, folders). Do **not** write or update PLANs at repo-root `PLAN/`. **Global** mode: do not edit `.gitignore`.

## Product documentation language

If a step updates **project** `docs/` or README, the **plan** or **implement** skill must **ask** pt-BR vs English before writing that deliverable.

---

## Template usage

1. `Read` `skills/_shared/templates/sdd/PLAN.md`.
2. Copy into the canonical PLAN path; remove instructional brackets.
3. Fill **Mapa REQ → passo** so every PRD `REQ-NNN` appears in ≥1 step.
4. Each step **Aceite** cites CA and/or REQ with verifiable outcomes (no vague language).

## Challenge vagueness

Before finalizing steps: rewrite Aceite lines that say "works", "ok", "as expected", "funciona", "como esperado". Prefer observable checks (tests named, script exit, checklist item).

## Selective retrieval

- Summarize the PRD for planning; **cite** the portable PRD path — **must not** paste the full PRD body into the PLAN or into Task/child prompts.
- **Must not** dump entire `memory-bank/` when exploring Prior context.
- Enforcement smoke: `scripts/validation/Assert-SelectiveRetrieval.ps1`.

## PLAN magro

Do not paste SQL/DDL/JSON/OpenAPI into the PLAN. Cite canonical paths (bank phase 2 or story `ARCH/` / `ANALYSIS/`). If the canonical file is missing, **STOP** — O1/O2 creates it first.

---

## PLAN update protocol (implement skill)

Do **not** embed implement update rules inside the PLAN artifact. After each completed step, **`sdd-develop`** updates the same PLAN file per `skills/sdd-develop/reference.md` § PLAN update protocol (status **Concluído** / **Completed**, progress bar, **Próximo passo** / **Next step**, deliverable checkboxes). Do not edit progress manually during implementation except session recovery.

---

## Status legend

| Marker | Meaning |
|--------|---------|
| ⏳ PASSO N | Pending |
| 🔄 PASSO N | In progress (active implement session) |
| ✅ PASSO N | Completed |
| ❌ PASSO N | Blocked |

Use **Pendente** / **Concluído** / **Bloqueado** (or English equivalents) on the `**Status:**` line in pt-BR PLANs; emoji in the heading is optional.

**Implement skill:** step headings may use `STEP` or `PASSO`; match the PLAN file when updating.

---

## Baby-step sizing checklist

- [ ] No step with 4+ new files without splitting
- [ ] EF migration and mapping separated when both apply
- [ ] Handler, consumer, and tests not in the same step unless trivial
- [ ] Dense steps include a context warning for implement
- [ ] Optional docs step only when contract or visible behavior changes - **ask system doc language** (pt-BR vs English)

---

## Structural validate (`validate-plan`)

Before `/sdd-develop` handoff, run:

```
.\scripts\validation\validate-prd.ps1 -Path <prd-path>
.\scripts\validation\validate-plan.ps1 -Path <plan-path> -PrdPath <prd-path>
```

Exit 0 required: PLAN has REQ→step map and covers every PRD `REQ-NNN`. Exit ≠ 0 → fix and re-run. Fixtures/smoke: `scripts/validation/Assert-ValidatePrdPlan.ps1`. Deterministic scripts only (RNF-001) — never use an LLM as the structural validator.

## Quality checklist (before handoff)

- [ ] User confirmed **sim** on canonical PLAN path (`PIPELINE.md` § Confirm before write)
- [ ] Canonical PRD on disk; PRD path and `NNN` match the PLAN filename
- [ ] Body follows `templates/sdd/PLAN.md` (REQ→step map; Aceite cites REQ/CA)
- [ ] Every PRD REQ and acceptance criterion appears in some step
- [ ] Vague Aceite challenged and rewritten
- [ ] `validate-prd` and `validate-plan` exit 0 on the written paths
- [ ] Step prose in pt-BR (unless English override)
- [ ] No full implementation code blocks in the PLAN
- [ ] No full PRD / memory-bank dump in PLAN or handoff prompts
- [ ] PLAN magro: SQL/DDL/JSON/OpenAPI omitted **only** if a canonical path already exists (bank phase 2 or `ARCH/` / `ANALYSIS/`); otherwise create that file first and cite the path
- [ ] Output path: `features/**/PLAN/PLAN_NNN_*.md` or global `.../features/**/PLAN/` only (not root `PLAN/`, ad-hoc `docs/`, or `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/` outside `sdd/.../features/`)
- [ ] Handoff: `/sdd-develop - <portable-plan-path> - Step 1`
- [ ] Initial progress `0/N`
