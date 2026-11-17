## Boundaries for sdd-develop

| Do not | Apply |
|---|---|
| Implement outside the approved PLAN outcome, scope, or step acceptance | Return a material change to the PLAN owner for a decision |
| Start a step before its dependencies are complete | Resolve the dependency from the canonical PLAN |
| Require a per-step confirmation after the PLAN approval | Use the selected `step_by_step` or `continuous` cadence |
| Add session flags, claims, checklists, progress counters, or CONTINUITY mirrors | Keep implementation state in the single PLAN progress table |
| Treat a receipt, validator, or planned check as proof by itself | Inspect relevant result/evidence and record actual validation in the PLAN row |
| Repeat unchanged tests or reviews only to satisfy a ceremony | Validate what changed and what the acceptance requires |
| Execute from a non-canonical or escaping PLAN path | Use `references/plan-acquisition.md` and preserve containment |
| Commit, push, create a PR, publish, install, or sync as a side effect | Do those only when separately requested |

Also preserve project language and coding conventions. See `references/plan-contract.md` for step completion semantics and the shared `PIPELINE.md` for cross-flow boundaries.
