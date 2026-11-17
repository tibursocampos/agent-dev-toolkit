## Optional PRD/PLAN diagnostics

The former PRD-to-PLAN-to-CHANGE preflight is not an O2 authorization or handoff gate. Do not run it automatically. A validator may still be used when it helps diagnose a concrete substantive inconsistency, but its formatting or structural result does not determine approval or readiness by itself.

For a relevant discrepancy, inspect the current canonical artifacts and evidence, identify the affected behavior or plan, and route the correction to the owner (`sdd-spec` for PRD, `sdd-plan` for PLAN). Keep unrelated stories eligible. If resolving the issue materially changes the implementation outcome or scope, present the updated PLAN for a new decision before implementation.

Legacy scripts and fixtures may remain until the runtime cleanup step determines their remaining consumers. Their presence does not reinstate the retired preflight gate.
