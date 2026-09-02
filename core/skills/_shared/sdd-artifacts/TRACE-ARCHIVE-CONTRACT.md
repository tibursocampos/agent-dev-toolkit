# TRACE + archive / sync current (living loop)

Install path after sync: `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/TRACE-ARCHIVE-CONTRACT.md`

**Language:** This guideline is **English**. Agent artifact prose in TRACE summaries may be **pt-BR** (default) or English if overridden. Identifiers, event names, and paths stay **English**.

Companion: `STORAGE.md` (canonical paths), `CHANGE-CONTRACT.md`, `EVD-STATE-CONTRACT.md`, `SELECTIVE-RETRIEVAL.md` (`SR-NO-FULL-DUMP`), `PIPELINE.md`.

---

## Purpose (REQ-005 / CA5; living loop)

**P3 living loop** after P0–P2 contracts exist:

```text
converge → sync current → archive
```

**Single SoT** event trail (JSON Lines, append-only):

```text
features/NNN-slug/TRACE.jsonl
```

Do **not** invent `openspec/`, `.specs/`, `.specify/`, SQLite/FTS, **`.agent-trace/`**, a second JSONL trail, or **git-notes as SoT** for this trail (RNF-003). Git-notes may exist elsewhere for other workflows; they are **not** the TRACE source of truth in this contract.

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

### Optional run metrics (REQ-005 / CA5)

Cross-cutting fields — **optional**. When a key is **present**, it is **normative** (validate-trace rejects malformed values). Emitters and harvest use these when the host exposes usage/timing/spawn context.

| Field | Type | Rule when present |
|-------|------|-------------------|
| `tokens` | number **or** object | Number ≥ 0 = total token count. Object: at least one of `prompt`, `completion`, `total`; each present value is a number ≥ 0 |
| `duration` | number **or** object | Number ≥ 0 = elapsed milliseconds. Object: required `ms` (number ≥ 0) |
| `spawn` | object | Nested spawn context on non-`spawn` events (e.g. `specialist_complete`, `step_done`). Requires non-empty string `role` and `outcome`; optional non-empty `reason`. Do **not** nest `spawn` on the top-level `event:"spawn"` line — use the orchestration fields `role` / `reason` / `outcome` there |

These fields never carry secrets, auth tokens, or PII (see **Redact / secrets** below).

#### JSON examples (run metrics)

```json
{"ts":"2026-08-21T11:45:00Z","event":"specialist_complete","feature":"features/042-auth","role":"sdd-develop","summary":"Step 2 done; tests pass","tokens":{"prompt":1200,"completion":800,"total":2000},"duration":45000,"spawn":{"role":"sdd-develop","outcome":"completed","reason":"PLAN step 2"}}
```

```json
{"ts":"2026-08-21T11:46:00Z","event":"step_done","feature":"features/042-auth","summary":"PASSO 5 schema extension","tokens":2000,"duration":{"ms":1200}}
```

### Living-loop event names

| `event` | Extra fields | Rule |
|---------|--------------|------|
| `converge` | `summary` (string, non-empty) | Optional `paths` (string array of portable paths) |
| `sync_current` | `summary`, `targets` (non-empty string array) | Each target under `memory-bank/` or `docs/` — **not** `openspec/`, `.specs/`, `.specify/` |
| `archive` | `summary`, `status` | `status` = `archived` (or `closed` alias accepted by validate) |

### Optional trail events (allowed anytime)

Same required fields (`ts`, `event`, `feature`) on every line. Extra keys allowed on informal events. These do **not** replace the three living-loop events for archive-complete.

**Informal examples** (no extra field contract): `develop_start`, `step_done`, `evidence`, `validate`, `note` — typically include a short `summary`.

**Normative orchestration events** (when used, extra fields below are **required**):

| `event` | Extra fields | Rule |
|---------|--------------|------|
| `retrieval` | `paths` (non-empty string array), `reason` (non-empty string) | Selective read audit (`SR-NO-FULL-DUMP`); portable paths only — no drive letters or user-home embeds |
| `gate` | `gate_id` (non-empty string), `response` (non-empty string) | Human or SESSION gate checkpoint (e.g. step approval, ARCH confirm) |
| `spawn` | `role` (non-empty string), `reason` (non-empty string), `outcome` (non-empty string) | Specialist spawn or in-parent fallback decision (`SPAWN.md`) |
| `specialist_complete` | `role` (non-empty string), `summary` (non-empty string) | Specialist pass finished; one-line outcome for parent synthesis |

Do **not** create a parallel trail (e.g. `.agent-trace/`) — extend this `TRACE.jsonl` only. Do **not** treat git-notes as a substitute SoT for TRACE.

### Redact / secrets (RNF-001)

TRACE payloads and emitter appends must **never** log:

- Auth secrets, API keys, passwords, private keys, connection strings
- Bearer/session tokens or raw `.env` values
- PII (names, emails, phone numbers) beyond what a portable path already encodes

Use env var **names**, placeholders (`***`, `YOUR_TOKEN`), or omit. Fail-open emitters must not echo sensitive tool bodies into TRACE. Structural validate does not scan for secrets — operators and emitters own redact before append.

#### JSON examples (orchestration events)

```json
{"ts":"2026-08-21T11:00:00Z","event":"retrieval","feature":"features/042-auth","paths":["memory-bank/domain-knowledge.md","features/042-auth/CONTINUITY.md"],"reason":"O3 step 2 prior context"}
```

```json
{"ts":"2026-08-21T11:05:00Z","event":"gate","feature":"features/042-auth","gate_id":"o3-step-spawn","response":"sim"}
```

```json
{"ts":"2026-08-21T11:06:00Z","event":"spawn","feature":"features/042-auth","role":"sdd-develop","reason":"PLAN step 2","outcome":"spawned"}
```

```json
{"ts":"2026-08-21T11:45:00Z","event":"specialist_complete","feature":"features/042-auth","role":"sdd-develop","summary":"Step 2 done; tests pass"}
```

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

- Use SQLite / FTS / OpenSpec / `.specs/` / **`.agent-trace/`** / a second JSONL as TRACE or archive SoT
- Treat **git-notes** as TRACE SoT under this contract
- Dump full `memory-bank/` or full PRD into TRACE payloads (`SR-NO-FULL-DUMP`)
- Log secrets, auth tokens, or PII in TRACE (RNF-001)
- Emit malformed `tokens` / `duration` / nested `spawn` when those keys are present
- Skip `sync_current` targets that point at forbidden trees
- Treat O3 parallelism as the archive verifier (same as evidence: sequential script gate)
- Create autonomous “controllers” or a second CLI for this loop (OOS)
