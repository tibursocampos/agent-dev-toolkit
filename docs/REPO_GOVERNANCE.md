# Repository governance

Public OSS policy for **agent-dev-toolkit**: who the docs are for, what visitors may do, and where policy lives.

**Summary:** clone and fork freely · **no upstream community PRs** · GitHub Issues = **bugs only** · security via [SECURITY.md](../SECURITY.md).

## Audiences

| Audience | Intent | Start here |
|----------|--------|------------|
| **Visitor** | Understand the toolkit, clone/fork, read policy | [README.md](../README.md), [INSTALL.md](INSTALL.md), [guides/01-getting-started.md](guides/01-getting-started.md), [CONTRIBUTING.md](../CONTRIBUTING.md) |
| **Operator** | Sync skills to an agent home, run validation | [INSTALL.md](INSTALL.md), [VALIDATION.md](VALIDATION.md), [ADAPTERS.md](ADAPTERS.md), [SKILLS.md](SKILLS.md) |
| **Maintainer** | Change this repository (write access / collaborators) | [CONTRIBUTING.md](../CONTRIBUTING.md) (Maintainers only), [VALIDATION.md](VALIDATION.md). See the CI and release policy below; required checks are configured remotely and can change independently of these docs. |

## Policy pointers

| Topic | Document |
|-------|----------|
| Clone / fork OK; no upstream PRs | [CONTRIBUTING.md](../CONTRIBUTING.md) |
| Issues = bugs only (no feature/contribution channel) | [CONTRIBUTING.md](../CONTRIBUTING.md) § Issues |
| Vulnerability reporting | [SECURITY.md](../SECURITY.md) |
| License | [LICENSE](../LICENSE) (MIT) |
| Install / sync / uninstall | [INSTALL.md](INSTALL.md) |
| Validation and CI | [VALIDATION.md](VALIDATION.md) |
| Documentation index | [README.md](README.md) (docs TOC) |

## Issues (bugs only)

GitHub Issues are for **defect reports only** (broken sync, validation failures, incorrect docs, runtime errors).

- Do **not** use Issues for feature requests, RFCs, or contribution proposals.
- There is **no** community contribution flow via Issues or pull requests.
- Security vulnerabilities: follow [SECURITY.md](../SECURITY.md) — **not** public Issues.

## No upstream pull requests

Anyone may **clone** or **fork** and customize a local or forked copy. **Do not** open pull requests expecting review or merge into this repository.

Internal development (collaborators with write access) uses the maintainer Git flow described in [CONTRIBUTING.md](../CONTRIBUTING.md).

## CI and release policy

Feature and fix PRs target `develop`. `.github/workflows/validate-toolkit.yml` emits the full validation suite plus aggregate checks `validate` and `ci-ok`. As checked on 2026-10-29, the active `protect-develop` ruleset requires `validate`, while legacy branch protection also requires `ci-ok`. Release PRs target `master` or `main`; `master-release-ci.yml` emits `ci-ok` for branch direction and `enforce-release-source.yml` emits `release-source` for source, release metadata, and release-sync App readiness. The active `protect-release` ruleset requires `release-source`.

The normal release starts when an opted-in `develop` → `master`/`main` PR merges. `release.yml` creates the tag/release and assets, then requests a normal reconciliation PR to `develop`. Use `reconcile_only=true` to retry reconciliation without creating another tag. See [VALIDATION.md](VALIDATION.md) for operational recovery details. Check GitHub rulesets and branch protection before each release; repository files do not control that remote configuration.

## Related

- [README.md](../README.md) — product entry
- [CONTRIBUTING.md](../CONTRIBUTING.md) — full contribution / non-contribution policy
- [SECURITY.md](../SECURITY.md) — security reporting
