# Grok InstallRoot fixture (in-repo)

Seed directory used by Grok sync/smoke as a safe `InstallRoot`.
Paths resolve under the toolkit repo — never under `%USERPROFILE%` unless
`-AllowUserHome` is set explicitly.

## Layout (skeleton)

```
grok/
└── .grok/
    ├── skills/   # mirrors ~/.grok/skills and project .grok/skills
    ├── rules/    # project rules (*.md) from core/policy
    └── hooks/    # native Grok hooks JSON (trust UI out of smoke)
```

`AGENTS.md` at the fixture root is written by Publish-Router in a later step.

Do not sync this tree to a live Grok home. CI and local smokes must use this
fixture (or another path under the repo root).
