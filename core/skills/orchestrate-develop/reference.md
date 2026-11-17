# O3 reference index

Procedural details for `skills/orchestrate-develop/SKILL.md`. Load only the relevant reference.

| Topic | Path |
|---|---|
| PLAN path and selection | `references/plan-acquisition.md` |
| PLAN semantics and acceptance | `references/plan-contract.md` |
| Queue, one-child dispatch, and reconciliation | `references/step-queue-spawn.md` |
| Step-by-step and continuous pacing | `references/develop-modes.md` |
| Serial dispatch and manual fallback | `references/execution-modes.md` |
| Shared table ownership | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/LIVE-STAGE-TABLE.md` |
| Handoff, stop, and requested closeout | `references/continuity-handoff.md` |
| Optional risk-based review | `references/step-verifier.md` |
| Authorization and path safety | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/PIPELINE.md`, `{{GUARDRAILS_PATH}}` |
| Spawn and receipt contracts | `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md`, `RECEIPT.md` |

O3 implementation dispatch is always serial.
