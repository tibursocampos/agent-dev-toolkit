# Known risks

| Risk | Mitigation |
|------|------------|
| Antigravity twin paths ≠ official `~/.gemini/config` | Adapter prefers official paths; legacy bridge only if IDE smoke requires |
| Replacing Claude/Codex settings.json wholesale | Keyed merge + backup; never wipe runtime dirs; Claude `permissions.allow` narrow (per-hook Bash), strip legacy broad wildcards unless opt-in |
| Codex hooks trust gate | Document `/hooks` trust; smoke asserts files, not live trust UI |
| OpenCode hooks are JS plugins, not PS1 | Capability `hooks` + `HooksSemantics=plugin-only`; do not fake shell-hook parity; CI = filesystem smoke only |
| Uninstall wiping SDD operator state | Keyed uninstall must preserve `sdd/sessions` and `sdd/manifest.json`; CI asserts (incl. Cursor/ZCode) verify survival |
| Subagents registry vs effective (Antigravity) | Registry may be `native`; prefer `Get-Capabilities` probe (pré-2.0 → `none`) |
| Drift vs intact twins | Accepted; changelog only in this repo |
| Accidental publish to real user home in tests | Fixture roots + fail if InstallRoot resolves under USERPROFILE without `-AllowUserHome`; CI uses Assert-SyncAllowUserHomeForward probe only |
| Extended/device path prefixes (`\\?\`, `\\.\`) bypassing USERPROFILE compare | Strip both prefixes before policy; Assert-InstallRootSafety; Initialize orphan cleanup on Confirm fail |
| Managed-skills prune / copy path escape via `..` names | Sanitize names + under-root asserts; Assert-ManagedSkillsPathSafety |
| Uninstall `Remove-Item` following junction outside InstallRoot | `Assert-PathUnderInstallRootForDelete` immediately before each delete |
| Docs linking story `features/**` paths | Public docs use `docs/SPAWN.md` / `core/skills/_shared/agents/SPAWN.md` only; Assert-NoFeaturesDocLinks |
