# Repository governance

Public OSS policy for **agent-dev-toolkit**: who the docs are for, what visitors may do, and where policy lives.

**Summary:** clone and fork freely · **no upstream community PRs** · GitHub Issues = **bugs only** · security via [SECURITY.md](../SECURITY.md).

## Audiences

| Audience | Intent | Start here |
|----------|--------|------------|
| **Visitor** | Understand the toolkit, clone/fork, read policy | [README.md](../README.md), [INSTALL.md](INSTALL.md), [guides/01-getting-started.md](guides/01-getting-started.md), [CONTRIBUTING.md](../CONTRIBUTING.md) |
| **Operator** | Sync skills to an agent home, run validation | [INSTALL.md](INSTALL.md), [VALIDATION.md](VALIDATION.md), [ADAPTERS.md](ADAPTERS.md), [SKILLS.md](SKILLS.md) |
| **Maintainer** | Change this repository (write access / collaborators) | [CONTRIBUTING.md](../CONTRIBUTING.md) (Maintainers only), [VALIDATION.md](VALIDATION.md), `.github/workflows/` |

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

## Related

- [README.md](../README.md) — product entry
- [CONTRIBUTING.md](../CONTRIBUTING.md) — full contribution / non-contribution policy
- [SECURITY.md](../SECURITY.md) — security reporting
