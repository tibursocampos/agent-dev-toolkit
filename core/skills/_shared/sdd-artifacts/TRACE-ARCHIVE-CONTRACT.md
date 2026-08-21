# TRACE + archive / sync current (living loop)

Install path after sync: `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/TRACE-ARCHIVE-CONTRACT.md`

**Language:** This guideline is **English**. Agent artifact prose in TRACE summaries may be **pt-BR** (default) or English if overridden. Identifiers, event names, and paths stay **English**.

Companion: `STORAGE.md` (canonical paths), `CHANGE-CONTRACT.md`, `EVD-STATE-CONTRACT.md`, `SELECTIVE-RETRIEVAL.md` (`SR-NO-FULL-DUMP`), `PIPELINE.md`.

---

## Purpose (REQ-006 / CA5)

**P3 living loop** after P0–P2 contracts exist:

```text
converge → sync current → archive
```

Event trail (markdown SoT, append-only):

```text
features/NNN-slug/TRACE.jsonl
```

Do **not** invent `openspec/`, `.specs/`, `.specify/`, or SQLite/FTS as the trail or archive SoT.

## Living loop phases

| Phase | Meaning | Typical writes |
|-------|---------|----------------|
| **converge** | Decide which CHANGE / PRD deltas become **current** living knowledge | TRACE event `converge`; optional notes in CONTINUITY |
| **sync current** | Apply accepted deltas into living specs (`memory-bank/` and/or named `docs/` domain files) | Selective edits to those paths; TRACE event `sync_current` with `targets` |
| **archive** | Close the feature trail for this wave; living specs and TRACE stay coherent | TRACE event `archive` with `status` |

Order is **strict for archive-complete**: at least one `converge`, then at least one `sync_current`, then at least one `archive` (timestamps non-decreasing; event order in the file).

**Current** (same convention as CHANGE): living domain / product knowledge in `memory-bank/` (and named docs when the delta truly touches them). Not OpenSpec / Spec Kit trees.

## TRACE.jsonl

Template: `skills/_shared/templates/features/TRACE.jsonl`.

- **Format:** JSON Lines (one JSON object per line; UTF-8; no BOM required)
- **Append-only** during the feature life; do not rewrite history to hide events
- **Portable paths only** in fields (no `^[A-Za-z]:/` or user-home InstallRoot embeds)

### Required fields (every event)

| Field | Type | Rule |
|-------|------|------|
| `ts` | string | ISO-8601 UTC (e.g. `2026-08-21T18:00:00Z`) |
| `event` | string | Event name (see below) |
| `feature` | string | Portable feature root: `features/NNN-slug` |

### Living-loop event names

| `event` | Extra fields | Rule |
|---------|--------------|------|
| `converge` | `summary` (string, non-empty) | Optional `paths` (string array of portable paths) |
| `sync_current` | `summary`, `targets` (non-empty string array) | Each target under `memory-bank/` or `docs/` — **not** `openspec/`, `.specs/`, `.specify/` |
| `archive` | `summary`, `status` | `status` = `archived` (or `closed` alias accepted by validate) |

### Optional trail events (allowed anytime)

Examples: `develop_start`, `step_done`, `evidence`, `validate`, `note`. Same required fields (`ts`, `event`, `feature`); extra keys allowed. These do **not** replace the three living-loop events for archive-complete.

## Coherence (living specs ↔ archive)

After `archive`:

1. TRACE contains the ordered living-loop triad above
2. Every `sync_current.targets` entry is a selective living-doc path (no full bank dump — `SR-NO-FULL-DUMP`)
3. Brownfield features that ran CHANGE still keep `features/NNN-slug/CHANGE.md` as the delta record; archive does **not** delete CHANGE
4. Markdown under `features/` + `memory-bank/` remains SoT (RN01)

## Structural validate

```text
.\scripts\validation\validate-trace.ps1 -FeatureRoot <features/NNN-slug> [-RequireArchiveComplete]
```

| Mode | Behavior |
|------|----------|
| Default | If `TRACE.jsonl` is missing → exit 0 (trail optional until close). If present → every line valid JSON + required fields |
| `-RequireArchiveComplete` | TRACE must exist and pass living-loop triad + sync target rules |

Exit 0 = OK. Exit ≠ 0 = fix before declaring archive done. Smoke: `Assert-TraceArchiveContract.ps1`. Deterministic only (RNF-001) — never LLM-as-validator.

## When to write

| Moment | Action |
|--------|--------|
| During `sdd-develop` / O3 (milestones) | Append optional trail events |
| Feature wave close (after EVD/STATE when used; before or with P-DOC) | Run **converge → sync current → archive**; append the three events; run `validate-trace -RequireArchiveComplete` |
| Greenfield with no bank sync needed | Still record `sync_current` with explicit target note (e.g. `memory-bank/` constitution touch or documented no-op path agreed in summary) — prefer a real selective path when any living doc changed |

## Must not

- Use SQLite / FTS / OpenSpec / `.specs/` as TRACE or archive SoT
- Dump full `memory-bank/` or full PRD into TRACE payloads (`SR-NO-FULL-DUMP`)
- Skip `sync_current` targets that point at forbidden trees
- Treat O3 parallelism as the archive verifier (same as evidence: sequential script gate)
- Create autonomous “controllers” or a second CLI for this loop (OOS)
