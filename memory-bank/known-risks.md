# Known risks

| Risk | Area | Mitigation / note |
|------|------|-------------------|
| Live home writes are opt-in | Install | Default destination is an in-repo fixture. Profile writes require `-AllowUserHome`. |
| `subagents=none` cannot spawn children | Spawn | Fallback is in-parent. OpenHands registry value is `none`. Antigravity effective value is the runtime probe (`ADT_ANTIGRAVITY_SUBAGENTS` / product version), not the registry string alone. |
| Develop session scope | SDD | `sdd-develop` executes one PLAN step per session, including `continuous` mode. |
| Language source of truth is split | Policy | Surface resolution is `core/skills/_shared/agents/LANGUAGE.md`. `core/policy/user-language-pt-br.md` and `core/policy/sdd-artifact-language-pt-br.md` are pt-BR install defaults and do not override that matrix when chat or preferences differ. |
| CI does not prove a live agent home | Validation | `.github/workflows/validate-toolkit.yml` runs validate-core plus fixture smokes and keyed-uninstall asserts. It does not sync `USERPROFILE`. |
| Backup is a stub | CLI | `-Action Backup` is fail-closed unless a test passes `-ForceStub`. It does not snapshot an install. |
| Uninstall is keyed | Adapters | Toolkit-owned files are removed. Alien operator files and `sdd/sessions` stay. Re-sync is update-in-place, not uninstall-then-install. |

## Fragile areas

- `adapters/registry.json` capability `subagents` versus Antigravity `Get-Capabilities` effective value.
- `core/skills/_shared/agents/LANGUAGE.md` versus `core/policy/*language-pt-br.md`.
- `InstallRoot` resolution (`-AllowUserHome`, Copilot `-Mode user|repo`, Codex optional `-UserScope`).

## Operational gotchas

- Missing or unknown `subagents` is treated as `none`.
- `verify_mode` defaults to false. A read-only post-implement verifier runs only when preferences set it true.
- Manifest `storage_mode` is `repository` or `global`. A global bank lives outside this repo tree.

## Notes

Facts from registry, spawn, language, CLI, and CI sources. Update when incidents or reviews find new footguns.
**No secrets** - describe classes of risk, not credentials.
