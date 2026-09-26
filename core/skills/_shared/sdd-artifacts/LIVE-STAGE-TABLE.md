# Live stage table

Chat-only progress table. Skill prose in this file is English. Render the table in the user chat language (`LANGUAGE.md`).

Weight tokens stay English: `Low`, `Medium`, `High`, `Very high`, or `—`. Weight is qualitative. It is never elapsed time and never a duration promise.

Do not write this table into `PLAN.md`, `FEATURE.md`, or `CONTINUITY.md`.

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

### sdd-develop / orchestrate-develop

| Stage | Analysis weight |
|-------|-----------------|
| Re-check the plan against the repo | High if persistence, else Medium |
| Mark the step IN_PROGRESS and re-read | Low |
| Implement the step | High if acceptance cites more than one REQ, else Medium |
| Focused validation | Medium |
| Write the ledger and the checkpoint | Low |
| Step summary | Low |
