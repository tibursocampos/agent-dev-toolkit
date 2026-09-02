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
- [docs/CREDITS.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/CREDITS.md) — third-party inspiration; site: [Credits](../credits/)

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

**Per-agent validate** (`validate-core` + adapter smoke test against fixture):

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

## Operator scripts (inventory → preflight → harvest)

Same skill call flow; these scripts add deterministic gates — not a second toolkit CLI. Suggested order on a consumer feature:

| Order | Script | Role |
|-------|--------|------|
| 1 | `scripts/inventory/Invoke-MemoryBankInventory.ps1` | `ready` \| `not-ready` under `memory-bank/.inventory/` |
| 2 | `scripts/validation/Invoke-PrdPlanChangePreflight.ps1` | Block O3 when PRD/PLAN/CHANGE inconsistent |
| 3 | Develop (`sdd-develop` / O3; optional PLAN-LEDGER claim) | Session gates + optional ledger hold |
| 4 | `scripts/trace/Invoke-TraceHarvest.ps1` | Summarize **only** `features/NNN-slug/TRACE.jsonl` |

```powershell
pwsh -NoProfile -File .\scripts\inventory\Invoke-MemoryBankInventory.ps1 `
  -RepoPath . -BankPath .\memory-bank -AllowCreateInventory

pwsh -NoProfile -File .\scripts\validation\Invoke-PrdPlanChangePreflight.ps1 `
  -FeatureRoot features\<NNN-slug> `
  -PlanPath features\<NNN-slug>\<story>\PLAN\PLAN_....md

pwsh -NoProfile -File .\scripts\trace\Invoke-TraceHarvest.ps1 `
  -FeatureRoot features\<NNN-slug>
```

PLAN-LEDGER CLI: `scripts/ledger/Invoke-PlanLedgerClaim.ps1`. Pointers only (no schema paste): [docs/VALIDATION.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/VALIDATION.md) · [docs/domains/cli-scripts.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/domains/cli-scripts.md). TRACE emitter claims: [Adapters](../adapters/).

## Maintainer Git flow

Collaborators with write access use normal branches: `feature/<slug>` → `develop` → `master`/`main`. Prefer `/open-github-pr` after `/commit` / `/push` (feature → `develop`; release mode `develop` → `master`/`main`). Release PRs use the template at `.github/PULL_REQUEST_TEMPLATE/release.md`. Required CI check: **validate**. See [Maintainers only (repository owner)](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/CONTRIBUTING.md#maintainers-only-repository-owner) in CONTRIBUTING.md.
