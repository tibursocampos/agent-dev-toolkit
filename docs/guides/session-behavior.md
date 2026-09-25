# Session behavior

These rules apply in every chat after sync. They are preferences and policy, not a separate workflow.

Source: `core/skills/_shared/agents/LANGUAGE.md`, `core/policy/orchestrator-session.md`, `core/policy/caveman-mode.md`, `scripts/_lib/Initialize-SddPreferences.ps1`.

## Language

| Surface | Language |
|---------|----------|
| What the operator reads (chat, host plans) | The language of this chat |
| Feature artifacts (FEATURE, STORY, PRD, PLAN, ARCH, SEC, CONTINUITY, CHANGE prose) | Same resolution as below |
| Child prompts, specialist context, receipts | English (`en-US`) |
| Identifiers, paths, skill ids, commits, tests | English |
| This toolkit’s public `docs/` | English |

Artifact language, once per write: invocation override, else `preferences.json` `artifact_language` when it is not null, else manifest `artifact_language` when it is not null, else the chat language. `null` means no override.

`core/policy/user-language-pt-br.md` and `core/policy/sdd-artifact-language-pt-br.md` ship as install defaults for a Brazilian Portuguese session. When chat or preferences name another language, `LANGUAGE.md` wins. Cursor publish writes those policy files to `InstallRoot/rules` as `.mdc` through `Publish-Policy` (`adapters/cursor/Publish-CursorPolicy.ps1`), invoked by `scripts/sync-agent.ps1`.

Child handoffs carry a path and a short excerpt. They do not paste a full PRD, PLAN, or memory-bank.

## Parent orchestrator

Default `orchestrator_mode` is `always`. The parent keeps goals, gates, paths, and receipts. Specialists write notes or code. Commands: `orchestrator always`, `orchestrator adaptive`, `orchestrator status` (aliases `orchestrate` and `parent`).

`adaptive` may keep a single-path question or a one-file edit in the parent. Any wider change is spawned. If the host has `subagents=none`, the same work stays in the parent. The session does not fail because Task is missing.

Full charter: [08-orchestrator-mode.md](08-orchestrator-mode.md). Spawn matrix: [SPAWN.md](../SPAWN.md).

Task `model` is omitted so the child uses the parent session model (`core/skills/_shared/agents/SUBAGENT-MODEL.md`). A different model needs an explicit approval. Silence is not that approval.

## Optional chat compression

`caveman_mode` defaults to **off**. It only shortens chat prose. It does not change skill steps, gates, or this documentation.

Commands: `caveman on`, `caveman off`, `caveman status`, `caveman lite`, `caveman full`, `caveman ultra`. `stop caveman` and `normal mode` turn it off.

`help-skills`, `read-sdd-artifact`, `commit`, `push`, and `open-github-pr` never compress. Gates, drafts, paths, and `(sim / ajustar / cancelar)` stay clear. Credit for the idea: [CREDITS.md](../CREDITS.md). Policy file: `core/policy/caveman-mode.md`.

## Other preference keys

Created with the defaults object when the file is missing:

| Key | Default | Effect |
|-----|---------|--------|
| `orchestrator_mode` | `always` | Parent stays orchestrator |
| `caveman_mode` | `false` | Chat compression off |
| `caveman_level` | `full` | Intensity if compression is turned on |
| `artifact_language` | `null` | No locale override |
| `verify_mode` | `false` | O3 does not spawn a read-only verifier after each implementer |

`verify_mode: true` is a second child after a successful `sdd-develop` step. It is not the evidence script (`validate-evidence`).
