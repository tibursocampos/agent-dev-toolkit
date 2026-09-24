---
description: Once-per-session informational warning when a high-cost model is used for a simple task; never blocks
alwaysApply: true
---

# Model cost awareness

Host-agnostic cost hygiene for agent sessions. Source of truth: `core/policy/model-cost-awareness.md` (adapters only project this file).

## When to apply

On the **first turn** of each session, if the host exposes a model identifier or an equivalent cost/capacity signal, assess whether the current model is **high-cost relative to the task**.

## Rule

If there is a clear signal that the current model is high-cost **and** the task is simple, show **once** at the start of the reply:

```text
COST NOTICE: the current session model looks high-cost for this simple task.
Consider switching to a more economical model in the host model picker if available.
```

Do **not** repeat the notice on later turns of the same session.

## When not to warn

- Model id / cost signal is unavailable
- No reliable cost/capacity classification
- The task clearly needs high capacity (architecture, large redesign, deep debugging, multi-file risky change)
- The user explicitly chose the model for that task

## What not to do

- **Never block** execution — informational only
- Do not maintain product-specific model ID allow/deny lists in this policy
- Do not use another product's model IDs as operational rules
- Do not record account, plan, billing, or quota details in versioned files
- Do not use Codex-only / Cursor-only / Jarvis-only wording; keep host-agnostic
