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

adaptive: trivial work (3/6/150 limits) may stay in the parent. always: delegates everything except qa_checklist. Full table: `core/policy/orchestrator-session.md` "Modes".
## Optional chat compression

`caveman_mode` defaults to **on** when non-interactive sync creates `preferences.json`. On interactive first sync, the toolkit asks for both parent orchestration mode and Caveman mode, with **on** as the default choice. Existing preferences are preserved. Caveman only shortens chat prose; it does not change skill steps, gates, or this documentation.

Commands: `caveman on`, `caveman off`, `caveman status`, `caveman lite`, `caveman full`, `caveman ultra`. `stop caveman` and `normal mode` turn it off. On Claude, the `UserPromptSubmit` hook (`preferences-command.ps1`) handles these commands together with the orchestrator commands, and writes `sdd/preferences.json`.

`help-skills`, `read-sdd-artifact`, `commit`, `push`, and `open-github-pr` never compress. Gates, drafts, paths, and gate labels stay clear. Labels are localized; answers are matched by meaning, not by a fixed word (see `core/skills/_shared/agents/QUESTIONS.md`). Credit for the idea: [CREDITS.md](../CREDITS.md). Policy file: `core/policy/caveman-mode.md`.

## Other preference keys

Created with the defaults object when the file is missing:

| Key | Default | Effect |
|-----|---------|--------|
| `orchestrator_mode` | `adaptive` | Parent orchestrates; trivial work may stay in the parent |
| `caveman_mode` | `true` | Chat compression on (interactive first sync can choose off) |
| `caveman_level` | `full` | Intensity if compression is turned on |
| `artifact_language` | `null` | No locale override |
| `verify_mode` | `false` | O3 does not spawn a read-only verifier after each implementer |

`verify_mode: true` is a second child after a successful `sdd-develop` step. It is not the evidence script (`validate-evidence`).
