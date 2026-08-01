# GitHub Copilot adapter (`copilot`)

Publish surfaces for **GitHub Copilot** (`Mode` `user` \| `repo`). Default InstallRoot is an in-repo sync fixture; live `USERPROFILE` roots require `-AllowUserHome`.

| Item | Value |
|------|-------|
| Agent id | `copilot` |
| Purpose | Publish skills, instructions, and hooks for Copilot user or repo roots |
| Sync fixtures | `scripts/validation/fixtures/copilot/user`, `scripts/validation/fixtures/copilot/repo` |
| `subagents` (registry) | `native` |

```powershell
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent copilot -Mode user -InstallRoot .\scripts\validation\fixtures\copilot\user
```

## Spawn / subagents (honesty)

| Field | Value |
|-------|-------|
| Registry / `Get-Capabilities` | `native` |
| Host mechanism | Copilot CLI **`/fleet`** (parallel subagents); optional custom agents in `.github/agents/` |
| Toolkit contract | Prefer `/fleet` (or host equivalent) when `subagents=native`; SPAWN in-parent fallback otherwise |

### Official references

- [Customization cheat sheet](https://docs.github.com/en/copilot/reference/customization-cheat-sheet)
- [Repo custom instructions](https://docs.github.com/copilot/customizing-copilot/adding-custom-instructions-for-github-copilot)
- [CLI custom instructions](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-custom-instructions)
- [CLI skills](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-skills)
- [Hooks](https://docs.github.com/en/copilot/concepts/agents/hooks)
- [Copilot CLI product](https://github.com/features/copilot/cli)
- [Run multiple agents with `/fleet`](https://github.blog/ai-and-ml/github-copilot/run-multiple-agents-at-once-with-fleet-in-copilot-cli/)

Public contract: [docs/ADAPTERS.md](../../docs/ADAPTERS.md).
