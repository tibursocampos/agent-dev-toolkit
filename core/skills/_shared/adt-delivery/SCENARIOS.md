# ADT delivery - key behaviors

Short list of behaviors the ADT delivery flow must keep. Check them by running the flow on a sample feature; the validator `scripts/validation/Assert-AdtDeliveryFlow.ps1` checks only that the files exist and their references resolve.

| ID | Area | Scenario | Expected |
|----|------|----------|----------|
| INV-01 | Invocation | Flow runs refine, plan and implement in one invocation | Demand carried through refinement, one approval, implementation |
| STP-01 | Start | Start preflight fails | Failures reported and the run stops before any task work |
| STP-02 | Entry | Plan requested while the Stage ledger reads `refine=pending` | Missing refinement reported and planning stops; no draft steps |
| STO-03 | Storage | Malformed storage configuration with global storage | Stops and asks to reconcile; never falls back to local storage |
| APR-01 | Approval | Plan presented for approval | One explicit approval covers the whole plan; refinement approval alone is not approval |
| APR-03 | Approval | Material change needed after approval | Affected step blocked, operator asked, renewed approval required |
| EXE-02 | Execution | Current branch is main, master or develop | Stops before changing code and proposes a feature branch |
| EXE-04 | Execution | Cadence step_by_step | Stops after each non-final step |
| EXE-08 | Execution | Unplanned file or step needed | Operator consulted before the file is touched |
| SPC-02 | Specialists | Security signals in the demand | needs_security is never defaulted to false |
| SPC-03 | Specialists | Specialist output | Findings returned in the receipt; no ANALYSIS, ARCH or SEC files written |
| CLO-05 | Closeout | Validation fails, is unavailable or is partial | Never reported as success |
| CLO-06 | Closeout | Delivery finished | Nothing committed, pushed, merged or published automatically |
