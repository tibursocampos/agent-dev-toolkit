# adt-sdd-plan — command playbook

Load after the shared pipeline/storage context. Read one relevant reference at a time.

| Stage | Action | Guidance |
|---|---|---|
| Context | Resolve direct vs orchestrated invocation once; inherit the parent's context when supplied. | `INVOCATION-CONTEXTS.md` |
| Source | Locate the PRD or use a sufficiently specified demand. Read relevant linked artifacts only. | `filename-numbering.md`, `selective-retrieval.md` |
| Clarify | Resolve only material decisions; identify which work they affect. | `PIPELINE.md` |
| Explore | Inspect relevant sources for current behavior, constraints, dependencies, and validation. | `plan-magro.md`, `challenge-vagueness.md` |
| Draft | Derive outcome-based steps and one execution progress table from the source. | `template-usage.md`, `baby-step-sizing.md` |
| Review | Perform one substantive review; correct material gaps. | `self-review.md` |
| Persist | Save the canonical PLAN. Optional validators may diagnose content; they do not decide authorization. | `filename-numbering.md`, `validate-plan.md` |
| Approval / handoff | Direct calls present the complete PLAN for one approval and then hand off. O2 receives the draft for its single approval interaction. | `PIPELINE.md`, `LIVE-STAGE-TABLE.md` |

## Progress display

A direct invocation shows its complete contextual table at start, meaningful state changes, blocking decisions and their resolution, specialist reconciliation, resume, and handoff. Combine adjacent events into one redraw. When O2 calls `adt-sdd-plan`, O2 owns the only table; do not render this skill's table internally. Use `LIVE-STAGE-TABLE.md` for the applicable projection.

The progress table is separate from the PLAN's execution progress table. Do not add a cumulative chat checkpoint or a second persisted status list.

## Optional PLAN validator

`references/validate-plan.md` describes an optional diagnostic. Run it only when useful to check the artifact or when the user/plan requests it. A structural diagnostic cannot approve content or block a substantively complete PLAN solely for formatting, headings, or numbering.

Selective retrieval: `references/selective-retrieval.md`. Product-document language follows the user language unless repository conventions or an explicit override apply: `references/product-docs-language.md`.
