# OpenCode InstallRoot fixture (in-repo)

Seed directory used by OpenCode sync/smoke as a safe `InstallRoot`.
The fixture root models `~/.config/opencode` — paths resolve under the toolkit
repo, never under `%USERPROFILE%` / `$HOME/.config/opencode` unless
`-AllowUserHome` is set explicitly.

## Layout (skeleton)

```
opencode/                 # InstallRoot ≡ ~/.config/opencode
├── skills/               # skills/<kebab-id>/SKILL.md (Publish-Skills)
├── plugins/              # optional plugin JS (Passo 5 decision)
└── AGENTS.md             # written by Publish-Router (core/router → AGENTS.md)
```

Do not sync this tree to a live OpenCode home. CI and local smokes must use this
fixture (or another path under the repo root).
