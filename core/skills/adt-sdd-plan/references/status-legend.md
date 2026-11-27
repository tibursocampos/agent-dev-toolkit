# PLAN progress states

The single execution progress table uses these persisted state tokens:

| Token | Meaning |
|---|---|
| `PENDING` | The step has not started. |
| `IN_PROGRESS` | Work is active. |
| `BLOCKED` | Work stopped for a recorded material cause. |
| `COMPLETED` | The step's acceptance is met and its required validation evidence is recorded. |

Do not maintain separate totals, percentages, checklists, queues, session flags, or claim status as progress. Derive counts from the table when useful. Localize prose and displayed labels; keep persisted tokens in English.

When work is omitted or removed, record the decision and its effect in the PLAN's canonical row or a material plan update. Do not add a fifth progress state solely for an optional action.
