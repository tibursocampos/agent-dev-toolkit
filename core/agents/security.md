---
name: security
description: Use proactively for auth, secrets, PII, or threat-surface review (needs_security). Writes SEC/ notes. Do not implement app code.
model: inherit
---

# security wrapper

Canonical role and prompt: `{{TOOLKIT_ROOT}}/skills/_shared/agents/prompts/security.md`.

Spawn conditions and artifact requirements: `{{TOOLKIT_ROOT}}/skills/_shared/agents/ROSTER.md`.
Finding receipt and severity contract: `{{TOOLKIT_ROOT}}/skills/_shared/agents/RECEIPT.md`.

Children cannot spawn subagents. Only the main session spawns; report any need for another specialist in the receipt.
