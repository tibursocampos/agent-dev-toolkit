# Skill sessions

These pages are the operator map of the **52** invocable skills. Counts and ids come from `core/skills/*/SKILL.md` and `core/skills/_shared/skills-catalog/CATALOG.md`. Shared folders under `core/skills/_shared/` are packs, not skills.

Classic SDD and Orchestrated Delivery are coexisting tracks. Start with Classic SDD for one clear feature; use Orchestrated Delivery when multi-story analysis and coordination help. Backlog refinement is optional preparation, not a delivery prerequisite. To choose a flow, see [guides/flow-selection.md](../guides/flow-selection.md).

| Session | What it explains | Skills |
|---------|------------------|--------|
| [01 Orchestrated Delivery](01-orchestrated-delivery.md) | Proportional analysis, one PLAN-set approval, and serial O3 implementation | `memory-bank-init`, `orchestrate-analyze`, `orchestrate-deliver`, `orchestrate-develop` |
| [02 Classic SDD](02-classic-sdd.md) | Standalone spec, planning, and implementation with one approval and chosen cadence | `sdd-spec`, `sdd-plan`, `sdd-develop`, `read-sdd-artifact` |
| [03 Backlog shape](03-backlog-shape.md) | Scorecard and story rules inside analysis, versus a product-only refine | `refine-story`, `requirement-review`, `split-story-checklist` |
| [04 Implement and guidelines](04-implement-and-guidelines.md) | Stack router, each `*-developer`, architecture layers, UI brief | `developer`, stack skills, `blip-plugin-developer` |
| [05 Review and quality](05-review-and-quality.md) | Review modes, implementation survey, stack tests, coverage, refactor, performance, build repair | `code-review`, `implementation-survey`, `run-tests`, `test-coverage`, `refactor`, `performance-profile`, `repair-dotnet-build` |
| [06 Framework upgrade](06-framework-upgrade.md) | Audit, plan, migrate, validate; packs | `framework-upgrade` |
| [07 APIs, i18n, containers, messaging, EF](07-platform-skills.md) | Adjacent implementation skills and where they hand back | `api-standards`, `api-integrate`, `i18n-manager`, `containerize`, `ef-add-migration`, `scaffold-message-handler` |
| [08 Git and repo docs](08-git-and-docs.md) | Commit, push, pull request, documentation plan | `commit`, `push`, `open-github-pr`, `document-plan`, `document-implement`, `help-skills` |
| [09 Every skill](09-every-skill.md) | One section per skill id, with the session that expands it | all 52 |
| [Session behavior](../guides/session-behavior.md) | Chat language, parent orchestrator, optional response compression | policy, not a skill |

Install and CI stay in [INSTALL.md](../INSTALL.md) and [VALIDATION.md](../VALIDATION.md). Agent publish stays in [ADAPTERS.md](../ADAPTERS.md).
