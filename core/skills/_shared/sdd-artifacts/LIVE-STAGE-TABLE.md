# Live stage table

Chat-only progress table. Skill prose in this file is English. Render the table in the user chat language (`LANGUAGE.md`).

Weight tokens stay English: `Low`, `Medium`, `High`, `Very high`, or `—`. Weight is qualitative. It is never elapsed time and never a duration promise.

Do not write the **stage** table into `PLAN.md`, `FEATURE.md`, or `CONTINUITY.md`.

`sdd-develop` and `orchestrate-develop` do not render this stage table, do not redraw it, and do not emit a `Develop:` heartbeat. Their operator chat follows `sdd-develop/references/execution-display.md`. The PLAN progress table stays in the PLAN file.

The **step ledger** is different. It lives in the PLAN under `Implementation progress`. At step close, `sdd-develop` / `orchestrate-develop` show that ledger for every step. Columns: Step ID, Step, Dependencies, Analysis weight, Status, Evidence. Do not replace it with this stage table. Weight tokens stay `Low`, `Medium`, `High`, `Very high`. They are not duration or story points.

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

### sdd-develop / orchestrate-develop

Do not render these rows in the operator chat. Do not redraw them. The chat contract is `sdd-develop/references/execution-display.md`.

| Stage | Analysis weight |
|-------|-----------------|
| Re-check the plan against the repo | High if persistence, else Medium |
| Mark the step IN_PROGRESS and re-read | Low |
| Implement the step | High if acceptance cites more than one REQ, else Medium |
| Focused validation | Medium |
| Write the ledger and the checkpoint | Low |
| Step summary | Low |
