# Antigravity InstallRoot fixture (in-repo)

Minimal seed for Antigravity adapter publish/smoke tests. It models the official
Gemini user root (`~/.gemini`) and intentionally contains no published
`config/` snapshot; CI copies this seed before sync generates managed output.

Paths resolve under the toolkit repo — never under `%USERPROFILE%` unless
`-AllowUserHome` is set explicitly. Do not sync this tree to a live
Antigravity/Gemini home.

The keyed-uninstall check creates its own managed and user-owned state, verifies
the router block is added and removed, and confirms alien skills survive.
Live KI and trust UI remain outside CI smoke.

## Operator commands

```powershell
$antigravityFixture = Join-Path $PWD 'scripts\validation\fixtures\antigravity-install-root'
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent antigravity -InstallRoot $antigravityFixture
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent antigravity -InstallRoot $antigravityFixture
pwsh -NoProfile -File .\scripts\validation\Assert-AntigravityOfficialLayout.ps1
pwsh -NoProfile -File .\scripts\validation\Assert-AntigravityKeyedUninstall.ps1
```
