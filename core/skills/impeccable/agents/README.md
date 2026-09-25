# Impeccable finish helpers

These four files are upstream subagent instructions for craft and live finish. They are not the toolkit roster in `core/skills/_shared/agents/`.

Do not spawn them from `sdd-spec`, `sdd-plan`, `sdd-develop`, or `orchestrate-*`.

A vendored instruction that calls `{{scripts_path}}/impeccable` has no launcher in this harness. Do not invent the binary. File writes still wait for user sim (`core/policy/guardrails.md`).
