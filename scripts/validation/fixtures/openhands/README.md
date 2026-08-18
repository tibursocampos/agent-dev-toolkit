# OpenHands InstallRoot fixture (in-repo)

Seed directory used by OpenHands smoke as a safe **project** `InstallRoot`.
Models a repository tree (`AGENTS.md`, `.agents/skills`, `.agents/agents`,
`.openhands`, `.plugin`) — **not** a live `~/.agents` home. Paths resolve
under the toolkit repo unless `-AllowUserHome` is set explicitly.

Publish copies `core/skills` at smoke time. Do not commit the full skills tree.

## Layout (skeleton)

```
openhands/                 # InstallRoot (= project root)
├── .agents/
│   ├── skills/            # Agent Skills (official; not microagents)
│   └── agents/            # SDK/plugin roster (not Canvas Profile)
├── .openhands/
│   └── hooks/             # shell hooks (*.sh) + sibling hooks.json
├── .plugin/               # plugin.json written by Publish-Skills
├── AGENTS.md              # written by Publish-Router / Publish-Policy
└── sdd/                   # prepared by Get-SddRoot -Prepare
```

Live user skills (`~/.agents/skills`) are a different InstallRoot
(`%USERPROFILE%\.agents` + `-AllowUserHome`). CI and local smokes must use
this fixture (or another path under the repo root).
