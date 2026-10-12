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

## Evidência de ativação de skills por adapter

O contrato compartilhado de ativação está em `core/skills/_shared/skills-catalog/CATALOG.md`: cada skill declara sinais positivos e negativos, solicita esclarecimento em caso de ambiguidade com ação mutável e não usa inferência vaga como gatilho. Os adapters abaixo publicam os arquivos e metadados para a superfície de cada host; nomes de comandos, formatos de configuração e caminhos continuam documentados no adapter correspondente.

| Adapter suportado | Evidência local verificada | Invocação documentada / lacuna | Limite da evidência |
|---|---|---|---|
| Cursor | `cursor/README.md`; `cursor/Invoke-CursorSmokeValidate.ps1` verifica manifests no caminho de skills publicado. | `/id`; também há seletor de skills com opções manual/automática. | Smoke verifica arquivos publicados; seleção automática e carregamento em uma sessão Cursor ao vivo não foram reproduzidos. |
| Antigravity | `antigravity/README.md`; `antigravity/Invoke-AntigravitySmokeValidate.ps1` verifica `config/skills/<id>/SKILL.md` e a entrada gerenciada de `config/skills.json`. | `use skill id` ou `/id`. | Smoke verifica layout e registro local; descoberta e ativação em sessão Antigravity ao vivo não foram reproduzidas. |
| Claude Code | `claude/README.md`; `claude/Invoke-ClaudeSmokeValidate.ps1` verifica manifests no caminho de skills publicado. | `/id`. | Smoke verifica arquivos publicados; descoberta ou ativação em sessão Claude Code ao vivo não foi reproduzida. |
| Codex | `codex/README.md`; `codex/Invoke-CodexSmokeValidate.ps1` verifica skills do plugin e o catálogo no root de skills `$`. | `$<skill-id>` no root de skills do Codex; o espelho opcional `.agents/skills` é uma superfície separada. | Smoke verifica arquivos e layout; descoberta e ativação em sessão Codex ao vivo não foram reproduzidas. |
| GitHub Copilot | `copilot/README.md`; `copilot/Invoke-CopilotSmokeValidate.ps1` verifica os manifests publicados nos modos `user` e `repo`. | `/id` e `/skills reload` estão documentados para CLI. VS Code varia por versão; SDK configura skills por aplicação. | CLI, VS Code e SDK são superfícies distintas. Smoke não prova carregamento ao vivo em nenhuma delas; VS Code/SDK requerem evidência da própria superfície. |
| OpenCode | `opencode/README.md`; `opencode/Invoke-OpenCodeSmokeValidate.ps1` verifica manifests no caminho de skills publicado. | Ferramenta `skill`, usando o nome do skill. | Smoke verifica arquivos publicados; resolução pela ferramenta `skill` em sessão OpenCode ao vivo não foi reproduzida. |
| Grok Build | `grok/README.md`; `grok/Invoke-GrokSmokeValidate.ps1` verifica o layout nativo de skills publicado. | A sintaxe explícita de invocação não está registrada na evidência local consultada. | Layout publicado é evidência estática; sintaxe de invocação e ativação ao vivo permanecem não verificadas. Não inferir comportamento a partir de Claude/Cursor. |
| ZCode | `zcode/README.md`; `zcode/Invoke-ZCodeSmokeValidate.ps1` verifica o layout publicado de skills. | `$id`; atualizar a lista de skills após sync se necessário. | Smoke verifica arquivos publicados; atualização e ativação em sessão ZCode ao vivo não foram reproduzidas. |
| Hermes | `hermes/README.md`; `hermes/Invoke-HermesSmokeValidate.ps1` verifica manifests no caminho de skills publicado. | A sintaxe explícita de invocação não está registrada na evidência local consultada. O trust opcional de skills é uma configuração separada, não prova de ativação. | Smoke verifica layout e manifest; seleção/ativação em sessão Hermes ao vivo permanece não verificada. |
| OpenHands | `openhands/README.md`; `openhands/Invoke-OpenHandsSmokeValidate.ps1` verifica manifests no layout de projeto ou no root de skills do usuário. | A sintaxe explícita de invocação não está registrada na evidência local consultada. | Smoke verifica arquivos publicados; seleção/ativação em sessão OpenHands ao vivo permanece não verificada. |

`Verificada` nesta matriz significa somente que há evidência local do publisher/layout e do smoke de arquivos indicado. Não significa que o host carregou ou ativou a skill em runtime. Cada linha mantém sua lacuna individual; nenhum resultado de um provider é extrapolado para outro.

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
