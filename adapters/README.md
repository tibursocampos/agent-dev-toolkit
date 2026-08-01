# Adapters

Tier 1 agent registry and per-agent publish modules live here. Orchestrators resolve an agent via `registry.json`, then load the module named on that entry.

| Path | Role | README |
|------|------|--------|
| `registry.json` | Agent ids, display names, capability flags, module paths | — |
| `_contract/AdapterContract.ps1` | Shared contract helpers / stub surface | — |
| `cursor/` | Cursor — `~/.cursor` publish + fixture smoke | [README](cursor/README.md) |
| `antigravity/` | Antigravity — `~/.gemini` official `config/*` | [README](antigravity/README.md) |
| `claude/` | Claude Code — skills, rules, `CLAUDE.md`, settings merge | [README](claude/README.md) |
| `codex/` | Codex — plugin + marketplace packaging | [README](codex/README.md) |
| `copilot/` | GitHub Copilot — Mode `user` \| `repo` | [README](copilot/README.md) |
| `opencode/` | OpenCode — skills + JS plugins | [README](opencode/README.md) |
| `grok/` | Grok Build — native `.grok` publish | [README](grok/README.md) |
| `zcode/` | ZCode ADE — `~/.zcode` filesystem | [README](zcode/README.md) |

Public contract: [docs/ADAPTERS.md](../docs/ADAPTERS.md).

**Constraint:** default sync/smoke uses in-repo fixtures. Live user-profile roots require `-AllowUserHome` on `sync-agent.ps1` / `validate-agent.ps1`.
