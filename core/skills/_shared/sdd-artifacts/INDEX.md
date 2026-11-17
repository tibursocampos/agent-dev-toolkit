# SDD artifacts index - when to read each file

Load this index first. Read only the rows that match the current action. Guardrails are always mandatory; session state is conditional on the active consumer's explicit contract (see `_shared/skill-boilerplate.md`).

| File | Read when | Size |
|------|-----------|------|
| `SESSION.md` | Read only for a consumer that explicitly retains session helpers, such as `document-implement`. Not an authorization or execution prerequisite for Classic SDD or Orchestrated Delivery; see the Applicability matrix. | 22 KB |
| `PIPELINE.md` | **Conditional:** SDD skills (`sdd-spec`, `sdd-plan`, `sdd-develop`) and every `orchestrate-*` skill (required for orchestrate). Start at "Navigation block" and "Canonical paths". Skip for read-only Q&A. | 17 KB |
| `STORAGE.md` | Resolving or writing canonical `features/` paths, portable paths, or storage modes. | 17 KB |
| `STORAGE-RESOLUTION.md` | Resolving the global manifest and dynamic storage root (schema v2). Only when `STORAGE.md` points here. | 10 KB |
| `ARTIFACT-OWNERSHIP.md` | Deciding which skill owns a given artifact, or before writing an artifact outside the owner's scope (resolution rules and gaps). | 3 KB |
| `ARTIFACT-OWNERSHIP-MATRIX.md` | Looking up the authority, writer, and consumers of one artifact type (the full matrix). | 16 KB |
| `INVOCATION-CONTEXTS.md` | Deciding `direct` vs `orchestrated` invocation, or the `IC-DIRECT-ORCHESTRATED` rules. | 9 KB |
| `MEMORY-BANK.md` | Explicit `memory-bank-init` operations or when an existing bank is relevant to the current decision; no Classic/O1/O2/O3 gate. | 14 KB |
| `LIVE-STAGE-TABLE.md` | Progress-table standard (structure, label map, display points, completeness); governs O1, O2, O3, sdd-spec, sdd-plan, sdd-develop and Backlog Refine. | 14 KB |
| `CHANGE-CONTRACT.md` | Brownfield work that changes current specs (`CHANGE.md`). | 6 KB |
| `CONTRACT-PROVENANCE.md` | Labelling a contract or assumption as `agreed` or `invented`, or while authoring a PRD with contract claims. | 7 KB |
| `EVD-STATE-CONTRACT.md` | Evidence levels or the evidence-or-zero rule, when a skill reports evidence or state. | 8 KB |
| `TRACE-ARCHIVE-CONTRACT.md` | Living loop: `TRACE.jsonl`, archive, or sync-current steps at feature-wave close. | 9 KB |
| `SELECTIVE-RETRIEVAL.md` | Choosing what to read from large artifacts (paths and short excerpts, never full dumps). | 7 KB |
| `SEMANTIC-SUFFICIENCY.md` | Deciding whether consumed content is enough to answer a material question. | 13 KB |
| `SKILL-REFERENCE-RETRIEVAL.md` | Deciding which `references/*.md` file to load for a skill step (lazy-load rules). | 5 KB |
| `CLASSIC-EXTERNAL-ACCESS.md` | Classic SDD work that touches external access scope. | 5 KB |
| `readiness-severity.md` | Distinguishing material blockers from non-blocking questions. | 8 KB |

## Notes

- Session helpers remain available to consumers that explicitly retain them; they are not general Write/Shell gates. Classic SDD and Orchestrated Delivery rely on the approved PLAN and its execution table.
- `PIPELINE.md` holds the canonical path rules and Phase A/B host modes; read it before creating a PRD or PLAN.
- When a row says "only when", do not load the file otherwise.
