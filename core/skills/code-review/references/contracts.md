# Review contracts refs (WS16a / REQ-016)

**Family:** `contracts`. Load during Process §2–4 when the diff touches SDD artifacts, skill contracts, CHANGE/FEATURE shape, evidence/TRACE, API schemas, or plan markers.

**Language:** English identifiers and checklist labels. Report prose follows session language.

**Contract:** cite portable paths; **do not** dump full contract files into the report (`SR-NO-FULL-DUMP` / RNF-004). Honor `CONTRACT-PROVENANCE.md` (`agreed` vs `invented`) — do not treat reviewer inventions as PRD requirements.

Companions: `references/sdd-resolution.md`, `references/policy.md`, `references/verification.md`.

---

## Pointer index (cite path; open on demand)

| Contract / topic | Portable path | When to load |
|------------------|---------------|--------------|
| CHANGE / FEATURE / TASKS shape | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/CHANGE-CONTRACT.md` | Diffs under `features/**/CHANGE.md` / FEATURE |
| Agreed vs invented | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/CONTRACT-PROVENANCE.md` | PRD/PLAN/REQ drift judgments |
| SESSION / develop gates | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/SESSION.md` | Gate / session-file skill changes |
| Storage / portable paths | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/STORAGE.md` | Path / storage_mode / navigation diffs |
| EVD / STATE | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/EVD-STATE-CONTRACT.md` | Evidence artifacts in scope |
| TRACE / archive | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/TRACE-ARCHIVE-CONTRACT.md` | Living-loop / archive diffs |
| Plan ledger | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/PLAN-LEDGER-CONTRACT.md` | Ledger / claim payload diffs |
| Selective retrieval | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/SELECTIVE-RETRIEVAL.md` | Skills that load bank/PRD context |
| Plan-contract markers + delivery-baseline | `{{TOOLKIT_ROOT}}/skills/sdd-develop/references/plan-contract.md` | PLAN progress / Complete criteria |
| Invocation contexts | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/INVOCATION-CONTEXTS.md` | direct vs orchestrated skill diffs |
| API naming (agnostic) | `{{TOOLKIT_ROOT}}/skills/api-standards/references/naming-contracts.md` | Public HTTP/schema naming in consumer apps |
| Skill fixture contracts | `scripts/validation/contracts/skill-contracts.json` (toolkit repo) | Toolkit skill SKILL.md contract regressions |

Sibling feature contracts (do **not** reopen CI asserts from enrich-only reviews): `features/006-toolkit-evolution-contracts/` — consume; flag reverts of InvocationAxes / Navigation / Shell as **important** when in the diff.

---

## Actionable checklist (contracts family)

- [ ] SDD path shape under `features/NNN-slug/...` still canonical; no OS absolute paths newly introduced in artifacts (`STORAGE.md` § Portable path)
- [ ] PLAN/PRD Related / Navigation still portable; no second SoT (OpenSpec / `.specs/` / SQLite TRACE) introduced
- [ ] CHANGE/FEATURE edits respect `CHANGE-CONTRACT` (ADDED\|MODIFIED\|REMOVED; TASKS policy) when those files are in the diff
- [ ] Complete / delivery claims still match `plan-contract` markers + delivery-baseline (no duration/effort estimates as gates — RN04)
- [ ] SESSION / ledger / path-secret guards not weakened (RNF-003)
- [ ] API/schema diffs: naming/versioning consistent with project or `api-standards` pointers — no proprietary contract dump
- [ ] Reviewer findings that are **not** in PRD/PLAN are labeled invented/suggestion — not claimed as failed REQ

**Severity hint:** portable-path / gate / SoT regressions → **critical** or **important**; missing Related cite → often **important**; style-only contract prose → **nice-to-have**.

## OOS (WS16b) — explicit

This family does **not** authorize creating `core/skills/framework-upgrade/` or any new product skill folder. Flag such additions as **out of scope** / **Changes required** unless a separate approved feature exists.

## CT6 marker (contracts)

- [ ] This file is reachable from `code-review` Reference routing / Process §2–4
- [ ] Three-family surface complete with `policy.md` + `n-plus-one.md`
- [ ] No `framework-upgrade` skill folder created by this wiring
