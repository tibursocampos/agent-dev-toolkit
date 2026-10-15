## Required checklist acquisition (REQ-010 / CA10)

Load this contract during Steps 2–4 whenever FEATURE complexity is `medium` or `complex`.

### Decide whether a checklist is required

1. Resolve the canonical feature/story and read FEATURE **Complexity**. Do not infer `trivial` from missing metadata. If complexity is missing or contradictory, stop with `open_question` and resolve it before PLAN authoring.
2. For `trivial`, no `REFINE/tasks.md` is required; create one PLAN step from the accepted PRD and continue the regular checks.
3. For `medium` or `complex`, `REFINE/tasks.md` is required. If it exists, validate it before consuming it. If it is absent, invoke the checklist owner as below.

### Coordinate the owner skill

- `split-story-checklist` is the sole author of `REFINE/tasks.md`; `sdd-plan` must not create, edit, replace, or renumber it.
- Resolve the canonical portable `STORY.md` path for this story. Invoke `split-story-checklist` with that path and only the context it needs. Preserve that skill's session/write confirmations, open-question behavior, complexity policy, and output contract; the plan's authorization does not waive a gate required by the owner skill.
- When the host exposes effective `subagents=native`, prefer one bounded specialist invocation with the STORY path and a receipt. The receipt identifies the output path and reports `done`, `blocked`, or `failed`; do not accept a claim of completion without re-reading the artifact.
- When effective `subagents=none`, capability is unknown, or the spawn mechanism is unavailable, execute the `split-story-checklist` workflow in the current flow. Do not hard-fail and do not turn this into an operator handoff loop.
- A checklist specialist may ask a necessary question. Keep the original planning flow suspended until every question is answered; an unanswered question is `open_question`, not approval. Resume this same plan only after the owner flow finishes successfully.

### Validate output, then resume

Re-read `features/NNN-slug/{USnn|TSnn}/REFINE/tasks.md` after the owner returns. Confirm all of the following:

- The exact canonical story checklist path exists and is non-empty; no alternate or duplicate checklist was substituted.
- It is the checklist produced by `split-story-checklist`, follows the current complexity policy and output template, and contains step headings with stable `STEP n` identifiers.
- IDs are unique, positive, ordered as declared, and any dependency refers to a declared ID. Preserve every ID exactly when building the PLAN; do not add, remove, or renumber an ID in `sdd-plan`.
- Every planned step maps to at least one checklist task row with the same step ID. Required checklist groups, paths, dependencies, and tests are present sufficiently to support the normal self-review.

If the artifact is missing, invalid, incomplete, changed to a different path, or its IDs/dependencies fail validation, stop with `step_blocked` and the specific cause. Do not write a PLAN draft or proceed to normal review. If the artifact contains an open question, preserve it and stop with `open_question`; do not treat checklist generation or an affirmative write confirmation as resolving it.

After successful validation, resume the existing `sdd-plan` flow at REQ mapping, exploration, two self-reviews, preview, and the usual confirm-before-write. Normal PRD review, open-question gates, confirm-before-write, structural validation, and PLAN preview remain active. The checklist acquisition handoff is intermediate work: it does not itself approve or write the PLAN.

### Observable scenarios

| Scenario | Required result |
|----------|-----------------|
| Medium/complex checklist absent; native specialist available | Owner skill is invoked once with the canonical STORY path; valid output is re-read and planning resumes without a manual handoff |
| Medium/complex checklist already valid | IDs are read unchanged; no owner invocation or rewrite |
| Owner fails, returns no artifact, or output/IDs are invalid | Stop with cause; do not draft/write PLAN or claim a successful resume |
| Checklist has an unanswered question or owner asks one | Keep the plan suspended as `open_question`; resume only after the answer and owner completion |
| No subagents / unknown capability / unavailable spawn | Run the owner skill flow inline; preserve its gates and authorship, then validate and resume |
| Trivial story without checklist | Continue with one PLAN step; do not create checklist to satisfy the gate |
