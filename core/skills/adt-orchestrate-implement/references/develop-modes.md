# O3 pacing (`step_by_step` | `continuous`)

Pacing controls when O3 stops between serial PLAN steps. It never changes the one-child-at-a-time rule.

| Pacing | Parent behavior |
|---|---|
| `step_by_step` | Dispatch the first eligible step, reconcile it into the PLAN, display the complete table, then stop and wait for authorization to continue. This is not a second approval of the PLAN. |
| `continuous` | After the initial approved scope and cadence are established, keep dispatching the next eligible step after each successful reconciliation. Stop on completion, a real blocker, or a material scope decision. |

Reuse an explicit valid cadence already recorded for the approved work. Ask only when no choice exists. An unanswered material question blocks only the affected work; do not repeat a cadence or PLAN-approval question on resume.

## Reconciliation before advancement

After every child result:

1. Inspect changed files and the requested step's acceptance and validation evidence.
2. Update the canonical PLAN row only when its acceptance is met; otherwise preserve or record its blocked/pending state and reason.
3. Re-read the PLAN and display the complete current O3 table.
4. In `step_by_step`, stop. In `continuous`, continue only when the next step is eligible and no material decision or concurrent owner blocks it.

The receipt is a navigation aid, not completion proof. SESSION flags, claims, and session-specific authorization helpers are not O3 prerequisites. A completed persisted PLAN row is not rerun because a transcript or receipt is absent; inspect partial work before deciding how to resume.
