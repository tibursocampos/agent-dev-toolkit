# Skill sessions

These pages are the operator map of the **41** invocable skills. Counts and ids come from `core/skills/*/SKILL.md` and `core/skills/_shared/skills-catalog/CATALOG.md`. Shared folders under `core/skills/_shared/` are packs, not skills.

The complete delivery path is **Orchestrated Delivery**. Classic SDD is the contract that path runs for each story (spec, plan, one implementation step). Backlog shaping is built into analysis; a standalone refine invoke is for someone shaping a single backlog item, not for delivering a feature.

| Session | What it explains | Skills |
|---------|------------------|--------|
| [01 Orchestrated Delivery](01-orchestrated-delivery.md) | How a feature is classified, questioned, split, staffed with specialists, specified, planned, and implemented | `memory-bank-init`, `orchestrate-analyze`, `orchestrate-deliver`, `orchestrate-develop` |
| [02 Classic SDD](02-classic-sdd.md) | The three contracts Orchestrated Delivery loads, and how to run them alone for one clear story | `sdd-spec`, `sdd-plan`, `sdd-develop`, `read-sdd-artifact` |
| [03 Backlog shape](03-backlog-shape.md) | Scorecard and story rules inside analysis, versus a product-only refine | `refine-story`, `split-story-checklist` |
| [04 Implement and guidelines](04-implement-and-guidelines.md) | Stack router, each `*-developer`, architecture layers, UI brief | `developer`, eleven stack skills, `blip-plugin-developer`, `impeccable` |
| [05 Review and quality](05-review-and-quality.md) | Review modes, coverage, refactor, performance, build repair | `code-review`, `test-coverage`, `refactor`, `performance-profile`, `repair-dotnet-build` |
| [06 Framework upgrade](06-framework-upgrade.md) | Audit, plan, migrate, validate; packs | `framework-upgrade` |
| [07 APIs, i18n, containers, messaging, EF](07-platform-skills.md) | Adjacent implementation skills and where they hand back | `api-standards`, `api-integrate`, `i18n-manager`, `containerize`, `ef-add-migration`, `scaffold-message-handler` |
| [08 Git and repo docs](08-git-and-docs.md) | Commit, push, pull request, documentation plan | `commit`, `push`, `open-github-pr`, `document-plan`, `document-implement`, `help-skills` |
| [09 Every skill](09-every-skill.md) | One section per skill id, with the session that expands it | all 41 |
| [Session behavior](../guides/session-behavior.md) | Chat language, parent orchestrator, optional response compression | policy, not a skill |

Install and CI stay in [INSTALL.md](../INSTALL.md) and [VALIDATION.md](../VALIDATION.md). Agent publish stays in [ADAPTERS.md](../ADAPTERS.md).
