# Live stage table

Chat-only progress table. Skill prose in this file is English. Render the table in the user chat language (`LANGUAGE.md`).

Weight tokens stay English: `Low`, `Medium`, `High`, `Very high`, or `—`. Weight is qualitative. It is never elapsed time and never a duration promise.

Do not write the **stage** table into `PLAN.md`, `FEATURE.md`, or `CONTINUITY.md`.

`sdd-develop` and `orchestrate-develop` do not render or redraw this weighted stage table, and do not emit a `Develop:` heartbeat. Direct `sdd-develop` follows `sdd-develop/references/execution-display.md`. O3 uses the separate PLAN-step progress table defined below. The PLAN progress table stays in the PLAN file.

The **step ledger** is different. It lives in the PLAN under `Implementation progress`. At step close, direct `sdd-develop` shows that ledger. O3 uses the PLAN-step progress table below, which lists every step. The persisted ledger columns are Step ID, Step, Dependencies, Analysis weight, Status, Evidence. Do not replace either operator-facing table with this weighted stage table. Weight tokens stay `Low`, `Medium`, `High`, `Very high`. They are not duration or story points.

## Columns

One table, this column order:

| Stage | Status | Analysis weight | What happened |
|-------|--------|-----------------|----------------|

## Status

Use these glyphs. The word beside the glyph follows the user chat language. Do not use a second status vocabulary.

| Glyph | Meaning |
|-------|---------|
| `☐` | Not started |
| `◐` | In progress |
| `☑` | Completed |
| `⊘` | Closed without success |
| `⚠` | Blocked |

Before the first row runs, mark that row `◐` and the rest `☐`. After each row finishes, redraw the **entire** table: completed rows become `☑`, the next row becomes `◐`, and `What happened` states the action or the evidence path. Use `⊘` or `⚠` when the step stops. Do not imply success.

`What happened` names actions, artifacts, evidence, and blockers. Do not narrate hidden reasoning.

If receipt validation is missing, incomplete, inconsistent, blocked, or failed, stop the redraw at the blocked state and do not present a successful final table or imply that a dependent spawn is authorized. Do not invent events, streaming, or heartbeat cadence absent from the host.

## Caller rows

### orchestrate-analyze step 8c

| Stage | Analysis weight |
|-------|-----------------|
| Read FEATURE and memory-bank | Medium |
| Specialists per `needs_*` | Very high |
| First findings pass | High |
| Second isolated pass | High |
| Close findings that have evidence | Medium |
| One question batch | Low |

Stop redraw when `open_question` fires. The blocked row is `⚠`. Do not continue to story folders.

### sdd-plan

| Stage | Analysis weight |
|-------|-----------------|
| Explore the repo | Very high |
| Draft | High |
| Review 1 | High |
| Review 2 | High |
| Preview | Low |
| Persist | Low |

Do not save this table in the PLAN.

### orchestrate-deliver (O2)

Render this table in the operator chat for the full O2 run, beginning before the first stage executes. After each stage and each story-cycle checkpoint, redraw the entire table with completed, current, and remaining rows. For série mode, repeat the story-cycle rows for each eligible US/TS in canonical dependency/order sequence; label each row with its story ID so the operator can see that the next story is continuing. Mark conditional checklist work completed with the evidence that it was required and run, or that the feature is `trivial` and the checklist is not applicable. Keep the same status glyph vocabulary defined above. The table is chat-only and is never written into `CONTINUITY.md`.

| Stage | Analysis weight |
|-------|-----------------|
| Resolve memory-bank and feature context | Medium |
| Reconcile canonical roster, required siblings, dependencies, and readiness | High |
| Choose execution mode and build eligible queue | Low |
| Per story: read STORY, required siblings, and relevant context | High |
| Per story: sdd-spec, PRD contestation, and readiness | High |
| Per story: checklist when required | Medium |
| Per story: sdd-plan and plan validation | High |
| Per story: present and process the applicable approval gate | Medium |
| Per story: reconcile checkpoint and recompute next eligible story | Medium |
| Cross-artifact analysis and PRD→PLAN→CHANGE preflight | High |
| Emit final multi-path handoff | Low |

In série mode, completing one story does not end O2. Reconcile `CONTINUITY.md` against canonical `FEATURE.md`, `STORY.md`, PRD/PLAN, required siblings, and dependencies; then read the next eligible US/TS context and continue its full O2 cycle. Do not ask an extra continue question. Stop only at a material blocker, a decision or approval gate that is due, or when every story is closed. Each story retains its own write and approval gates. `sdd-develop`'s one-step stop does not govern the O2 story queue.

### orchestrate-develop (O3) — PLAN-step progress table

O3 renders this table in the operator chat as a read-only projection of the approved PLAN's `Implementation progress` rows. It is separate from the weighted stage table above and from the durable PLAN ledger.

| Step ID | Step | Dependencies | Status | Checkpoint / evidence | Next action / owner |
|---------|------|--------------|--------|----------------------|---------------------|

Render exactly one row for every PLAN step, including consecutive steps such as S3–S7. Never combine multiple steps into a summary row. Use the canonical PLAN status token for each row; localize the remaining text and headers to the operator chat language. Keep pending, in-progress, completed, blocked, and skipped states distinct. Do not infer completion from a receipt without its persisted, reconciled checkpoint.

Render the complete table before the first spawn. After each child return, validate its receipt, read and reconcile the persisted PLAN checkpoint, then redraw the complete table before evaluating the next spawn. Redraw the affected row when a blocker, failure, or other advancement gate becomes observable. The table at step close serves as the operator-facing step ledger; do not add a raw ledger dump or duplicate stage-weight table.

When the host provides no intermediate event, preserve the last verifiable table until control returns. Do not invent streaming, heartbeat cadence, or retrospective progress. O3 closeout activities are tracked separately from PLAN-step rows.

### O3 closeout progress

When the operator requests wave close, render a separate closeout table; do not add closeout activities as PLAN steps or combine them with the PLAN-step progress table.

| Gate | Status | Owner | Evidence / next action |
|------|--------|-------|------------------------|

Include each applicable gate in the order defined by `orchestrate-develop/SKILL.md`: `run-tests`, `code-review`, review corrections when findings require changes, post-review `run-tests` when changes require it (otherwise `SKIPPED` with the no-rerun reason), security review, and any applicable build or operator-requested commit/push handoff. Do not imply that optional or not-yet-requested gates have run.

Use the PLAN closeout status tokens `PENDING`, `IN_PROGRESS`, `COMPLETED`, `BLOCKED`, and `SKIPPED`. `SKIPPED` requires a reason and evidence that the gate is not required. `COMPLETED` requires current evidence for the gate. `BLOCKED` names the owner and next action.

Render the applicable rows when closeout begins and update them after each observable gate result and after later changes that affect gate evidence. Associate each result with the reviewed/tested revision or changed scope when available. When a later change invalidates evidence, return only affected rows to `PENDING`, preserve unaffected evidence, identify the superseded evidence and next action, and do not advance past required gates with stale evidence. This table is a chat-only projection; it does not create persistent closeout state in `PLAN.md` or `CONTINUITY.md`.

### sdd-develop (direct)

Do not render the weighted stage table above. Follow `sdd-develop/references/execution-display.md` and show the PLAN step ledger at step close.

| Stage | Analysis weight |
|-------|-----------------|
| Re-check the plan against the repo | High if persistence, else Medium |
| Mark the step IN_PROGRESS and re-read | Low |
| Implement the step | High if acceptance cites more than one REQ, else Medium |
| Focused validation | Medium |
| Write the ledger and the checkpoint | Low |
| Step summary | Low |
