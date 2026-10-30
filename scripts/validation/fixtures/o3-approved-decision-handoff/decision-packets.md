# O3 approved-decision handoff fixtures

## Decision source

- Source: `features/019-o3-execution-contract/US01/PRD/019_o3_execution_contract.md` §4, REQ-009/CA9.
- Decision: Keep the PLAN as the only authority for accepted scope.
- Applies to: S7 handoff behavior and its acceptance.
- Required handling: Pass only the relevant source, decision, scope, and check to the recipient.

## Implementation handoff

- Source: portable PRD path, §4 REQ-009/CA9.
- Decision: Keep the PLAN as the only authority for accepted scope.
- Applies to: S7 implementation.
- Required handling: Add a relevant decision envelope; do not make an unapproved acceptance change.

## Review handoff

- Source: portable PRD path, §4 REQ-009/CA9.
- Decision: Keep the PLAN as the only authority for accepted scope.
- Applies to: S7 code-review handoff.
- Required handling: Assess the implementation against this decision and its cited acceptance.

## Material acceptance change

- Observed: Proposed change alters an accepted requirement.
- Action: Stop and return the change to the PLAN owner for an explicitly approved revision.
- Result: No implementation or review handoff proceeds under silently changed acceptance.

## Decision does not apply

- Observed: An approved decision has no bearing on the assigned step or review scope.
- Action: Omit it from that handoff.
