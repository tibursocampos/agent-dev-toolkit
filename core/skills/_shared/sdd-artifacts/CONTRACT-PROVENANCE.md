# Contract provenance (agreed vs invented)

Install path after sync: `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/CONTRACT-PROVENANCE.md`

**Language:** This guideline is **English**. Operator chat stays **pt-BR** per toolkit policy (`LANGUAGE.md`). Artifact body language follows `preferences.json` / manifest `artifact_language`.

Companion: `PIPELINE.md`, `INVOCATION-CONTEXTS.md`, `SELECTIVE-RETRIEVAL.md` (`SR-NO-FULL-DUMP`), `CHANGE-CONTRACT.md`, `STORAGE.md` § Portable path.

**Rule ID:** `CP-AGREED-VS-INVENTED`

---

## Purpose (REQ-002 / CA1)

Skills that **author** or **consume** requirements must distinguish:

| Provenance id | Meaning |
|---------------|---------|
| `agreed` | Explicitly confirmed by the operator, cited Prior context (FEATURE / STORY / REFINE / promoted bank / sibling ANALYSIS\|ARCH\|SEC), or an existing approved artifact the operator already accepted. |
| `invented` | Agent-proposed fill-in: gap hypothesis, default, inferred constraint, or unconfirmed assumption **not** yet accepted by the operator. |

Do **not** present `invented` content as `agreed`. Do **not** invent a third id that collapses the distinction (TE02).

## In-scope consumers

| Skill | Role |
|-------|------|
| `sdd-spec` | **Author** — primary wire; marks REQ/CA/OOS/assumptions on write |
| `sdd-plan` | **Consumer** — treat PRD REQs as `agreed` unless PRD labels otherwise; do not re-label invented as agreed |
| `sdd-develop` | **Consumer** — implement only `agreed` step Aceite / cited REQ; invented gaps need operator confirm before coding as requirement |

Other pipeline skills may **cite** this file when they synthesize requirements; they must not invent REQ text and call it operator-agreed.

## Detection (deterministic)

Resolve provenance **per claim** (REQ, CA bullet, assumption, OOS item), not once per session:

1. **Operator said / confirmed** in this session (answers to questionnaire, **sim** on draft bullets that include the claim) → `agreed`.
2. **Cited Prior context** with a portable path + short quote/summary pointing to an existing accepted artifact → `agreed` (cite the path; do not dump full PRD/`memory-bank/`).
3. **Agent fill-in** to close a gap, propose a default, or infer from code without operator confirm → `invented` until confirmed.
4. **Ambiguous** → treat as `invented` (TE02); ask or label explicitly before Write.

## Observable behavior

### Shared

| Rule | Behavior |
|------|----------|
| Labeling | PRD / handoff that includes agent fill-in must make provenance **visible** (section, table column, or inline tag such as `provenance: invented`) |
| No laundering | Never move `invented` → `agreed` without operator **sim** or an explicit Prior-context cite |
| Secrets (RNF-002) | Examples use env var **names** or `***` only — never real tokens |
| Selective retrieval | Cite portable paths + short summaries; **must not** dump entire `memory-bank/` or paste full PRD (`SR-NO-FULL-DUMP`) |
| Portable paths | Cross-refs in written artifacts use portable paths only |

### `sdd-spec` (author)

| Observable | Required behavior |
|------------|-------------------|
| Questionnaire / Prior context answers | Map into REQ/CA as `agreed` |
| Agent proposals (defaults, inferred NFRs, guessed IDs) | Keep under Assumptions / Open questions / explicit `invented` until operator confirms |
| Confirm-before-write draft | Show which bullets are still `invented`; wait for **sim** / **ajustar** — after **sim**, those listed bullets become `agreed` for the Write |
| OOS | Out-of-scope items the operator accepted are `agreed` OOS; agent-suggested OOS without confirm stays `invented` |
| Handoff | Do not tell `sdd-plan` that invented gaps are locked requirements |

### `sdd-plan` / `sdd-develop` (consume)

| Observable | Required behavior |
|------------|-------------------|
| PRD REQs without invented label | Treat as `agreed` input for planning / implementation |
| PRD / notes marked `invented` or “open assumption” | Do **not** put into Aceite as done criteria until operator promotes them |
| New gaps found mid-plan/develop | Label `invented`; ask operator — do not silently encode as REQ |

## Examples (no secrets)

### Env / redaction (RNF-002)

```text
# OK — env var name only
Connection uses $env:APP_DB_CONNECTION (agreed: operator supplied name)
Token header: Authorization: Bearer ***

# Forbidden — real token material
Authorization: Bearer eyJhbGciOi***real***
```

### Authoring shape (sdd-spec)

```text
## Assumptions (invented until confirmed)
- [invented] Max export size = 50 MB (agent default; not confirmed)

## Requirements
| ID | Text | provenance |
|----|------|------------|
| REQ-001 | Operator can export profile CSV | agreed |
```

After operator **sim** on the assumption, move it into Requirements (or drop it) and remove the invented label.

### Consumer shape (sdd-plan)

```text
PRD marks REQ-001 agreed → PLAN Aceite may cite REQ-001.
PRD lists "Assumptions (invented)" → do not map into Aceite as Completed criteria.
```

## Wiring requirement

1. **`sdd-spec` (required):** Cite this file in Lazy-load; apply `CP-AGREED-VS-INVENTED` during requirements authoring and before Write; restate in Must-not.
2. **`sdd-plan` / `sdd-develop` (minimal):** Cite this file in Lazy-load and Must-not so consumers do not re-label invented as agreed.
3. Pointers only — do **not** paste this body into `SKILL.md` or child Task prompts.

## Enforcement

| Check | How |
|-------|-----|
| Documented | This file + skill Lazy-load / Must-not pointers |
| Smoke | Contract file exists; contains `CP-AGREED-VS-INVENTED`, `agreed`, `invented`; `sdd-spec` SKILL.md cites `CONTRACT-PROVENANCE` and `CP-AGREED-VS-INVENTED`; `sdd-plan` / `sdd-develop` cite `CONTRACT-PROVENANCE` |

Automated Assert may be added later; missing `sdd-spec` wire → do not mark REQ-002 / CA1 done.

## Must not

- Present agent guesses as operator-agreed requirements
- Collapse `agreed` and `invented` into one unlabeled blob in PRD Write
- Put real API tokens, passwords, or private keys in examples
- Dump this contract body into child Task prompts (cite portable path + rule id only)
- Use provenance labels to skip confirm-before-write gates
