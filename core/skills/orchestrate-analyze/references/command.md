# orchestrate-analyze flow

Load shared `PIPELINE.md`, `STORAGE.md`, and `INVOCATION-CONTEXTS.md` before
starting. Use this sequence as a working guide; omit steps that do not help the
request.

| Stage | Work | Reference |
|---|---|---|
| 1 | Classify intent and choose O1 or a direct path | `intent-classification.md`, `triage.md` |
| 2 | Resolve feature storage and read relevant existing context | `process-common.md`, `STORAGE.md` |
| 3 | Understand the outcome, current behavior, limits, and concrete unknowns | `triage.md` |
| 4 | Investigate material questions; parallelize independent analysis if useful | `spawn-map.md`, shared `ROSTER.md`, `SPAWN.md` |
| 5 | Prepare or revise FEATURE and justified stories; keep evidence and decisions traceable | `story-synthesis.md`, shared templates |
| 6 | Resolve only material questions that block affected work | `process-common.md` |
| 7 | Summarize and hand off to O2, Classic SDD, or Backlog Refine | `boundaries-handoff.md` |

## Progress table

O1 owns one live table as defined in shared `LIVE-STAGE-TABLE.md`. Render the
complete current table at start, meaningful transitions, blocking decisions and
their resolution, specialist-result reconciliation, resume, and handoff.
Adjacent events may share a redraw. Do not render a cumulative checkpoint or
second progress table.

## Memory Bank

An existing Memory Bank is optional context. Read only relevant material when
it answers a concrete question. O1 does not initialize, refresh, or gate on a
Memory Bank; see `memory-bank-gate.md` for that boundary.

## Specialist investigation

Use a specialist only for a concrete question. Brownfield classification and
`needs_*` signals alone do not require a specialist folder or architecture
mirror. Keep findings labeled as observed fact, inference, suggestion, or
decision. Suggestions do not expand scope without an operator decision.

## Synthesis and handoff

Create only artifacts useful to the outcome. Keep relevant behavior and risks
in the canonical FEATURE/STORY or a justified analysis note. There is no
backlog approval gate. O2 prepares and presents the complete PLAN set for one
explicit approval before implementation. See `story-synthesis.md` and
`boundaries-handoff.md`.
