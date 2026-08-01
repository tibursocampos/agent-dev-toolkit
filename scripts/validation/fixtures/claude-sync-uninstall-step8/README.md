# Claude InstallRoot fixture (in-repo)

Seed directory for Claude adapter publish/smoke. Resolves under the toolkit repo —
never under `%USERPROFILE%` unless `-AllowUserHome` is set.

**InstallRoot path (relative to repo root):** `scripts/validation/fixtures/claude`

## Pre-existing settings (merge seed)

Versioned `settings.json` at the fixture root models a realistic user profile before sync:

| Marker | Purpose |
|--------|---------|
| `operatorCustomKey` | Unrelated key that merge must preserve |
| `env.*` | Alien nested object preserved across merge |
| `hooks.Notification` | Alien hook event preserved |
| `hooks.UserPromptSubmit` = `stale-user-prompt` | Partial managed hook — toolkit upserts on merge |
| `permissions.allow` includes `Bash(git status)` | User allow kept; toolkit allows added |
| `permissions.deny` | Preserved as-is |
| UTF-8 without BOM | Encoding baseline |

Do not point InstallRoot at a live Claude user home from CI.

## Point InstallRoot at this fixture

```powershell
# From repo root
$fixture = Join-Path $PWD 'scripts/validation/fixtures/claude'

# Publish / merge (later orchestrated by sync-agent)
.\scripts\sync-agent.ps1 -Agent claude -InstallRoot $fixture

# Assert merge + keyed uninstall
pwsh -NoProfile -File .\scripts\validation\Assert-ClaudeSettingsMerge.ps1
pwsh -NoProfile -File .\scripts\validation\Assert-ClaudeKeyedUninstall.ps1
```

Expected after full publish (ephemeral artifacts may be recreated by asserts):

- `skills/` from `core/skills/`
- `rules/*.md` from `core/policy/`
- `CLAUDE.md` from `core/router/AGENTS.md`
- `hooks/*.ps1` from `adapters/claude/assets/hooks/`
- `settings.json` merged (backup `settings.json.bak`); seed markers above remain for merge asserts
