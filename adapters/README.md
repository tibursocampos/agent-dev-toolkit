# Adapters

Agent registry and per-agent publish modules live here. Orchestrators resolve an agent via `registry.json`, then load the module named on that entry.

| Path | Role | README |
|------|------|--------|
| `registry.json` | Agent ids, display names, capability flags, module paths | — |
| `_contract/AdapterContract.ps1` | Shared contract helpers / stub surface | — |
| `_shared/` | Cross-adapter hook helpers (`GuardCommon.ps1`, `guard-rules.md`) | — |
| `cursor/` | Cursor — `~/.cursor` publish + fixture smoke | [README](cursor/README.md) |
| `antigravity/` | Antigravity — `~/.gemini` official `config/*` | [README](antigravity/README.md) |
| `claude/` | Claude Code — skills, rules, `CLAUDE.md`, settings merge | [README](claude/README.md) |
| `codex/` | Codex — plugin + marketplace packaging | [README](codex/README.md) |
| `copilot/` | GitHub Copilot — Mode `user` \| `repo` | [README](copilot/README.md) |
| `opencode/` | OpenCode — skills + JS plugins | [README](opencode/README.md) |
| `grok/` | Grok Build — native `.grok` publish | [README](grok/README.md) |
| `zcode/` | ZCode ADE — `~/.zcode` filesystem | [README](zcode/README.md) |
| `hermes/` | Hermes — `~/.hermes`; policy folded into `AGENTS.md` | [README](hermes/README.md) |
| `openhands/` | OpenHands — project `.agents/` + `.openhands/` | [README](openhands/README.md) |

Public contract: [docs/ADAPTERS.md](../docs/ADAPTERS.md).

## Blocking approval interaction and evidence limits

Every adapter must preserve the shared gate lifecycle in [`approval-gates.md`](../core/skills/orchestrate-deliver/references/approval-gates.md): state the question and scope, keep dependent work blocked while pending, accept a visible host control only when the host actually returns its choice, and provide explicit text choices as the fallback. On resumed turns, restate/reload the active gate before dependent work. Toolkit publication cannot force a host to display, retain, retract, or redeliver a prompt.

| Adapter | Supported interaction evidence | Retry / redelivery observability limit |
|---------|---------------------------------|-----------------------------------------|
| Cursor | Text choices in the agent conversation; a host control counts only when the agent receives its selected value. | Hooks observe configured tool lifecycle events, not prompt display, answer delivery, or UI retries. Record those as `SKIPPED` unless a live run exposes them. |
| Antigravity | Text choices in the agent conversation; record an approval result only after the agent receives it. | Toolkit filesystem smoke does not observe conversation delivery or UI retry/redelivery. |
| Claude Code | Text choices in the agent conversation; hooks may record only their documented lifecycle events. | Hook events do not prove the user saw a prompt or that a retried message was processed. Live host evidence required. |
| Codex | Text choices in the agent conversation; any UI affordance is evidence only when its selected value reaches the agent. | Published files/static validation do not observe prompt display, queueing, or retries. |
| GitHub Copilot | Use the actual surface (CLI, VS Code, or SDK) and record a textual choice or returned callback result for that surface. | CLI, IDE, and SDK are separate evidence scopes. SDK callbacks can expose application events; do not infer delivery or retry visibility for CLI/VS Code. See [`copilot/README.md`](copilot/README.md). |
| OpenCode | Text choices in the agent conversation; record the processed answer before resuming. | Filesystem/plugin validation does not establish UI display or answer redelivery. |
| Grok | Text choices in the agent conversation; record a processed answer before resuming. | Toolkit smoke cannot observe message queue, prompt display, or host retries. |
| ZCode | Text choices in the agent conversation; record a processed answer before resuming. | Toolkit validation does not observe host prompt lifecycle or redelivery. |
| Hermes | Text choices in the agent conversation; record a processed answer before resuming. | Adapter publication does not observe host prompt lifecycle or redelivery. |
| OpenHands | Text choices in the agent conversation; record a processed answer before resuming. | Filesystem validation does not observe host prompt lifecycle or redelivery. |

These rows describe toolkit evidence boundaries, not guarantees about host UI behavior. Record host, version, surface, prompt scope, answer, and observed lifecycle events for each live run; mark unavailable delivery/retry signals `SKIPPED` rather than treating absence as success.

**Constraint:** default sync/smoke uses in-repo fixtures. Live user-profile roots require `-AllowUserHome` on `sync-agent.ps1` / `validate-agent.ps1`.
