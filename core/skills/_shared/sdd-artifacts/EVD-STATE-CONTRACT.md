# EVD + STATE contract (evidence-or-zero)

Install path after sync: `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/EVD-STATE-CONTRACT.md`

**Language:** This guideline is **English**. Agent artifact prose for `STATE.md` / `EVD/*` may be **pt-BR** (default) or English if overridden. Identifiers and paths stay **English**.

Companion: `STORAGE.md` (canonical paths), `CHANGE-CONTRACT.md`, `SELECTIVE-RETRIEVAL.md` (`SR-NO-FULL-DUMP`), `PIPELINE.md`.

---

## Purpose (REQ-005 / CA4)

After implementation, verification records evidence under the feature root:

```text
features/NNN-slug/EVD/          # evidence files (smoke notes, command outputs, links)
features/NNN-slug/STATE.md      # AC → evidence matrix + evidence level
```

Policy name: **evidence-or-zero**.

## Evidence levels

| Level | Meaning |
|-------|---------|
| `off` | No evidence gate — `validate-evidence` exits 0 without requiring EVD/STATE |
| `cheap` | Require `STATE.md` + `EVD/` and **at least one** non-empty evidence file cited by the matrix |
| `standard` | `cheap` + every matrix row has a non-empty evidence path under `EVD/` |
| `strict` | `standard` + every matrix **Result** is `pass` (no `pending` / empty / `fail`) |

Default for post-implementation verify in `sdd-develop`: **`cheap`** (override via `-Level` or STATE field **Evidence level**).

**Gate (TE02):** level ≥ `cheap` with zero evidence → gate **fails** (exit ≠ 0). Do not mark the PLAN step done.

## STATE.md

Template: `skills/_shared/templates/features/STATE.md`.

Required when level ≥ `cheap`:

1. Field **Evidence level** = `off` \| `cheap` \| `standard` \| `strict`
2. Section **AC → evidence matrix** (or `AC -> evidence matrix`) with a markdown table
3. Columns at least: **AC**, **Evidence** (path under `EVD/`), **Result**

## EVD/

Template stub: `skills/_shared/templates/features/EVD/README.md`.

- Store short, named evidence files (e.g. `EVD/ca1-validate-smoke.md`)
- Cite portable paths only (`features/NNN-slug/EVD/...`)
- Do **not** dump full PRD / full `memory-bank/` (`SR-NO-FULL-DUMP`)

## Verifier ≠ O3 parallelism

Evidence verification is a **sequential** gate inside the same `sdd-develop` session (or a deterministic script).

| Allowed | Forbidden |
|---------|-----------|
| Run `validate-evidence.ps1` in the develop child after tests | Spawn Task / O3 parallel children **as the verifier mechanism** |
| Parent asks child to include evidence before marking done | Treat `orchestrate-develop` parallelism as “proof” that ACs passed |
| Serial re-run of validate after fixing EVD/STATE | Parallel “verify” wave that replaces STATE/EVD |

O3 may still parallelize **implementation** of **disjoint PLAN steps** when the PLAN and operator allow — that is unrelated to the evidence verifier.

## Structural validate

```text
.\scripts\validation\validate-evidence.ps1 -FeatureRoot <features/NNN-slug> [-Level cheap]
```

If `-Level` is omitted, the script reads **Evidence level** from `STATE.md` (default `cheap` when STATE is missing and a level is required).

Exit 0 = policy satisfied. Exit ≠ 0 = fix before marking the step done. Smoke: `Assert-EvidenceContract.ps1`. Deterministic only (RNF-001) — never LLM-as-validator.

## When to write

| Moment | Action |
|--------|--------|
| During / after `sdd-develop` step that claims AC coverage | Create/update `EVD/` + `STATE.md`; run `validate-evidence` |
| Level `off` | Optional artifacts; no gate |
| Before PLAN step **Completed** when level ≥ `cheap` | Gate must pass |

## Must not

- Use O3 / Task parallelism as the evidence verifier
- Mark step done at level ≥ `cheap` with empty `EVD/` or missing matrix
- Treat SQLite / OpenSpec / `.specs/` as evidence SoT
- Dump full memory-bank or PRD into EVD files

TRACE / living loop (`converge` → `sync_current` → `archive`) is **P3**: see `TRACE-ARCHIVE-CONTRACT.md` (not this file).
