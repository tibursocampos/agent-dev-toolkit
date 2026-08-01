# Antigravity InstallRoot fixture (in-repo)

Seed directory used by Antigravity adapter publish/smoke as a safe
`InstallRoot` modeling the official Gemini user root (`~/.gemini`).

**Path (repo-relative):** `scripts/validation/fixtures/antigravity-install-root/`

Paths resolve under the toolkit repo — never under `%USERPROFILE%` unless
`-AllowUserHome` is set explicitly.

## Layout (official seed)

```
antigravity-install-root/          # models ~/.gemini
└── config/
    ├── skills/                    # kebab Agent Skills (+ dev_persona after sync)
    ├── plugins/                   # GUARDRAILS under managed plugin id after sync
    ├── hooks/                     # present; Publish-Hooks is no-op (hooks=false)
    ├── skills.json                # upserted by Publish-Skills
    ├── AGENTS.md                  # managed block by Publish-Router
    └── GEMINI.md                  # managed block by Publish-Router
```

Legacy bridge `antigravity-ide/plugins` is **not** part of this fixture (non-default /
not a CI gate).

Do not sync this tree to a live Antigravity/Gemini home. CI and local smokes must
use this fixture (or another path under the repo root). Live KI / trust UI are out of
scope for Antigravity smoke.

## Operator commands

```powershell
$antigravityFixture = Join-Path $PWD 'scripts\validation\fixtures\antigravity-install-root'
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent antigravity -InstallRoot $antigravityFixture
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent antigravity -InstallRoot $antigravityFixture
pwsh -NoProfile -File .\scripts\validation\Assert-AntigravityOfficialLayout.ps1
pwsh -NoProfile -File .\scripts\validation\Assert-AntigravityKeyedUninstall.ps1
```
