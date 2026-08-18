# Hermes InstallRoot fixture (in-repo)

Seed directory used by Hermes sync/smoke as a safe `InstallRoot`.
Models live **`~/.hermes`** — skills and `AGENTS.md` are **direct children**
of this folder. Paths resolve under the toolkit repo — never under
`%USERPROFILE%` unless `-AllowUserHome` is set explicitly.

## Layout (skeleton)

```
hermes/               # InstallRoot (= live ~/.hermes)
├── skills/           # mirrors ~/.hermes/skills (empty until first publish)
├── AGENTS.md         # placeholder until Publish-Policy / Publish-Router
└── sdd/              # prepared by Get-SddRoot -Prepare
```

Do **not** add a `rules/` tree or hooks JSON. Hermes folds policy into
`AGENTS.md`. Do not nest another `.hermes/` under this fixture.

CI and local smokes must use this fixture (or another path under the repo
root). `MEMORY.md` is seeded on publish only when missing.
