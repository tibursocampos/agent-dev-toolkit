# PRD authoring (spec skill)

Authoritative document template: `skills/_shared/templates/sdd/PRD.md` (toolkit: `core/skills/_shared/templates/sdd/PRD.md`).

**Default:** section titles and body in **Brazilian Portuguese (pt-BR)**. English only if the user overrides in the skill invocation - see `sdd-artifact-language-pt-br.mdc`.

**Identifiers** (types, methods, APIs, paths, test names) stay in **English**. No implementation code in the PRD.

Storage: `STORAGE.md`. Pipeline (confirm-before-write, canonical paths, modes): `PIPELINE.md`.  
Selective retrieval: `SELECTIVE-RETRIEVAL.md` (`SR-NO-FULL-DUMP`).  
Brownfield CHANGE / current specs: `CHANGE-CONTRACT.md` (template `templates/features/CHANGE.md`).

## Filename and numbering

| Part | Rule |
|------|------|
| Folder | From manifest: `features/NNN-slug/USnn/PRD/` (Classic SDD default `US01`) or global under `<classic.path>/features/...` |
| Sequence | Next `NNN` (3 digits) after listing PRDs under `features/**/PRD/` only (workspace + global feature root for `<repo-id>`) |
| Slug | Short ASCII summary (kebab-case or snake_case; Portuguese words allowed) |
| Example (repo) | `features/002-exportacao-perfil/US01/PRD/002_exportacao_perfil_usuario.md` |
| Example (global) | `sdd/acme-payments-api/features/002-exportacao-perfil/US01/PRD/002_exportacao_perfil_usuario.md` (portable path relative to InstallRoot) |

## Storage and `.gitignore` (spec skill)

Before `Write` in **repository** mode, follow `STORAGE.md` § Repository mode - `.gitignore`: ensure SDD block includes **`/features/`**. Keep `/PRD/`, `/PLAN/`, `/docs/PRD/`, `/docs/PLAN/` in `.gitignore` **only as a safety net** (not active Classic SDD paths). **Do not** add `/memory-bank/` — commit bank when product knowledge; never commit secrets. Run this on first SDD write in a repo.

**Global** mode: no `.gitignore` changes (do not add features / memory-bank / PRD / PLAN patterns).

After choosing storage, write `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/sdd/<repo-id>/manifest.json` with `artifact_language`: `pt-BR` (default) or `en` (override).

## Product documentation language

If the PRD scope includes creating or updating **project** docs under `docs/` or README, **ask** the user pt-BR vs English before writing that documentation (separate from PRD artifact language).

---

## Template usage

1. `Read` `skills/_shared/templates/sdd/PRD.md`.
2. Copy into the canonical PRD path; remove instructional brackets.
3. Fill **REQ-IDs** (`REQ-NNN`), **verifiable** CA (BDD), **OOS**, and **blast radius** when impact spans multiple areas.
4. **EARS** is hybrid/optional — use only when event/condition clarity helps; never require EARS for every REQ.

## Challenge vagueness (before Write)

Reject or rewrite acceptance / REQ text that cannot be verified. Examples of **forbidden** phrasing: "works correctly", "as expected", "properly", "funciona corretamente", "como esperado", "de forma adequada".

Every CA must state an **observable** outcome (test, script exit code, checklist item, or measurable UI/API result). Every functional REQ maps to ≥1 CA.

## Selective retrieval

- Prior context: summary + max **3** gap questions; prefer sibling/bank **paths** over bodies (`PIPELINE.md`, `SELECTIVE-RETRIEVAL.md`).
- **Must not** dump entire `memory-bank/` or paste the full PRD into chat handoffs / CONTINUITY / child prompts — cite portable paths.
- Enforcement smoke: `scripts/validation/Assert-SelectiveRetrieval.ps1`.

## English override

When the user requests English in the skill invocation: same structure as the shared template; section titles in English (`## 1. Overview`, **Given**/**When**/**Then**, status **Ready for planning**). Set manifest `artifact_language` to `en`. Keep REQ-IDs, OOS, blast radius, and optional EARS rules.

---

## Structural validate (`validate-prd`)

Before `/sdd-plan` handoff, run:

```
.\scripts\validation\validate-prd.ps1 -Path <prd-path>
```

Exit 0 required (REQ-NNN + CA headings present). Exit ≠ 0 → fix and re-run. Fixtures/smoke: `scripts/validation/Assert-ValidatePrdPlan.ps1`. Deterministic scripts only (RNF-001) — never use an LLM as the structural validator.

## Brownfield CHANGE (`validate-change`)

When FEATURE **Nature** is **brownfield**, also Write `features/NNN-slug/CHANGE.md` (ADDED \| MODIFIED \| REMOVED vs **current** `memory-bank/` docs) and run:

```
.\scripts\validation\validate-change.ps1 -Path <features/NNN-slug/CHANGE.md>
```

**Greenfield** must **not** force an empty CHANGE stub. Contract: `CHANGE-CONTRACT.md`. Smoke: `Assert-ChangeContract.ps1`.

## Quality checklist (before handoff)

- [ ] User confirmed **sim** on canonical path (`PIPELINE.md` § Confirm before write)
- [ ] Path matches `features/**/PRD/NNN_*.md` or global `.../features/**/PRD/NNN_*.md` only
- [ ] Body follows `templates/sdd/PRD.md` (REQ-IDs, verifiable CA, OOS; EARS only if useful)
- [ ] Vague AC/REQ challenged and rewritten
- [ ] `validate-prd` exit 0 on the written path
- [ ] Brownfield: `CHANGE.md` present + `validate-change` exit 0; greenfield: no empty CHANGE forced
- [ ] No implementation code in the PRD; no production/test code edited in `spec` session
- [ ] No full memory-bank / PRD dump prescribed in this skill session
- [ ] Body in pt-BR unless English override
- [ ] Type/method/API names in English where cited
- [ ] Status **Pronto para planejamento** (or **Ready for planning** if EN override)
- [ ] Handoff: `/sdd-plan - <portable-prd-path>`
