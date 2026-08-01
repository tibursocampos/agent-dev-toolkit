# Copilot InstallRoot fixtures (in-repo)

Seed directories used by Copilot sync/smoke as safe `InstallRoot` values.
Paths resolve under the toolkit repo — never under `%USERPROFILE%` unless
`-AllowUserHome` is set explicitly.

## Layout (skeleton)

```
copilot/
├── user/                 # InstallRoot for -Mode user (models ~/.copilot)
│   ├── skills/           # ~/.copilot/skills
│   ├── instructions/     # ~/.copilot/instructions
│   ├── hooks/            # ~/.copilot/hooks
│   └── (copilot-instructions.md written by later publish steps)
└── repo/                 # InstallRoot for -Mode repo (models .github)
    ├── skills/           # .github/skills
    ├── instructions/     # .github/instructions
    ├── hooks/            # .github/hooks
    └── (copilot-instructions.md written by later publish steps)
```

Official surfaces only. JetBrains / Eclipse Copilot IDE layouts are out of scope.

Do not sync these trees to a live `~/.copilot` or the toolkit working-tree
`.github`. CI and local smokes must use these fixtures (or another path under
the repo root).

## Operator / CI (single command)

Both modes (user + repo), fixture InstallRoots only — no Copilot profile:

```powershell
pwsh -NoProfile -File .\scripts\validation\Invoke-CopilotCiSmokeSuite.ps1
```

Targeted assert (matrix + home guard):

```powershell
pwsh -NoProfile -File .\scripts\validation\Assert-CopilotModes.ps1
```
