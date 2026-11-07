## Context-aware PLAN inputs

Resolve `invocation_context` once from `INVOCATION-CONTEXTS.md`. The selected context owns its input gates; sibling presence cannot switch or promote the context. See `PIPELINE.md` for the O2 route. This reference does not change `split-story-checklist` ownership of `REFINE/tasks.md`.

### `direct`: approved PRD controls checklist acquisition

The canonical PRD is the sole required planning input when it records both persisted content approval and a planning-ready status (`Pronto para planejamento` / `Ready for planning`). A write confirmation or conversational approval does not replace either persisted field. If content approval or status is missing, pending, unknown, or conflicting, stop with `open_question`; do not infer approval from another artifact.

No `FEATURE.md`, `STORY.md`, `CONTINUITY.md`, or Memory Bank is required or created. Their absence is not a complexity or readiness failure. The approved PRD's persisted complexity is the only source for direct checklist acquisition. For `trivial`, derive PLAN-native steps from approved PRD behavior, REQ, and CA without a checklist. For `medium` or `complex`, require `split-story-checklist` to produce `REFINE/tasks.md` before writing the PLAN. If that checklist is absent, coordinate its owner and keep planning suspended until it is complete. Do not create, edit, replace, or renumber checklist rows; preserve their IDs and dependencies exactly in the PLAN.

#### Deterministic complexity normalization

Use only the PRD's persisted `Complexidade` / `Complexity` field. Normalize the recognized labels to the Core taxonomy used by `story-sizing.md` and the triage contract:

| PRD value | Core value | Direct planning effect |
|-----------|------------|------------------------|
| `Baixa` / `Low` | `trivial` | No checklist required; derive PLAN-native steps from approved behavior, REQ, and CA |
| `Média` / `Medium` | `medium` | Require the owner checklist before PLAN authoring |
| `Alta` / `High` | `complex` | Require the owner checklist before PLAN authoring |
| explicit Core enum `trivial`, `medium`, or `complex` | same enum | Accept when it is the only complexity value or when its paired localized label matches this table; apply the matching checklist rule above |

If a localized label and explicit Core enum disagree, or the value is missing/unsupported, stop with `open_question`; do not consult FEATURE or guess from scope, step count, or sibling artifacts. `Alta (complex)` is a valid explicit pair. Complexity controls whether direct planning requires a checklist; it does not import O2 approval or backlog gates.

#### Optional linked context

For `trivial`, a `STORY.md` or checklist is optional. Consult one only when its canonical portable path is explicitly linked by the PRD's `## Related` section or provided by the operator. It may clarify grouping, implementation constraints, or dependencies only when consistent with the approved PRD. If an explicitly linked, valid checklist is adopted, preserve its existing IDs and dependencies exactly; do not create checklist rows or invoke its owner. The PRD remains authoritative for scope and acceptance. A missing optional sibling does not block planning. If optional material conflicts with PRD scope, acceptance, or dependency meaning, stop with `open_question` and identify the conflicting paths and clauses. Do not silently prefer the sibling or rewrite the PRD. For `medium` or `complex`, use the checklist-owner coordination below rather than this optional-context rule.

### `orchestrated`: preserve O2 gates

O2 remains responsible for its approved FEATURE/STORY backlog, persisted approvals, analysis and required artifacts. `sdd-plan` in this context does not use the direct fallback. Apply the canonical FEATURE complexity and checklist-owner contract below; missing or unapproved required backlog/story inputs, absent required checklist, invalid IDs, or unresolved questions block PLAN authoring. `split-story-checklist` remains the only writer of `REFINE/tasks.md`.

### Checklist acquisition and validation

For O2, resolve canonical FEATURE/STORY and read FEATURE **Complexity**. Direct instead uses the PRD rule above.

1. If complexity is missing or contradictory, stop with `open_question`.
2. For `trivial`, no `REFINE/tasks.md` is required; derive the PLAN from the approved PRD and preserve the regular O2 gates.
3. For `medium` or `complex`, `REFINE/tasks.md` is required. If absent, coordinate its owner before continuing. Never invent steps or checklist IDs.

#### Coordinate the owner skill

- `split-story-checklist` is the sole author of `REFINE/tasks.md`; `sdd-plan` must not create, edit, replace, or renumber it.
- Invoke the owner with the canonical portable `STORY.md` path and only the needed context. In `direct`, also provide the approved PRD path as the complexity source; in O2, provide the FEATURE path. Preserve its session/write confirmations, open-question behavior, complexity policy, and output contract; this PLAN's authorization does not waive owner gates.
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

### Paired context scenarios

| Scenario | Expected result |
|----------|-----------------|
| `direct`; approved trivial PRD; FEATURE/STORY/CONTINUITY/Memory Bank/REFINE tasks absent | PLAN-native steps map approved REQ/CA by behavior; no checklist acquisition, fabricated IDs, or task boxes |
| `direct`; approved medium/complex PRD; required checklist absent | Coordinate `split-story-checklist`; keep PLAN authoring suspended until its checklist is complete |
| `orchestrated`; required backlog/checklist absent, invalid, or unapproved | Block at the applicable O2 gate; do not use the direct PRD-only path |
| `direct`; optional linked checklist conflicts with approved PRD | Preserve PRD authority and stop for operator resolution; do not let checklist content override it |
| Context is explicit and an unrelated sibling suggests another route | Keep the explicit context; do not infer O2 from sibling presence |
