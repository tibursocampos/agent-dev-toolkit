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
├── skills/              # Codex $ discovery mirror (always via Publish-Skills; live ~/.codex/skills)
│   ├── help-skills/SKILL.md
│   └── _shared/skills-catalog/CATALOG.md + OPERATOR.md
├── plugin/              # toolkit Codex plugin root
│   ├── .codex-plugin/   # plugin.json lands in Publish-Skills
│   ├── skills/          # bundled plugin skills (default Publish-Skills)
│   │   ├── help-skills/SKILL.md
│   │   └── _shared/skills-catalog/CATALOG.md + OPERATOR.md
│   └── hooks/           # hooks.json + guard-pre-tool.ps1 via Publish-Hooks (PreToolUse)
├── rules/               # core/policy/*.md via Publish-Policy (capability rules=true)
├── AGENTS.md            # materialized by Publish-Router (dual-root absolute paths)
└── sdd/                 # SDD runtime (sessions + manifest)
```

## Smoke asserts (filesystem-only)

After `sync-agent -Agent codex` (or CI ephemeral sync), `Invoke-SmokeValidate` checks:

1. TE01–TE04: InstallRoot resolve, plugin.json + skills, marketplace source.path, hooks files
2. `plugin/skills/help-skills/SKILL.md` and `plugin/skills/_shared/skills-catalog/CATALOG.md` + `OPERATOR.md`
3. `InstallRoot/skills/help-skills/SKILL.md` and `InstallRoot/skills/_shared/skills-catalog/CATALOG.md` (Codex `$` discovery)
4. `InstallRoot/rules/` with every `core/policy/*.md` counterpart
5. `AGENTS.md`: no leftover `{{…}}`, no live `docs/` links, dual-root callout + absolute InstallRoot/plugin/home paths
6. UserScope: **absent or empty** `.agents/skills` is OK without `-UserScope`. When `-UserScope` mirrored skills are present, smoke also requires help-skills + CATALOG + OPERATOR under the USER skills root (fixture `InstallRoot/.agents/skills`; live `$HOME/.agents/skills`)

RN03: smoke asserts hooks **files** only. Trust via Codex `/hooks` UI is a
manual human step after a real install — never invoked by CI/smoke.

## Skills scopes

- Default `Publish-Skills`: plugin-bundled (`plugin/skills` + marketplace) **and** home
  skills at `InstallRoot/skills` (live `~/.codex/skills` for `$` discovery).
  Does **not** write real `$HOME/.agents/skills` from a fixture InstallRoot.
- Optional `-UserScope` on a fixture InstallRoot: mirrors `core/skills` under
  `InstallRoot/.agents/skills` (stand-in for `~/.agents/skills`).
- Optional `-UserScope` when InstallRoot is live `~/.codex` with `-AllowUserHome`:
  writes real `$HOME/.agents/skills`. **Opt-in only** via explicit `-UserScope`
  (do not enable by default — duplicates Personal `$` picks alongside `~/.codex/skills`).

Do not sync this tree to a live Codex home. CI and local smokes must use this
fixture (or another path under the repo root).
