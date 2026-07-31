# Codex InstallRoot fixture (in-repo)

Seed directory used by Codex sync/smoke as a safe `InstallRoot`.
Paths resolve under the toolkit repo — never under `%USERPROFILE%` unless
`-AllowUserHome` is set explicitly.

## Layout (skeleton)

```
codex/
├── .agents/
│   ├── skills/          # mirrors ~/.agents/skills (opt-in via Publish-Skills -UserScope)
│   └── plugins/         # marketplace catalog (marketplace.json via Publish-Skills)
├── plugin/              # toolkit Codex plugin root
│   ├── .codex-plugin/   # plugin.json lands in Publish-Skills
│   ├── skills/          # bundled plugin skills (default Publish-Skills)
│   └── hooks/           # hooks.json + session_start.ps1 via Publish-Hooks
└── AGENTS.md            # written by Publish-Router from core/router
```

## USER skills scope

- Default `Publish-Skills`: plugin-bundled only (`plugin/skills` + marketplace).
  Does **not** write real `$HOME/.agents/skills`.
- Optional `-UserScope`: also mirrors `core/skills` under
  `InstallRoot/.agents/skills` (fixture stand-in for `~/.agents/skills`).

RN03: smoke asserts hooks **files** only. Trust via Codex `/hooks` UI is a
manual human step after a real install — never invoked by CI/smoke.

Do not sync this tree to a live Codex home. CI and local smokes must use this
fixture (or another path under the repo root).
