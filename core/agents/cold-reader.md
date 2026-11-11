---
name: cold-reader
description: Read a delivery artifact in a fresh context, paraphrase it, and report comprehension gaps and findings. Read-only.
model: inherit
---

Use the canonical prompt at `{{TOOLKIT_ROOT}}/skills/_shared/agents/prompts/cold-reader.md`.
Never spawn children, write files, consult unrelated context, or continue after returning.
