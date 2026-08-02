# Maintainers

Operator and collaborator notes for keeping **agent-dev-toolkit** green. Public clone/fork is welcome; upstream community PRs are out of scope.

## Policy (short)

| Rule | Detail |
|------|--------|
| Clone / fork | Anyone may clone or fork and customize locally |
| Upstream PRs | Not accepted from the community |
| Issues | Bugs only (no feature/RFC channel) |
| Security | Report via `SECURITY.md`, not public Issues |

Deep dives on GitHub:

- [CONTRIBUTING.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/CONTRIBUTING.md)
- [docs/REPO_GOVERNANCE.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/REPO_GOVERNANCE.md)
- [SECURITY.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/SECURITY.md)
- [docs/ARCHITECTURE.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/ARCHITECTURE.md) — full layout; site overview: [Architecture](../architecture/)

## Validation (local)

None of these steps write to a live install path. Prefer fixture `InstallRoot` paths; never use `-AllowUserHome` to “make CI pass.”

**Core suite** (contracts, skill graph, fixtures — required before merge for maintainers):

```powershell
pwsh -NoProfile -File .\scripts\validation\validate-core.ps1

# Alias:
pwsh -NoProfile -File .\scripts\validation\validate-all.ps1

# Quiet (CI-style):
pwsh -NoProfile -File .\scripts\validation\validate-core.ps1 -Quiet
```

**Per-agent validate** (`validate-core` + adapter smoke against fixture):

```powershell
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent cursor
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent claude
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent copilot -Mode user
```

**CI smoke harnesses** (mirror Actions ephemeral-copy behavior):

```powershell
pwsh -NoProfile -File .\scripts\validation\Invoke-CursorCiSmoke.ps1
pwsh -NoProfile -File .\scripts\validation\Invoke-AntigravityCiSmoke.ps1
pwsh -NoProfile -File .\scripts\validation\Invoke-ClaudeCiSmoke.ps1
pwsh -NoProfile -File .\scripts\validation\Invoke-CodexCiSmoke.ps1
pwsh -NoProfile -File .\scripts\validation\Invoke-CopilotCiSmokeSuite.ps1
pwsh -NoProfile -File .\scripts\validation\Invoke-OpenCodeCiSmoke.ps1
pwsh -NoProfile -File .\scripts\validation\Invoke-GrokCiSmoke.ps1
pwsh -NoProfile -File .\scripts\validation\Invoke-ZCodeCiSmoke.ps1
```

Full matrix, safety rules, and CI workflows:

- [docs/VALIDATION.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/VALIDATION.md)
- [validate-toolkit.yml](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/.github/workflows/validate-toolkit.yml) — required **validate** check
- [docs.yml](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/.github/workflows/docs.yml) — MkDocs build / Pages deploy

## Maintainer Git flow

Collaborators with write access use normal branches: `feature/<slug>` → `develop` → `master`/`main`. Prefer `/open-github-pr` after `/commit` / `/push` (feature → `develop`; release mode `develop` → `master`/`main`). Release PRs use the template at `.github/PULL_REQUEST_TEMPLATE/release.md`. Required CI check: **validate**. See [Maintainers only (repository owner)](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/CONTRIBUTING.md#maintainers-only-repository-owner) in CONTRIBUTING.md.
