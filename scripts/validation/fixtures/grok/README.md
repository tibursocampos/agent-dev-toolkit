# Grok InstallRoot fixture (in-repo)

Seed directory used by Grok sync/smoke as a safe `InstallRoot`.
Models live **`~/.grok`** — skills, rules, and hooks are **direct children**
of this folder (Claude-style). Paths resolve under the toolkit repo — never
under `%USERPROFILE%` unless `-AllowUserHome` is set explicitly.

## Layout (skeleton)

```
grok/                 # InstallRoot (= live ~/.grok)
├── skills/           # mirrors ~/.grok/skills
├── rules/            # project rules (*.md) from core/policy
├── hooks/            # native Grok hooks JSON (trust UI out of smoke)
├── AGENTS.md         # written by Publish-Router
└── sdd/              # prepared by Get-SddRoot -Prepare
```

Do not nest another `.grok/` under this fixture (that produced the live bug
`~/.grok/.grok/skills`). CI and local smokes must use this fixture (or another
path under the repo root).
