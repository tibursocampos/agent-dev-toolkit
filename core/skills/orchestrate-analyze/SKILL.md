---
name: orchestrate-analyze
description: >-
  Orchestrated Delivery O1: understand a multi-story or brownfield demand,
  investigate concrete questions, prepare a FEATURE and justified stories, then
  hand off to O2. No application code.
---

## Read first

Read `_shared/skill-boilerplate.md`, then `PIPELINE.md`, `STORAGE.md`, and
`INVOCATION-CONTEXTS.md`. These define shared authorization, path, and
invocation rules. O1 does not add separate artifact-write or backlog approval
gates. The complete implementation PLAN receives one explicit approval in O2
before implementation.

# Skill: orchestrate-analyze

## When to use

Use for a complex, multi-story, multi-area, or materially uncertain feature.
For a clear single story, route to Classic SDD; for one informal backlog item,
route to Backlog Refine. A trivial issue may go directly to `developer` or the
relevant stack skill. Reuse context the user already supplied.

An identified EPIC and selected feature ID may be read narrowly as evidence.
Do not infer relevance from a filename alone or require promotion of the whole
EPIC.

## Outcome and boundaries

O1 produces a comprehensible FEATURE and justified US/TS/Bug stories under the
resolved `features/` root, plus justified analysis records when they add useful
evidence. It does not write PRDs, PLANs, or application code. It ends with a
handoff to O2 (or a more appropriate direct workflow).

Existing FEATURE/STORY/PRD/PLAN material is canonical according to its role.
Existing CONTINUITY, CHANGE, TASKS, and Memory Bank files are optional context.
O1 does not require their creation, conversion, synchronization, or deletion.
Do not create `ANALYSIS/`, `ARCH/`, or `SEC/` solely because of brownfield
classification or a `needs_*` flag.

## Flow

1. **Classify intent.** Reuse the request and cited evidence; select full O1,
   Classic SDD, Backlog Refine, or a direct developer handoff. See
   `references/intent-classification.md` and `references/triage.md`.
2. **Resolve storage and resume context.** Use `STORAGE.md` for roots and
   portable paths. Read relevant existing artifacts and optionally consult an
   existing Memory Bank when it can answer a concrete question. Do not create or
   refresh one as an O1 prerequisite.
3. **Understand the demand.** Identify the desired outcome, relevant current
   behavior, constraints, and known areas. Classify nature, complexity, scope,
   and investigation signals proportionally. Do not repeat discovery already
   answered by supplied context.
4. **Investigate concrete questions.** Use a specialist only when its expertise
   is useful for a specific question. Independent investigations may run in
   parallel. Distinguish observed facts, inferences, suggestions, and decisions.
   Suggestions do not enter scope without an operator decision.
5. **Synthesize.** Prepare or revise FEATURE and stories as needed. Keep
   behavior, scope, acceptance, dependencies, material questions, and evidence
   clear. Record relevant brownfield current behavior, intended change, and
   concrete risks in the FEATURE/STORY or PRD/PLAN destination as appropriate.
   Create separate ANALYSIS/ARCH/SEC notes only when the evidence or decision
   benefits from a distinct record.
6. **Resolve material questions.** Ask only when behavior, acceptance, scope,
   required access, or an implementation decision cannot be determined. Name
   affected work. Minor questions and optional improvements remain visible and
   do not block independent work.
7. **Handoff.** Summarize the understanding, stories, material decisions or
   unresolved questions, evidence limits, and next action. O2 prepares the
   PRD/PLAN set and obtains one explicit approval before implementation.

## Session progress display

O1 owns one contextual progress table under
`LIVE-STAGE-TABLE.md` § O1. Show the complete table at start, meaningful state
changes, blocking decisions and their resolution, reconciliation of specialist
results, resume, and handoff. Combine adjacent events into one redraw. Do not
display a second cumulative checkpoint.

## Specialists

Use the shared `ROSTER.md` for signals and roles and `SPAWN.md` for delegation
rules. A flag or brownfield label alone does not require an agent, folder, or
sidecar. If native subagents are unavailable, use the documented in-parent
fallback where appropriate; do not fail only because an agent is unavailable.
Specialists do not implement product code in O1.

## References

| Need | Reference |
|---|---|
| Intent and routing | `references/intent-classification.md`, `references/triage.md` |
| Paths and selective evidence | shared `STORAGE.md`, `SELECTIVE-RETRIEVAL.md` |
| Specialist choice and dispatch | shared `ROSTER.md`, `SPAWN.md`, `references/spawn-map.md` |
| Story synthesis | `references/story-synthesis.md` |
| Handoff | `references/boundaries-handoff.md` |
| Optional Memory Bank context | `references/memory-bank-gate.md` |

## Must not

- Require a Memory Bank, CONTINUITY, CHANGE, TASKS, mirrored ARCH, fixed
  scorecard, folder, or validator solely to complete O1.
- Recreate a backlog approval or architecture-style approval gate.
- Treat a suggestion as approved scope or make minor questions block unrelated
  work.
- Invent evidence, architecture, behavior, or product decisions.
- Write PRD/PLAN or product code, or perform external actions not authorized by
  the user.
- Read or write outside the resolved feature root without explicit authority.

## Handoff

When multi-story delivery is ready for planning:

```text
/orchestrate-deliver - <portable-feature-path>
```

For a clear single story, hand off to `/sdd-spec`; for an informal item, use
`/refine-story`. No backlog approval token is required before these handoffs.
