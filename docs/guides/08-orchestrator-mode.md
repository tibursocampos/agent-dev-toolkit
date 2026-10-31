# 08 — Orchestrator mode

Always-on **parent orchestrator** policy: this chat stays lean (goals, gates, paths, receipts, synthesis). Specialists write code, run builds/tests, and perform heavy analysis.

Canonical contract (after sync): `core/policy/orchestrator-session.md`  
Router summary: `core/router/AGENTS.md` → **ORCHESTRATOR CHARTER**  
Spawn/handoff: `core/skills/_shared/agents/SPAWN.md`

## Default

**`orchestrator_mode: "adaptive"`** is the default for every adapter. When `preferences.json` is missing, sync creates it with:

```json
{
  "caveman_mode": true,
  "caveman_level": "full",
  "orchestrator_mode": "adaptive",
  "artifact_language": null,
  "verify_mode": false
}
```

An existing `preferences.json` keeps its values; sync only seeds a missing file.

Location: `{{SDD_ROOT}}/preferences.json` (under the agent's published SDD root after sync). Resolve via host-aware `effective_SDD_ROOT` (`STORAGE.md`).

Interactive first sync (`toolkit.ps1` → Sync agent) prompts when the file is missing:

```text
[1] Adaptive (recommended default)
[2] Always orchestrate
```

The Claude hooks do not carry their own default for `orchestrator_mode`. Sync seeds `adaptive` into a missing file. If the file is deleted after sync, the Claude session-start state line and `orchestrator status` report `missing`, and the parent applies the policy default `adaptive` until the next sync reseeds the file. Run `orchestrator status` after a fresh install to confirm the stored value.

## ORCHESTRATOR CHARTER (summary)

1. **Parent orchestrator-only** — no app code, builds, scripts/batches, or heavy multi-file analysis in the parent chat.
2. **Delegate in parallel** — independent work → specialist subagents; minimal handoff (scoped paths + receipt + role).
3. **Post-change validation** — child runs build + tests after file changes; parent synthesizes `{ build, tests, summary }`.

## Commands (in chat)

| Command | Effect |
|---------|--------|
| `orchestrator always` | Set `orchestrator_mode: "always"` |
| `orchestrator adaptive` | Set `orchestrator_mode: "adaptive"` |
| `orchestrator status` | Report current mode |

Aliases: `orchestrate always`, `parent always`, `orchestrate adaptive`, `parent adaptive`, `orchestrate status`, `parent status`.

On Claude, the `UserPromptSubmit` hook `preferences-command.ps1` handles these commands and the Caveman commands (`caveman on|off|status|lite|full|ultra`, plus `stop caveman` and `normal mode`), and writes `sdd/preferences.json`. Other adapters apply the same commands through the always-on policy rule.

When active, agents show once per session:  
`[Orchestrator] Mode active: always. Type orchestrator status to review.` (mode varies)

## Modes

| Mode | Behavior |
|------|----------|
| **adaptive** (default) | Same spawn preference for multi-file / heavy work; may keep **thin trivial** Q&A or one-file no-spread edits in-parent |
| **always** | Strict parent orchestrator; spawn for non-trivial work per `SPAWN.md` |

Both modes honor spawn caps, fallback when `subagents=none`, and Caveman-scoped child I/O.

## PRD / PLAN execution policy

Templates include **## Execution policy** (`templates/sdd/PRD.md`, `templates/sdd/PLAN.md`) so each feature documents orchestrator mode, parent role, child validation, and handoff rules for the wave.

## Related

- [01-getting-started.md](01-getting-started.md)  
- [session-behavior.md](session-behavior.md)  
- Installed `OPERATOR.md`  
- [STORAGE.md](../../core/sdd/STORAGE.md) § Preferences
