# Session report

Use this block after the PLAN is saved. Identifiers stay English. Sentences follow the user chat language (`LANGUAGE.md`).

```text
STEP_COMPLETED | STEP_BLOCKED
Step: {step id} — {title}
Validation: PASS | BLOCKED
Evidence: {portable path or command result}
Previous unblock: {what cleared the old block} | none
Next eligible: {step ids}
Counts: pending={n} in_progress={n} blocked={n} completed={n}
Portability: LOCAL_ONLY | SHARED
Implement weight: Low | Medium | High | Very high
```

`SHARED` only after commit and push. Until both exist, portability is `LOCAL_ONLY`.

`STEP_COMPLETED` only when the step acceptance and the step test passed (`plan-contract.md`). No duration.

Handoff for the next step stays a new chat:

```text
/sdd-develop - <portable-plan-path> - Step {next}
```

## Context checkpoint (mandatory)

From `context-management.mdc` after PLAN persist:

1. Update the PLAN.
2. Assess context usage if visible.
3. At **≥ 40%:** show a pause message; do not start the next PLAN step in this session.
4. At **≥ 80%:** stop; the user must start a new chat.

Include in the pause message: saved PLAN path, last step id, next eligible step ids.
