## Context-aware PLAN inputs (REQ-001 / REQ-013 / REQ-014)

Resolve `invocation_context` once from `INVOCATION-CONTEXTS.md`. The selected context owns its input gates; sibling presence cannot switch or promote the context. See `PIPELINE.md` for the O2 route. This reference does not change `split-story-checklist` ownership of `REFINE/tasks.md`.

### `direct`: approved PRD is sufficient

The canonical PRD is the sole required planning input when it records both persisted content approval and a planning-ready status (`Pronto para planejamento` / `Ready for planning`). A write confirmation or conversational approval does not replace either persisted field. If content approval or status is missing, pending, unknown, or conflicting, stop with `open_question`; do not infer approval from another artifact.

No `FEATURE.md`, `STORY.md`, `CONTINUITY.md`, Memory Bank, or `REFINE/tasks.md` is required or created. Their absence is not a complexity or readiness failure. By default, `sdd-plan` derives PLAN-native steps from approved PRD behavior, REQ, and CA: group related behaviors into small verifiable outcomes, preserve declared dependencies, and map every REQ to a step. Do not invent checklist IDs or task rows, claim task-box coverage, or invoke `split-story-checklist` to make the direct plan possible.

#### Deterministic complexity normalization

Use only the PRD's persisted `Complexidade` / `Complexity` field. Normalize the recognized labels to the Core taxonomy used by `story-sizing.md` and the triage contract:

| PRD value | Core value | Direct planning effect |
|-----------|------------|------------------------|
| `Baixa` / `Low` | `trivial` | May use one PLAN-native step if the approved behavior forms one verifiable outcome; otherwise group by distinct behavior without adding a checklist gate |
| `Média` / `Medium` | `medium` | Derive PLAN-native steps by behavior/REQ/CA; no checklist acquisition |
| `Alta` / `High` | `complex` | Derive PLAN-native steps by behavior/REQ/CA; no checklist acquisition |
| explicit Core enum `trivial`, `medium`, or `complex` | same enum | Accept when it is the only complexity value or when its paired localized label matches this table |

If a localized label and explicit Core enum disagree, or the value is missing/unsupported, stop with `open_question`; do not consult an absent FEATURE or guess from scope, step count, or sibling artifacts. `Alta (complex)` is a valid explicit pair. Complexity informs planning granularity; it does not create an O1/O2 backlog gate in `direct`.

#### Optional linked context

A `STORY.md` or checklist is optional. Consult one only when its canonical portable path is explicitly linked by the PRD's `## Related` section or supplied by the operator. It may clarify grouping, implementation constraints, or dependencies only when consistent with the approved PRD. If an explicitly linked, valid checklist is adopted, preserve its existing IDs and dependencies exactly; do not create checklist rows or invoke its owner. The PRD remains authoritative for scope and acceptance. A missing optional sibling does not block planning. If optional material conflicts with PRD scope, acceptance, or dependency meaning, stop with `open_question` and identify the conflicting paths and clauses. Do not silently prefer the sibling or rewrite the PRD.

### `orchestrated`: preserve O2 gates

O2 remains responsible for its approved FEATURE/STORY backlog, persisted approvals, analysis and required artifacts. `sdd-plan` in this context does not use the direct fallback. Apply the canonical FEATURE complexity and checklist-owner contract below; missing or unapproved required backlog/story inputs, absent required checklist, invalid IDs, or unresolved questions block PLAN authoring. `split-story-checklist` remains the only writer of `REFINE/tasks.md`.

### O2 checklist acquisition and validation

For O2, resolve canonical FEATURE/STORY and read FEATURE **Complexity**. This gate is intentionally not applied to `direct`.

1. If complexity is missing or contradictory, stop with `open_question`.
2. For `trivial`, no `REFINE/tasks.md` is required; derive the PLAN from the approved PRD and preserve the regular O2 gates.
3. For `medium` or `complex`, `REFINE/tasks.md` is required. If absent, coordinate its owner before continuing. Never invent steps or checklist IDs.

#### Coordinate the owner skill

- `split-story-checklist` is the sole author of `REFINE/tasks.md`; `sdd-plan` must not create, edit, replace, or renumber it.
- Invoke the owner with the canonical portable `STORY.md` path and only the needed context. Preserve its session/write confirmations, open-question behavior, complexity policy, and output contract; this PLAN's authorization does not waive owner gates.
- When the host exposes effective `subagents=native`, prefer one bounded specialist invocation with the STORY path and a receipt. The receipt identifies the output path and reports `done`, `blocked`, or `failed`; re-read the artifact before accepting completion.
- When effective `subagents=none`, capability is unknown, or spawn is unavailable, run the owner skill workflow inline. Preserve its gates and authorship; do not hard-fail or turn it into a manual handoff loop.
- Keep the planning flow suspended while the owner has an unanswered question. Resume only after the owner finishes successfully.

#### Validate output, then resume

Re-read `features/NNN-slug/{USnn|TSnn}/REFINE/tasks.md` after the owner returns. Confirm:

- The exact canonical story checklist path exists and is non-empty; no alternate or duplicate checklist was substituted.
- It follows the current output template and contains stable `STEP n` identifiers.
- IDs are unique, positive, ordered as declared, and dependencies refer to declared IDs. Preserve every ID exactly when building the PLAN.
- Every planned step maps to at least one checklist task row with the same step ID; required paths, dependencies, and tests support self-review.

If the artifact is missing, invalid, incomplete, changed to a different path, or its IDs/dependencies fail validation, stop with `step_blocked` and the specific cause. An unanswered question remains `open_question`. After successful validation, resume REQ mapping, exploration, the two self-reviews, preview, and confirm-before-write. Checklist acquisition does not approve or write the PLAN.

### Paired context scenarios (CT15 / CT16)

| Scenario | Expected result |
|----------|-----------------|
| `direct`; approved complex PRD; FEATURE/STORY/CONTINUITY/Memory Bank/REFINE tasks absent | PLAN-native steps map approved REQ/CA by behavior; no checklist acquisition, fabricated IDs, or task boxes |
| `orchestrated`; required backlog/checklist absent, invalid, or unapproved | Block at the applicable O2 gate; do not use the direct PRD-only path |
| `direct`; optional linked checklist conflicts with approved PRD | Preserve PRD authority and stop for operator resolution; do not let checklist content override it |
| Context is explicit and an unrelated sibling suggests another route | Keep the explicit context; do not infer O2 from sibling presence |
