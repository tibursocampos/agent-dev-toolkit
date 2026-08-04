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
│   │   ├── help-skills/SKILL.md
│   │   └── _shared/skills-catalog/CATALOG.md
│   └── hooks/           # hooks.json + session_start.ps1 via Publish-Hooks
├── rules/               # core/policy/*.md via Publish-Policy (capability rules=true)
├── AGENTS.md            # materialized by Publish-Router (dual-root absolute paths)
└── sdd/                 # SDD runtime (sessions + manifest)
```

## Smoke asserts (filesystem-only)

After `sync-agent -Agent codex` (or CI ephemeral sync), `Invoke-SmokeValidate` checks:

1. TE01–TE04: InstallRoot resolve, plugin.json + skills, marketplace source.path, hooks files
2. `plugin/skills/help-skills/SKILL.md` and `plugin/skills/_shared/skills-catalog/CATALOG.md`
3. `InstallRoot/rules/` with every `core/policy/*.md` counterpart
4. `AGENTS.md`: no leftover `{{…}}`, no live `docs/` links, dual-root callout + absolute InstallRoot/plugin paths
5. UserScope: empty `.agents/skills` skeleton is OK (default sync is plugin-only). When `-UserScope` mirrored skills are present, smoke also requires help-skills + CATALOG under `.agents/skills`

RN03: smoke asserts hooks **files** only. Trust via Codex `/hooks` UI is a
manual human step after a real install — never invoked by CI/smoke.

## USER skills scope

- Default `Publish-Skills`: plugin-bundled only (`plugin/skills` + marketplace).
  Does **not** write real `$HOME/.agents/skills` from a fixture InstallRoot.
- Optional `-UserScope` on a fixture InstallRoot: mirrors `core/skills` under
  `InstallRoot/.agents/skills` (stand-in for `~/.agents/skills`).
- Optional `-UserScope` when InstallRoot is live `~/.codex` with `-AllowUserHome`:
  writes real `$HOME/.agents/skills`.

Do not sync this tree to a live Codex home. CI and local smokes must use this
fixture (or another path under the repo root).
