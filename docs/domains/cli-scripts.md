# Domain: CLI scripts

Operator entry points under `scripts/`.

## Scripts

| Script | Role |
|--------|------|
| `scripts/toolkit.ps1` | Interactive Smart Manager (wizards + Help) or `-Action` / `-Agent` orchestrator |
| `scripts/sync-agent.ps1` | Load registry module; run `Publish-*` (+ `Get-SddRoot -Prepare` when `sdd=true`) |
| `scripts/validate-agent.ps1` | Always `validate-core`, then adapter `Invoke-SmokeValidate` |
| `scripts/validation/validate-core.ps1` | Core contract suite (alias `validate-all.ps1`) |
| `scripts/validation/Invoke-*CiSmoke.ps1` | CI-parity smoke harnesses |

Shared helpers: `scripts/_lib/` (`Resolve-InstallRoot`, `Resolve-RegistryAgent`, toolkit constants, …).

## toolkit.ps1

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action ListAgents
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Validate -Agent cursor
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent cursor -WhatIf
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Uninstall -Agent claude -WhatIf
```

Interactive menu: Sync / Validate / Sync+Validate / Validate core / Validation lab / Uninstall / Help. Sync / Validate / Uninstall **require** an agent id (wizard or `-Agent`). Backup is non-interactive stub only (`-Action Backup`). `-WhatIf` forwards to `sync-agent.ps1` for Sync / SyncAndValidate, and to adapter `Uninstall-Toolkit` when that command declares `-WhatIf`.

## sync-agent.ps1

```powershell
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent <id> [-InstallRoot <path>] [-Mode user|repo] [-AllowUserHome] [-WhatIf]
```

| Parameter | Behavior |
|-----------|----------|
| `-Agent` | Required registry id |
| `-InstallRoot` | Target root; default = in-repo fixture |
| `-Mode` | Required for `copilot` (`user` \| `repo`) |
| `-AllowUserHome` | Opt-in for USERPROFILE paths |
| `-WhatIf` | Forwarded to Publish-* |

Order (typical): Publish-Skills → Policy → Router → Hooks; then SDD prepare when capable.

## validate-agent.ps1

```powershell
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent <id> [-InstallRoot <path>] [-Mode user|repo] [-AllowUserHome]
```

1. Runs core validation.
2. Runs adapter smoke against InstallRoot (documented no-op only when smoke is not applicable — missing `-Agent` still fails).

## Examples

```powershell
# Fixture sync (safe)
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent cursor
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent cursor

# Live Cursor
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent cursor -InstallRoot "$env:USERPROFILE\.cursor" -AllowUserHome

# Copilot both modes (fixtures)
$u = Join-Path $PWD 'scripts\validation\fixtures\copilot\user'
$r = Join-Path $PWD 'scripts\validation\fixtures\copilot\repo'
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent copilot -Mode user -InstallRoot $u
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent copilot -Mode repo -InstallRoot $r
```

## Related

- [INSTALL.md](../INSTALL.md)
- [VALIDATION.md](../VALIDATION.md)
- [domains/validation-ci.md](validation-ci.md)
- [ADAPTERS.md](../ADAPTERS.md)
