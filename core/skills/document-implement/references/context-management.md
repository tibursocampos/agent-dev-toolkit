## Context management

After each completed documentation step:

1. Save all touched markdown and `plan.md`.
Checkpoint durable workflow progress at the workflow-defined boundaries; context usage does not add a stop gate.
3. Do not start the next **Kind: new** pending step in the same session when paused (coalesced **update** work for the current step may finish first).

Handoff:

```
New chat: /document-implement
```

---
