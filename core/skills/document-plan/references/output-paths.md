## Output paths (consumer repo only)

| Artifact | Path |
|----------|------|
| High-level summary | `docs/overview.md` |
| Documentation plan | `docs/documentation-plan/plan.md` |
| Domain docs (later) | `docs/domains/<slug>.md` or path declared in plan steps |

Paths are English. Prose language = user choice (pt-BR or English).

The documentation plan is local workflow state: before writing it, `document-plan` verifies it is not tracked and that a repository-root `.gitignore` rule excludes it. If the rule is missing, the skill adds the narrow `/docs/documentation-plan/plan.md` pattern. Product docs such as `docs/overview.md` remain versionable.

---
