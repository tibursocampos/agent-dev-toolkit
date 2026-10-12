---
description: Preserve durable workflow progress at meaningful step boundaries
alwaysApply: false
---

# Progress checkpoints

This reference is optional and does not define a context-usage threshold, token budget, model-cost warning, session stop, or requirement to start another chat.

For multi-step work, save the workflow's existing control artifact at the boundary already defined by that workflow (for example, the PLAN step status or Orchestrated Delivery CONTINUITY). If the host exposes a context or compaction signal, the operator or agent may use it as a practical cue to save current progress; it does not override the workflow's gates or authorize skipping a step.

Prefer selective reads of the files needed for the next step. Do not load an entire Memory Bank or unrelated session history when the workflow calls for focused context.
