# Skill sessions

These pages are the operator map of the **52** invocable skills. Counts and ids come from `core/skills/*/SKILL.md` and `core/skills/_shared/skills-catalog/CATALOG.md`. Shared folders under `core/skills/_shared/` are packs, not skills.

Classic SDD and Orchestrated Delivery are coexisting tracks. Start with Classic SDD for one clear feature; use Orchestrated Delivery when multi-story analysis and coordination help. Backlog refinement is optional preparation, not a delivery prerequisite. To choose a flow, see [guides/flow-selection.md](../guides/flow-selection.md).

| Session | What it explains | Skills |
|---------|------------------|--------|
| [01 Orchestrated Delivery](01-orchestrated-delivery.md) | Proportional analysis, one PLAN-set approval, and serial O3 implementation | `adt-memory-bank`, `adt-orchestrate-analyze`, `adt-orchestrate-prepare`, `adt-orchestrate-implement` |
| [02 Classic SDD](02-classic-sdd.md) | Standalone spec, planning, and implementation with one approval and chosen cadence | `adt-sdd-spec`, `adt-sdd-plan`, `adt-sdd-develop`, `adt-read-sdd-artifact` |
| [03 Backlog shape](03-backlog-shape.md) | Scorecard and story rules inside analysis, versus a product-only refine | `adt-refine-story`, `adt-requirement-review`, `adt-split-story-checklist` |
| [04 Implement and guidelines](04-implement-and-guidelines.md) | Stack router, each `adt-*-developer`, architecture layers, UI brief | `adt-developer`, stack skills, `adt-blip-plugin-developer` |
| [05 Review and quality](05-review-and-quality.md) | Review modes, implementation survey, stack tests, coverage, refactor, performance, build repair | `adt-code-review`, `adt-code-explain`, `adt-run-tests`, `adt-test-coverage`, `adt-refactor`, `adt-performance-profile`, `adt-repair-dotnet-build` |
| [06 Framework upgrade](06-framework-upgrade.md) | Audit, plan, migrate, validate; packs | `adt-framework-upgrade` |
| [07 APIs, i18n, containers, messaging, EF](07-platform-skills.md) | Adjacent implementation skills and where they hand back | `adt-api-standards`, `adt-api-integrate`, `adt-i18n-manager`, `adt-containerize`, `adt-ef-add-migration`, `adt-scaffold-message-handler` |
| [08 Git and repo docs](08-git-and-docs.md) | Commit, push, pull request, documentation plan | `adt-commit`, `adt-push`, `adt-open-github-pr`, `adt-document-plan`, `adt-document-implement`, `adt-help-skills` |
| [09 Every skill](09-every-skill.md) | One section per skill id, with the session that expands it | all 52 |
| [Session behavior](../guides/session-behavior.md) | Chat language, parent orchestrator, optional response compression | policy, not a skill |

Install and CI stay in [INSTALL.md](../INSTALL.md) and [VALIDATION.md](../VALIDATION.md). Agent publish stays in [ADAPTERS.md](../ADAPTERS.md).
