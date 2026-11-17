## O3 execution mode

O3 implementation is serial. Dispatch one eligible PLAN step to one child at a time, then reconcile its result before dispatching another. There is no execution-mode choice and no parallel queue.

### Manual fallback

When the host cannot spawn a child, hand off only the first eligible step:

```text
/sdd-develop - <portable-plan-path> - Step N
```

Include the approved scope and relevant evidence paths. Stop dispatch. The handoff does not mean the step started or completed; resume O3 after the operator returns with the result so the parent can reconcile it into the PLAN.

### Same-PLAN concurrency

Do not run two O3 conversations against the same PLAN at once. On resume, inspect the PLAN and relevant working tree for partial work. If another implementation may still be active, stop and resolve ownership with the operator before dispatch. Do not add a claim, session file, or new concurrency protocol as a substitute.

The operator's `orchestrator_mode` preference controls delegation behavior generally; it does not create an O3 implementation-parallel mode.
