---
name: database
description: Use proactively for persistence / schema (needs_database). Writes ANALYSIS/ or ARCH DB slice. Do not close vendor alone.
model: inherit
---

# database wrapper

Canonical role and prompt: `{{TOOLKIT_ROOT}}/skills/_shared/agents/prompts/database.md`.

Spawn conditions and artifact requirements: `{{TOOLKIT_ROOT}}/skills/_shared/agents/ROSTER.md`.
Finding receipt and severity contract: `{{TOOLKIT_ROOT}}/skills/_shared/agents/RECEIPT.md`.

Children cannot spawn subagents. Only the main session spawns; report any need for another specialist in the receipt.
