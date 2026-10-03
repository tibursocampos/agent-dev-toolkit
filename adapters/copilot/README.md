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

## How to invoke

| Item | Value |
|------|-------|
| Skills path | Mode `user`: `~/.copilot/skills` · Mode `repo`: `<repo>/.github/skills` |
| Explicit form | `/id` |
| Examples | `/help-skills`, `/dotnet-developer` |
| After sync | `/skills reload` (CLI) so new skills appear |

Canonical form is the skill **id**; `/` is the Copilot host prefix.

## Surface matrix and comparison record

The adapter covers filesystem publication. It does not infer that files were loaded by a running host. Record the host and version fields below for each live comparison; the adapter smoke itself reports static evidence only.

| Surface | Version to record | Mode | Instructions | Skills / agents | Tools / permissions / hooks | Context | Session state | Evidence boundary |
|---------|-------------------|------|--------------|-----------------|-----------------------------|---------|---------------|-------------------|
| Copilot CLI | `copilot --version` | `user`, `repo` | CLI customization is documented; toolkit publishes the user and repo layouts. | Skills and custom agents publish in both modes. | CLI hooks are documented and published; actual tool permissions are not exercised by static smoke. | Record workspace, prompt, model, and loaded instruction/skill identifiers. | Record new/resumed state and observed events. | Product docs + toolkit filesystem observation; live CLI behavior requires a host run. |
| Copilot in VS Code | VS Code and Copilot/Copilot Chat extension versions | `repo` | Repository and path-specific instructions are documented for VS Code. | Feature/version dependent; this adapter does not verify IDE loading. | Record enabled tools and approval settings from the live session. CLI hooks do not prove VS Code hook behavior. | Record workspace, prompt, model, loaded instruction/skill identifiers, and relevant settings. | Observe and record state in the actual chat session. | Product docs + live VS Code observation; filesystem smoke is not IDE evidence. |
| Copilot SDK | SDK package, runtime, and Copilot CLI versions | `application-defined` | Application/session configured; do not infer file discovery from CLI or VS Code. | SDK skills, agents, and tools are configured through SDK session/plugin facilities. | Hooks and permission handlers are application callbacks. | Record app configuration, working directory, model, loaded skills/plugins, prompt, and tool list. | Record session id, create/resume path, and lifecycle events. | Product docs + live application instrumentation; toolkit does not create an SDK session. |

### Skill copy fidelity

The sync path is `core/skills/**` → `Publish-CopilotSkills.ps1` → `Invoke-ToolkitManagedSkillsPublish` in `scripts/_lib/Copy-ToolkitManagedTree.ps1` → `<InstallRoot>/skills/**`. User mode models `~/.copilot`; repo mode models `<repo>/.github`. The shared copier keeps each relative path and file, then the Copilot publisher resolves only `{{TOOLKIT_ROOT}}`, `{{SDD_ROOT}}`, and `{{GUARDRAILS_PATH}}` for the selected install root. `_shared/` is support material referenced by skills; it is copied intact but is not itself a skill because it has no top-level `SKILL.md`.

| Canonical source | Generated Copilot artifact | Expected transformation |
|------------------|----------------------------|-------------------------|
| `core/skills/developer/SKILL.md` | `skills/developer/SKILL.md` | Preserve YAML `name: developer`, `description`, and body; expand path tokens to this install root. |
| `core/skills/sdd-develop/references/plan-contract.md` | `skills/sdd-develop/references/plan-contract.md` | Preserve relative path and body; expand path tokens only. |
| `core/skills/_shared/sdd-artifacts/SESSION.md` | `skills/_shared/sdd-artifacts/SESSION.md` | Preserve shared support path and body; expand path tokens only. |

The CI smoke compares every generated skill file with its canonical source after those three expansions, checks each discoverable top-level skill has a matching lowercase/hyphen `name` plus a non-empty `description`, and separately reports host execution as `SKIPPED`. GitHub documents the required `SKILL.md` directory/frontmatter and the user/repository discovery roots in [Adding agent skills](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-skills) and the [CLI configuration directory reference](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-config-dir-reference).

### Copilot-specific materialization findings

The format audit found material differences beyond byte-for-byte copy fidelity. Copilot CLI documents personal agents in `~/.copilot/agents`, so user-mode publication is supported; the earlier no-op skipped a real discovery scope. VS Code custom agents use `.agent.md` profiles under `.github/agents`, while Copilot CLI accepts both `.md` and `.agent.md`; publication now emits one `.agent.md` profile for the shared CLI/VS Code ID. See [Using custom agents in your IDE](https://docs.github.com/en/copilot/how-tos/copilot-in-your-ide/use-copilot-agents/use-custom-agents), [Invoking custom agents in Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/use-copilot-cli/invoke-custom-agents), and [Custom agents configuration](https://docs.github.com/en/copilot/reference/custom-agents-configuration).

Copilot CLI custom subagents default `include-custom-instructions` to `false`. The publisher adds it only for `architect`, `database`, `repo-analyst`, and `security`, whose work depends on repository conventions/instructions. It remains absent for `shell-runner`, which runs a scoped command sequence. This is a targeted metadata transformation; canonical agent bodies remain unchanged for other adapters. See the [Copilot CLI custom agent reference](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference#custom-agents-reference).

Hooks use the published hook directory as an absolute `cwd`, with a script path relative to that directory. GitHub's hook schema allows `cwd` to be absolute or repo-root-relative; repo hooks are discovered as `.github/hooks/*.json`, and user hooks under `~/.copilot/hooks/`. The smoke resolves the configured command for both fixture modes and checks it identifies the copied script. See the [hooks reference](https://docs.github.com/en/copilot/reference/hooks-reference) and [CLI configuration directory reference](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-config-dir-reference).

These checks prove documented layout and static path/frontmatter validity. They do not demonstrate that current Copilot CLI or VS Code versions load the generated profiles, choose the same skills, or perform equally well; live host behavior remains untested.

### Evidence labels

- **Documented**: stated by the linked GitHub product documentation; it does not prove the current host configuration loaded it.
- **Observed (toolkit)**: a local adapter or validation script inspected/copied a filesystem artifact. This is not a live host observation.
- **Hypothesis / unverified**: any expectation about extension versions, implicit discovery, permission prompts, context injection, or session resumption until reproduced on that exact host/version.

For comparable runs, record host + exact version(s), mode, model, workspace, prompt, instruction/skill/agent identifiers, tool and permission settings, hook configuration, context inputs, and whether the session was new or resumed. Compare like-for-like fields and leave unknowns explicitly `SKIPPED`; do not use CLI or SDK evidence as proof of VS Code behavior.

`Get-Capabilities` exposes this same matrix through `SurfaceMatrix` so callers can inspect the evidence boundary programmatically.

## Spawn / subagents (honesty)

| Field | Value |
|-------|-------|
| Registry / `Get-Capabilities` | `native` |
| Host mechanism | Copilot CLI **`/fleet`** (parallel subagents); optional custom agents in `.github/agents/` |
| Toolkit contract | Prefer `/fleet` (or host equivalent) when `subagents=native`; SPAWN in-parent fallback otherwise |
| Published files | `Publish-Agents` writes `.agent.md` profiles from `core/agents/` into user (`~/.copilot/agents/`) and repo (`.github/agents/`) scopes. |

### Official references

- [Customization cheat sheet](https://docs.github.com/en/copilot/reference/customization-cheat-sheet)
- [Repo custom instructions](https://docs.github.com/copilot/customizing-copilot/adding-custom-instructions-for-github-copilot)
- [CLI custom instructions](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-custom-instructions)
- [CLI skills](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-skills)
- [Hooks](https://docs.github.com/en/copilot/concepts/agents/hooks)
- [VS Code customization cheat sheet](https://docs.github.com/en/copilot/reference/customization-cheat-sheet)
- [Copilot SDK](https://docs.github.com/en/copilot/how-tos/copilot-sdk)
- [Copilot SDK session hooks](https://docs.github.com/en/copilot/how-tos/copilot-sdk/features/hooks)
- [Copilot CLI product](https://github.com/features/copilot/cli)
- [Run multiple agents with `/fleet`](https://github.blog/ai-and-ml/github-copilot/run-multiple-agents-at-once-with-fleet-in-copilot-cli/)

Public contract: [docs/ADAPTERS.md](../../docs/ADAPTERS.md).
