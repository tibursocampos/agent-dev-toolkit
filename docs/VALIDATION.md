# Validation and local CI

How to run the in-repo test suite and agent smokes. **None of these steps require writing to a live agent home.**

## Audiences

| Audience | What this doc is for | What to run |
|----------|----------------------|-------------|
| **Visitor** | Understanding that tests exist; **not** expected to run the suite | None — clone/fork and read [REPO_GOVERNANCE.md](REPO_GOVERNANCE.md) / [CONTRIBUTING.md](../CONTRIBUTING.md) |
| **Operator** | Syncing skills to an agent home and checking a fixture install | Optional: [Core suite](#core-suite) (`validate-core`); [Per-agent validate](#per-agent-validate) against a fixture `InstallRoot` — **never** `-AllowUserHome` to “make CI pass” |
| **Maintainer** | Changing this repository (write access / CI owners) | **Required locally before merge:** `validate-core.ps1` (or `validate-all.ps1`) plus the relevant docs build. **Parity with Actions:** [What CI runs](#what-ci-runs) / [Local parity](#local-parity) (same scripts as [`.github/workflows/validate-toolkit.yml`](../.github/workflows/validate-toolkit.yml)). Full merge gate = core/security checks + keyed uninstall asserts + `Assert-SyncAllowUserHomeForward` + 10 agent CI smokes (Copilot is a suite) + strict MkDocs build |

**Maintainers vs visitors:** Visitors do not need PowerShell validation. Maintainers own the green bar — run **validate-core** on every change that touches contracts, skills, router, or validation scripts; run the relevant **CI smoke** when an adapter or publish path changes. Operators may run the same scripts against fixtures; that does not grant upstream PR rights ([CONTRIBUTING.md](../CONTRIBUTING.md)).

Policy context: [REPO_GOVERNANCE.md](REPO_GOVERNANCE.md).

## Core suite

Validates contracts, skill graph, fixtures, and the smoke harness wiring — **no** `%USERPROFILE%` deploy:

```powershell
pwsh -NoProfile -File .\scripts\validation\validate-core.ps1

# Alias:
pwsh -NoProfile -File .\scripts\validation\validate-all.ps1
```

Quiet mode (CI):

```powershell
pwsh -NoProfile -File .\scripts\validation\validate-core.ps1 -Quiet
```

Smoke harness alone (fixture `InstallRoot` under the repo):

```powershell
pwsh -NoProfile -File .\scripts\validation\Invoke-SmokeHarness.ps1
```

`validate-core` wires structural PRD / PLAN / CHANGE validation and focused toolkit contract checks. It does not run acceptance fixtures for individual US/FEATURE artifacts. These are scripts, not LLM validators, and do not introduce a second toolkit CLI or SQLite/FTS.

These prove contracts and scripts exist. They are not a substitute for running inventory, preflight, or harvest on a consumer feature. Operator entry points stay in the table below.

## Reliability evidence boundaries

The suite verifies published runtime-helper paths, repository and PLAN session identity protection, local-instruction discovery, and configured diagnostic evidence with static fixtures. Development and review evidence uses distinct `PASS`, `FOUND`, and `SKIPPED` states: `SKIPPED` records an unavailable or unrun check and is never approval. A configured command may be exercised by a fixture; that does not prove a live Copilot, IDE, host runtime, Markdownlint, dependency audit, or analyzer run. Record those unavailable surfaces as `SKIPPED` with their reason and scope.

Planning checks also cover outcome-based story sizing and observable API-contract readiness before a PLAN is written. O3 may begin with a full contract review and use later delta/risk reviews when the relevant scope has not changed; unavailable token or tool telemetry remains `SKIPPED`, not an acceptance failure.

| Assert / script | Role |
|-----------------|------|
| `Assert-MemoryBankInventory.ps1` | Inventory script + `ready` / `not-ready` contract smoke (portable paths in `sources.json`) |
| `Assert-DevelopSessionGate.ps1` / `validate-session-gates.ps1` | Idempotent develop `step_confirmed` helper + skill MUST `-File` (WS10) |
| `Assert-InvocationAxes.ps1` | Spawn Axis B omit/inherit prose + harness wiring (WS1) |
| `Assert-PublishSpawnKnobs.ps1` | Publish honesty depth/threads/inherit (no child≠parent pin) |
| `Assert-TraceEmitterFailOpen.ps1` | Fail-open emitter + `TraceEmitCommon` parity |
| `validate-trace.ps1` | Per-feature TRACE validate (`-RequireArchiveComplete` at wave close) |
| `Invoke-PrdPlanChangePreflight.ps1` | PRD/PLAN/CHANGE consistency before O3 |

## Operator scripts (pointers)

Run against a **consumer** feature / bank when closing a wave or before O3 — not required for visitor CI green. Contracts live under `core/skills/_shared/sdd-artifacts/`; do not duplicate schemas here.

| Script | When | Domain detail |
|--------|------|---------------|
| `scripts/inventory/Invoke-MemoryBankInventory.ps1` | Refresh `memory-bank/.inventory/` (`ready` \| `not-ready`; **portable** paths only) | [cli-scripts](domains/cli-scripts.md#memory-bank-inventory) |
| `scripts/validation/Invoke-PrdPlanChangePreflight.ps1` | Before O3 — PRD/PLAN/CHANGE consistency | [cli-scripts](domains/cli-scripts.md#prd--plan--change-preflight) |
| `scripts/session/Invoke-DevelopSessionGate.ps1` | After **sim** — idempotent develop `step_confirmed` (MUST `-File` with claim) | [cli-scripts](domains/cli-scripts.md#shell-allowlist-tip-ws10--req-013) · [core session gate](domains/core.md#plan-ledger--develop-session-gate) |
| `scripts/ledger/Invoke-PlanLedgerClaim.ps1` | O3 parallel step claim / release | [core PLAN-LEDGER](domains/core.md#plan-ledger--develop-session-gate) |
| `scripts/validation/Invoke-SiblingReadinessGate.ps1` | Selective clarify READY / NEEDS_CLARIFICATION check | [core readiness](domains/core.md#clarification-readiness-b--i--minor) |
| `scripts/trace/Invoke-TraceHarvest.ps1` | Summarize `features/NNN-slug/TRACE.jsonl` only | [cli-scripts](domains/cli-scripts.md#trace-harvest) |
| `scripts/validation/validate-trace.ps1` | Structural TRACE check; `-RequireArchiveComplete` at archive | [core TRACE](domains/core.md#trace-archive-living-loop) |

Suggested order: **inventory → preflight → develop (session gate + claim) → TRACE harvest**. Emitter honesty (which hosts actually wire TRACE): [adapters.md](domains/adapters.md#trace-emitter-honesty).

`Assert-HermesSpawnIsolation.ps1` (check name `hermes-spawn-isolation`) keeps Hermes `delegate_task` out of core policy/router/skills (SPAWN host-map allowlist only) and proves the Hermes AGENTS spawn bridge does not leak into other adapters’ published `AGENTS.md` / rules.

## Per-agent validate

Runs `validate-core`, then the adapter’s `Invoke-SmokeValidate` against a fixture InstallRoot (default from the registry / adapter):

```powershell
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent cursor
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent claude
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent copilot -Mode user
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent copilot -Mode repo
```

## CI smoke harnesses

These mirror [`.github/workflows/validate-toolkit.yml`](../.github/workflows/validate-toolkit.yml). Prefer them locally when you want the same ephemeral-copy behavior as Actions.

| Script | What it covers |
|--------|----------------|
| `Invoke-CursorCiSmoke.ps1` | Cursor sync+validate on ephemeral copy of Cursor fixture |
| `Invoke-AntigravityCiSmoke.ps1` | Antigravity sync+validate on ephemeral Antigravity fixture |
| `Invoke-ClaudeCiSmoke.ps1` | Claude sync+validate on ephemeral Claude fixture |
| `Invoke-CodexCiSmoke.ps1` | Codex sync+validate on ephemeral Codex fixture |
| `Invoke-CopilotCiSmokeSuite.ps1` | Copilot Mode `user` + Mode `repo` + home guard |
| `Invoke-OpenCodeCiSmoke.ps1` | OpenCode filesystem sync+validate on ephemeral fixture (**not** product runtime) |
| `Invoke-GrokCiSmoke.ps1` | Grok sync+validate on ephemeral Grok fixture |
| `Invoke-ZCodeCiSmoke.ps1` | ZCode ADE fixture InstallRoot |
| `Invoke-HermesCiSmoke.ps1` | Hermes sync+validate on ephemeral Hermes fixture (models `~/.hermes`) |
| `Invoke-OpenHandsCiSmoke.ps1` | OpenHands filesystem sync+validate on ephemeral project fixture |

```powershell
pwsh -NoProfile -File .\scripts\validation\Invoke-CursorCiSmoke.ps1
pwsh -NoProfile -File .\scripts\validation\Invoke-AntigravityCiSmoke.ps1
pwsh -NoProfile -File .\scripts\validation\Invoke-ClaudeCiSmoke.ps1
pwsh -NoProfile -File .\scripts\validation\Invoke-CodexCiSmoke.ps1
pwsh -NoProfile -File .\scripts\validation\Invoke-CopilotCiSmokeSuite.ps1
pwsh -NoProfile -File .\scripts\validation\Invoke-OpenCodeCiSmoke.ps1
pwsh -NoProfile -File .\scripts\validation\Invoke-GrokCiSmoke.ps1
pwsh -NoProfile -File .\scripts\validation\Invoke-ZCodeCiSmoke.ps1
pwsh -NoProfile -File .\scripts\validation\Invoke-HermesCiSmoke.ps1
pwsh -NoProfile -File .\scripts\validation\Invoke-OpenHandsCiSmoke.ps1
```

### Manual fixture sync (same idea)

```powershell
$cursorFixture = Join-Path $PWD 'scripts\validation\fixtures\cursor-install-root'
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent cursor -InstallRoot $cursorFixture
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent cursor -InstallRoot $cursorFixture

$claudeFixture = Join-Path $PWD 'scripts\validation\fixtures\claude'
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent claude -InstallRoot $claudeFixture
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent claude -InstallRoot $claudeFixture

$copilotUser = Join-Path $PWD 'scripts\validation\fixtures\copilot\user'
$copilotRepo = Join-Path $PWD 'scripts\validation\fixtures\copilot\repo'
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent copilot -Mode user -InstallRoot $copilotUser
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent copilot -Mode user -InstallRoot $copilotUser
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent copilot -Mode repo -InstallRoot $copilotRepo
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent copilot -Mode repo -InstallRoot $copilotRepo
```

Other fixture roots: `fixtures/codex` (Codex plugin layout), `fixtures/opencode` (OpenCode config root), `fixtures/grok` (Grok Build), `fixtures/zcode-install-root` (ZCode ADE), `fixtures/antigravity-install-root`, `fixtures/hermes` (`~/.hermes` model), `fixtures/openhands` (OpenHands project tree), `fixtures/install-root` (generic smoke harness). `fixtures/claude` includes the merge seed `settings.json`.

CI harnesses often copy a fixture to an ephemeral work root so the versioned seed stays intact. Local sync residue under fixture InstallRoots (published skill trees, SDD sessions, merge `.bak` files) is listed in the root `.gitignore`. Keep that residue locally for faster re-tests. Do not commit it.

## What CI runs

Workflow: [`.github/workflows/validate-toolkit.yml`](../.github/workflows/validate-toolkit.yml). Trigger: `pull_request` to `develop` only (no `push`, and no pull request into `master` or `main`). Permissions: `contents: read`. Checkout only; no secrets; no home sync for green. The wide suite `validate-core.ps1` and the keyed-uninstall matrix are not jobs on this path.

**Jobs (all must be green before merge into `develop`):**

| Job | Runner | Role |
|-----|--------|------|
| `validate` | `windows-latest` | Named remaining checks plus `Assert-SyncAllowUserHomeForward` |
| `validate-windows-adapter-smoke` | `windows-latest` matrix | 10 adapter CI smokes, after `validate` |
| `validate-ubuntu` | `ubuntu-latest` | The same named remaining checks |
| `validate-ubuntu-adapter-smoke` | `ubuntu-latest` matrix | 10 adapter CI smokes, after `validate-ubuntu` |
| `docs-strict` | `ubuntu-latest` | Strict MkDocs build; required by `ci-ok` |
| `ci-ok` | `ubuntu-latest` | Required gate with `needs` on the five jobs above |

### Job `validate` (Windows base)

Named remaining checks, each in its own process:

1. `Assert-CiWorkflow.ps1`
2. `Assert-GuardShellCanonicalPaths.ps1`
3. `Assert-TraceEmitterFailOpen.ps1`
4. `Assert-SyncAllowUserHomeForward.ps1` (disposable USERPROFILE probe; not a live-home sync for green)

The adapter-smoke matrices are separate jobs. Each uses `fail-fast: false`, `max-parallel: 4`, and the same ten adapters. Adapter smoke runs `Invoke-*-CiSmoke.ps1 -Quiet` (Copilot is a suite).

`validate-ubuntu` runs the same three named remaining checks and does not run `Assert-SyncAllowUserHomeForward`. `validate-ubuntu-adapter-smoke` is a separate ten-entry matrix that depends on `validate-ubuntu`.

`docs-strict` is the single strict MkDocs build for pull requests into `develop` and is an explicit `ci-ok` dependency. The Pages workflow is intentionally not triggered by pull requests, so the same change does not build documentation twice. Documentation failures still block merge into `develop` through `ci-ok`.

`ci-ok` depends on `validate`, `validate-windows-adapter-smoke`, `validate-ubuntu`, `validate-ubuntu-adapter-smoke`, and `docs-strict`. Do **not** merge into `develop` with any required job red. Auto-merge must wait for `ci-ok`.

### Other workflows

`enforce-release-source.yml` runs on release PRs into `master`/`main`. It requires `develop` as the head and validates `Create release: yes/no`, the version, and (when opted in) non-empty bullet-only `Highlights`; a requested version must be strict SemVer, unused, and greater than the latest release tag. After a release PR is merged, `release.yml` publishes only when the PR opted in. It targets the promoted commit on `master`/`main`, serializes release jobs, and rechecks the requested version against tags after entering the queue to reject duplicate or stale versions. Release notes use the approved highlights and list only PRs associated with commits in the actual previous-tag-to-promoted-commit range; an empty range is explicitly stated instead of leaving `Included work` blank. `publish-release-bootstrap.yml` is called as a reusable workflow by `release.yml`, so assets publish in the same run despite GitHub's `GITHUB_TOKEN` downstream-event restriction; it also supports `release: published` and manual recovery dispatch.

After every merged release PR, whether or not it opted into a version, `release.yml` prepares a reconciliation branch and opens a PR into `develop`. When promoted and develop trees match, it records ancestry with an `ours` merge. When trees differ, it performs a real merge so promoted content is preserved; conflicts stop the job for maintainer resolution. It does not push directly to protected `develop` or grant Actions a branch-rule bypass. Install a repository GitHub App with **Contents: read/write** and **Pull requests: read/write**, install it only on this repository, and add its app ID and private key as Actions secrets `RELEASE_SYNC_APP_ID` and `RELEASE_SYNC_APP_PRIVATE_KEY`. Do not grant the app ruleset/branch-protection bypass. The app token opens the sync PR so the normal `develop` checks can run, then requests GitHub auto-merge using the repository merge strategy and normal branch rules. The job fails clearly if auto-merge cannot be enabled or is not queued. No bypass is granted. This restores ancestry and prevents the same divergence from accumulating. If the app is unavailable, reconciliation stops and a maintainer can manually open an equivalent merge PR from `master`/`main` into `develop`.

If release creation succeeds but asset publication fails, do not create another version or rerun `release.yml`. Retry only `.github/workflows/publish-release-bootstrap.yml` with `workflow_dispatch` on `master`/`main`, using the existing `vVERSION` tag. The upload uses `--clobber`, so it replaces any partial assets for that same release.

The release workflow's concurrency group serializes runs, and each release job checks the remote tag and latest SemVer after it starts. GitHub keeps at most one pending run per concurrency group; if several release PRs merge while a run is active, a newer pending run can replace an older pending run. Avoid merging multiple release PRs in quick succession. Check Actions after each merge; if a run was replaced/canceled, recover on `master`/`main` with `workflow_dispatch`, a new unused version, and create/merge a reconciliation PR if the run did not create one. If two merged PRs request the same version, only the first can create it; the later job fails without replacing the release. Choose a new unused version for recovery. If a tag exists but no GitHub Release exists, inspect the tag and run history before taking action; do not delete or move a tag automatically. If the GitHub Release exists, use the asset-only retry above. A release event whose version became stale while queued can be recovered with `workflow_dispatch` on `master`/`main` and a new version greater than the latest published SemVer tag.

`.github/workflows/docs.yml` builds the public MkDocs site on pushes to `master`/`main`/`develop` and manual dispatch; it is not run on pull requests because `validate-toolkit.yml` owns the required PR build. Only pushes to `master`/`main` deploy Pages.

### CI tiers

| Tier | Trigger | Coverage and gate policy |
|------|---------|--------------------------|
| PR into `develop` | `pull_request` to `develop` | Named remaining checks, adapter-smoke matrices, `Assert-SyncAllowUserHomeForward` on Windows, and `docs-strict`; `ci-ok` is the required merge check. |
| Release PR | `pull_request` to `master` or `main` | `enforce-release-source.yml`: head must be `develop`; opt-in and SemVer metadata must validate. |
| Release publish | Merged opt-in release PR; or manual recovery dispatch | `release.yml` tags the promoted commit and calls `publish-release-bootstrap.yml` to package and upload fixed assets. |
| Branch reconciliation | After every merged release PR | `release.yml` opens a normal merge PR into develop using the scoped repository App token; required checks run before the PR is merged. |

### Local parity

Mirrors the workflow topology: run the Windows named checks, then the adapter-smoke matrix; separately run the Ubuntu named checks, then its adapter-smoke matrix; run the strict MkDocs build. `ci-ok` covers those five jobs.

`validate-core.ps1` remains the local wide suite. It is not a default CI job. The adapter smoke matrices stay on both runners. Windows-only `Assert-SyncAllowUserHomeForward` stays on the `validate` job.

```powershell
pwsh -NoProfile -File .\scripts\validation\validate-core.ps1 -Quiet

pwsh -NoProfile -File .\scripts\validation\Assert-ClaudeKeyedUninstall.ps1
pwsh -NoProfile -File .\scripts\validation\Assert-CopilotKeyedUninstall.ps1
pwsh -NoProfile -File .\scripts\validation\Assert-CodexKeyedUninstall.ps1
pwsh -NoProfile -File .\scripts\validation\Assert-OpenCodeKeyedUninstall.ps1
pwsh -NoProfile -File .\scripts\validation\Assert-AntigravityKeyedUninstall.ps1
pwsh -NoProfile -File .\scripts\validation\Assert-GrokKeyedUninstall.ps1
pwsh -NoProfile -File .\scripts\validation\Assert-CursorKeyedUninstall.ps1
pwsh -NoProfile -File .\scripts\validation\Assert-ZcodeKeyedUninstall.ps1
pwsh -NoProfile -File .\scripts\validation\Assert-HermesKeyedUninstall.ps1
pwsh -NoProfile -File .\scripts\validation\Assert-OpenHandsKeyedUninstall.ps1

pwsh -NoProfile -File .\scripts\validation\Assert-SyncAllowUserHomeForward.ps1

python -m pip install -r docs-site/requirements-docs.txt
mkdocs build --strict -f docs-site/mkdocs.yml

pwsh -NoProfile -File .\scripts\validation\Invoke-CursorCiSmoke.ps1 -Quiet
pwsh -NoProfile -File .\scripts\validation\Invoke-AntigravityCiSmoke.ps1 -Quiet
pwsh -NoProfile -File .\scripts\validation\Invoke-ClaudeCiSmoke.ps1 -Quiet
pwsh -NoProfile -File .\scripts\validation\Invoke-CodexCiSmoke.ps1 -Quiet
pwsh -NoProfile -File .\scripts\validation\Invoke-CopilotCiSmokeSuite.ps1 -Quiet
pwsh -NoProfile -File .\scripts\validation\Invoke-OpenCodeCiSmoke.ps1 -Quiet
pwsh -NoProfile -File .\scripts\validation\Invoke-GrokCiSmoke.ps1 -Quiet
pwsh -NoProfile -File .\scripts\validation\Invoke-ZCodeCiSmoke.ps1 -Quiet
pwsh -NoProfile -File .\scripts\validation\Invoke-HermesCiSmoke.ps1 -Quiet
pwsh -NoProfile -File .\scripts\validation\Invoke-OpenHandsCiSmoke.ps1 -Quiet
```

## Safety rules

| Rule | Detail |
|------|--------|
| No live home for green | Do not use `-AllowUserHome` to “make CI pass” |
| Trust UIs out of scope | Cursor / Claude / Codex / Grok hook trust dialogs are never required for smoke green |
| JetBrains / Eclipse Copilot | Out of scope — Mode user/repo official surfaces only |
| GLM Coding Plan | Endpoint-only; not ZCode ADE |
| Hermes gateway | `SOUL.md` and `config.yaml` secrets are out of smoke scope |
| OpenHands product runtime | Automation Server, sandbox YAML, and legacy microagents are out of smoke scope |

Live homes such as `~/.cursor`, `~/.claude`, `~/.copilot`, `~/.hermes`, and `~/.agents` are out of smoke scope.

## Related

- Adapter publish details: [ADAPTERS.md](ADAPTERS.md)
- Install / live home: [INSTALL.md](INSTALL.md)
- CLI scripts: [domains/cli-scripts.md](domains/cli-scripts.md)
