# Known risks

| Risk | Area | Mitigation / evidence |
|------|------|----------------------|
| Live-home behavior is not covered by fixture-only CI | Install / adapters | Default destinations are in-repository fixtures; real profile writes require `-AllowUserHome`. Treat fixture smokes as local contract evidence, not live-host proof. |
| Release sync App was missing from the repository (resolved 2026-10-31) | Release | The preflight failed with 404 until the App was installed on the repository. The workflow `reconcile_only` run on 2026-10-31 passed preflight and opened the reconciliation PR. Keep the App installed with contents and pull-request write permissions. |
| Current local CI changes have not been verified by a GitHub PR run | CI | `validate-core.ps1` and the strict docs build passed locally, but the workflow runs on PRs to `develop`; a pushed branch without a PR has no remote check evidence. Confirm `validate` and `ci-ok` on the final PR SHA. |
| Release reconciliation can be superseded when multiple runs are pending | Release | GitHub concurrency permits only one pending run per group. Reconciliation of the latest promoted `master`/`main` commit includes its ancestors; avoid queuing overlapping release runs and verify the final ancestry. |
| External-access fixtures do not prove production provider/host enforcement | SDD | Feature 020 remains `IN_PROGRESS`; production I/O, provider enforcement, isolation/TOCTOU, and true Windows case-sensitive-directory behavior remain deferred or unverified. Keep claims scoped to contract and fixture evidence. |
| Registry capability and runtime capability can differ | Spawn / adapters | Use the effective Antigravity probe (`ADT_ANTIGRAVITY_SUBAGENTS`, then product version); treat missing/unknown `subagents` as `none`. |
| Toolkit menu must isolate CLI scripts that use top-level `exit` | CLI / validation | `scripts/toolkit.ps1` now runs dispatched scripts through `scripts/_lib/Invoke-ToolkitChildScript.ps1`; `Assert-ToolkitScriptIsolation.ps1` covers success/failure codes and argument quoting. Keep new menu dispatches on this boundary. |
| Repository rulesets are external configuration | Git / CI | `protect-develop` allows squash and merge only and requires `validate`; `protect-release` allows merge only and requires `release-source`. Both have no bypass actors. Local validation does not change GitHub rules; they were changed on 2026-10-31. |

## Fragile areas

- `adapters/registry.json` declarations versus effective host capability probes.
- `core/skills/_shared/agents/LANGUAGE.md` versus published pt-BR defaults.
- `InstallRoot` resolution and its `-AllowUserHome`, Copilot `-Mode user|repo`, and optional Codex `-UserScope` gates.
- GitHub Actions release preflight, required-check names, App permissions, and ancestry reconciliation.
- Skill catalog mirrors; exact ID parity is checked by `scripts/validation/Assert-SkillCatalogParity.ps1`.

## Operational notes

- `-Action Backup` is fail-closed unless the explicit stub override is used; it does not snapshot an install.
- Uninstall removes toolkit-owned files but preserves alien files and `sdd/sessions`; sync is update-in-place.
- `verify_mode` defaults to false; read-only verification after implementation runs only when enabled.
- Use environment variable names only in docs and this bank. Never copy tokens, private keys, connection strings, or raw `.env` data.

Update this file when new incidents or reviews change the evidence. Unknown external behavior belongs in `.inventory/gaps.md`.
