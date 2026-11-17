# 01 — Orchestrated Delivery

Orchestrated Delivery coordinates multi-story or brownfield work through O1 analysis, O2 specification/planning, and optional O3 implementation. Canonical decisions and detailed procedure live in [`PIPELINE.md`](../../core/skills/_shared/sdd-artifacts/PIPELINE.md) and the three `orchestrate-*` skill guides.

## Flow

| Phase | Skill | Result |
|-------|-------|--------|
| O1 — Analyze | `orchestrate-analyze` | A clear feature outcome and justified stories; specialist analysis only for concrete questions. |
| O2 — Deliver | `orchestrate-deliver` | A PRD and executable PLAN for each selected story. |
| O3 — Develop (optional) | `orchestrate-develop` | A serial queue, one PLAN step per child, with each result reconciled before the next dispatch. |

Classic SDD can also start directly from a sufficiently clear demand. O1/O2 are not prerequisites for a single feature with a clear path.

## Approval and open questions

O1 and O2 may draft and save working artifacts as part of preparation. O2 presents the complete implementation PLAN, or an explicitly listed set of PLANs, for one approval before implementation. A new decision is needed only if behavior, acceptance, scope, access, or an implementation choice changes materially.

Only unanswered questions that prevent behavior, acceptance, scope, required access, or implementation decisions block the affected work. Minor questions and optional improvements remain visible. Independent stories may proceed when another story is blocked.

## Analysis and context

Investigate in proportion to the demand. A brownfield label alone does not require architecture mirroring, analysis folders, or validation artifacts. Use specialists when a concrete question needs them; record relevant findings in the canonical FEATURE/STORY or in a justified analysis note. Distinguish observed facts, inferences, suggestions, and decisions. Suggestions do not expand approved scope by themselves.

Memory Bank, CONTINUITY, CHANGE, and TASKS files are optional context. New work does not require creating them; resumed work does not require conversion, synchronization, or deletion. Prefer the canonical current requirements and PLAN. If older records conflict and the evidence does not resolve a material ambiguity, describe that conflict and ask only for the decision needed to proceed.

## Progress and closeout

The PLAN is the only persisted implementation progress source for O1/O2/O3. A live table is a chat projection with one owner: O1 owns its table, O2 owns one table across internal spec/plan calls, and O3 owns one table across internal develop calls. Skills called inside the active coordinator do not draw a competing table. O3 uses a single serial queue; it does not use claims or SESSION flags as authorization.

At closeout, run the validation required by the approved PLAN and one substantive review. Reuse current validation evidence when it covers the same stack, command, and unchanged tree. Revalidate only checks affected by a correction. Commit, push, PR, installation, and publication require their own authorization.

For exact paths, scope boundaries, unaffected consumers, and session-table display rules, use [`PIPELINE.md`](../../core/skills/_shared/sdd-artifacts/PIPELINE.md), [`LIVE-STAGE-TABLE.md`](../../core/skills/_shared/sdd-artifacts/LIVE-STAGE-TABLE.md), and the relevant skill references.
