# ZCode InstallRoot fixture (in-repo)

Empty seed used by ZCode ADE adapter publish/smoke tests as a safe
`InstallRoot` (layout equivalent to `~/.zcode`).

Paths resolve under the toolkit repo — never under `%USERPROFILE%` unless
`-AllowUserHome` is set explicitly.

Do not sync this tree to a live ZCode ADE home. CI and local smokes must use this
fixture (or another path under the repo root).

```powershell
$fixture = Join-Path $PWD 'scripts\validation\fixtures\zcode-install-root'
.\scripts\sync-agent.ps1 -Agent zcode -InstallRoot $fixture
.\scripts\validate-agent.ps1 -Agent zcode -InstallRoot $fixture
```

Published artifacts (skills, AGENTS.md, hooks/config, …) may appear here during
tests and are safe to delete between runs.

GLM Coding Plan (endpoint/Base URL/MCP only) is not this adapter surface.
