---
name: read-sdd-artifact
description: Resolve canonical FEATURE/STORY/PRD/PLAN paths under features/ into a source_context envelope with artifact identity. Reject path traversal and paths outside features/. Use when invoking read-sdd-artifact or normalizing SDD artifact reads for child handoffs.
---

# Skill: read-sdd-artifact

## Trigger

Invoke when the consumer asks for skill **`read-sdd-artifact`** (host forms: `/read-sdd-artifact`, `$read-sdd-artifact`, `use skill read-sdd-artifact`, OpenCode `skill({ name: "read-sdd-artifact" })`), or needs a normalized **`source_context`** envelope for FEATURE / STORY / PRD / PLAN under `features/`.

## Outcome

- Happy path: one **`source_context`** envelope with artifact **identity** (kind, portable path, feature slug, story id when applicable, file name).
- Fail path: **no** partial envelope — precise reject reason (`path_traversal`, `outside_features`, `absolute_path_forbidden`, `unsupported_kind`, `not_found`, `empty_path`, `invalid_portable_path`).
- Consumers that already hold `source_context` for a path **skip** opaque re-read of that artifact (REQ-005).

## Lazy-load (only when needed)

| When | Path (after agent sync) |
|------|-------------------------|
| Portable path / features layout | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/STORAGE.md` |
| Selective retrieval | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/SELECTIVE-RETRIEVAL.md` |
| Invocation handoff (orchestrated) | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/INVOCATION-CONTEXTS.md` |
| Reference index (routing only) | `{{TOOLKIT_ROOT}}/skills/read-sdd-artifact/reference.md` |
| Process step detail (lazy) | `{{TOOLKIT_ROOT}}/skills/read-sdd-artifact/references/<section>.md` |

**Never by default:** do not preload all `references/*.md`, full PRD/PLAN bodies beyond the single target path, `memory-bank/`, TRACE emitters, or unrelated pipeline skill bodies. Load **one** section per Process step (`SKILL-REFERENCE-RETRIEVAL.md`).

## Reference routing

| Situation | Path |
|-----------|------|
| Envelope schema + kinds | `references/envelope-schema.md` |
| Normalize / validate path | `references/normalize-path.md` |
| Build envelope + consume + report | `references/build-consume-report.md` |
| Must not (full) | `references/must-not.md` |

## Rule ID

`RSA-SOURCE-CONTEXT`

## Process

Read `references/<section>.md` for procedural detail — **not** full `reference.md`.

### Caveman Mode
**NEVER** — Ignore `caveman_mode`. Keep reject reasons and envelope fields exact. Do not load `CAVEMAN.md` for compression.

### 0. Read-only gates
This skill is **read-only**. Do **not** require `write_confirmed` / new-artifact `sim` to resolve a path. Do **not** Write/Delete.

### 1. Normalize input path
Follow `references/normalize-path.md`.

### 2–4. Build envelope, consume, report
Follow `references/envelope-schema.md` then `references/build-consume-report.md`.

## Must not

Enforce the full list in `references/must-not.md`. Critical: no partial `source_context` on fail; no `..` / OS absolute / outside `features/`; no CONTINUITY/ANALYSIS/ARCH/SEC/CHANGE/memory-bank kinds.

## Handoff

- Pipeline / O3 children: pass `source_context` in scoped handoff so consumers skip opaque re-read
- Next authoring skills stay `sdd-spec` / `sdd-plan` / `sdd-develop` by id — this skill only normalizes reads
