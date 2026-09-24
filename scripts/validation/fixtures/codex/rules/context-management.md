---
description: Checkpoint multi-step SDD skills when context is high; persist PLAN/PRD before continuing
alwaysApply: true
---

# Context management

Avoid losing progress on long, multi-step work. This rule applies to **every** interaction when context pressure is visible, and **mandatory checkpoints** at the end of each step in multi-step skills.

Host-agnostic: apply whenever the **host session** surfaces context usage (status line, system reminder, usage meter, or user-reported percentage). Do not depend on a specific product's hooks, session JSONL, or Codex-only APIs.

## Universal - every response

When the environment shows context usage:

| Usage | Status | Action |
|-------|--------|--------|
| **< 40%** | OK | Note usage briefly; continue normally |
| **≥ 40%** | Warning | Stop multi-step skills immediately; warn on other long tasks |
| **≥ 80%** | Critical | Stop immediately; do not continue in this session |

If usage is unknown, still **save artifacts to disk** at step boundaries (PLAN/PRD checkboxes, files written) when in **Agent** mode and the user has confirmed the write (`sdd-pipeline-guards.md` / `PIPELINE.md` § Confirm before write).

In **Plan/Ask**, persist progress in chat drafts until the user switches to Agent and confirms - do not claim PRD/PLAN were saved without `Write`.

Do not end a skill abruptly without persisting the control artifact (or an explicit paused draft with path pending).

## Multi-step skills - end of each step

For skills that run sequential steps against an external control file:

| Skill | Control artifact |
|-------|------------------|
| `sdd-spec` | `features/**/PRD/*.md` or global `.../features/**/PRD/` |
| `sdd-plan` | `features/**/PLAN/PLAN_*.md` or global `.../features/**/PLAN/` |
| `sdd-develop` | Same feature PLAN path as handoff (one step per session) |
| `document-implement` | `docs/documentation-plan/plan.md` (one step per session) |

Cite control artifacts with **portable paths** only in versioned files (`STORAGE.md` § Portable path). Chat may show OS absolute paths for operator clarity.

### Required flow after each completed step

1. **Persist progress** - update the control file (checkbox, status, notes).
2. **Assess context** - use visible usage or ask the user if unclear.
3. **Decide** using the table above.
4. If **≥ 40%** (Warning), pause and show the **Warning pause template** below.
5. If **≥ 80%** (Critical), pause and show the **Critical pause template** below — do **not** accept override.

### Warning pause template (≥ 40%, < 80%)

Use this host-agnostic block (fill brackets; keep structure):

```text
EXECUTION PAUSED - Context at X% used.

This is a safety stop. Execution does not continue automatically.

Saved: [portable control file path]
Last step done: [step id - short description]
Next pending: [next step id - short description]

Recommended: start a new chat/session and resume from the control file.
To continue in this session, reply exactly: force continue
```

### Critical pause template (≥ 80%)

```text
CONTEXT CRITICAL - X% used.

Progress saved. Do not continue multi-step work in this session.

Saved: [portable control file path]
Last step done: [step id - short description]
Next pending: [next step id - short description]

Strongly recommended: start a new chat/session and resume from the control file.
Override is not accepted at Critical — end the skill here.
```

### User override (Warning only)

- User says **force continue** -> continue; repeat this checkpoint after the next step
- Any other reply -> end the skill; recommend a new session
- If **≥ 80%**: do not accept force continue - stop definitively

## Optional hooks

Context-only hooks under `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/hooks/` (see `docs/HOOKS.md`):

- `beforeSubmitPrompt` - track `use skill sdd-spec|sdd-plan|sdd-develop|orchestrate-*|...` (always allows submit)
- `preToolUse` - deny Write outside allowed scopes (`features/`, `memory-bank/`, `docs/`, standard app trees) and block obvious secret patterns in write content
- `afterFileEdit` - record `features/**/PLAN/PLAN_*.md` edits
- `preCompact` - user message at 40%/80% usage before compaction

Hooks do **not** select models and do **not** read host session transcript files as a required dependency. Policy applies even when hooks are absent.

## What not to do

- Do not rely on external `check-context.ps1` or host-private session transcript paths
- Do not continue multi-step SDD silently past 40% without saving and notifying
- Do not use absolute step counts as the only limit - prefer usage percentage when available
- Do not block the user when usage status is unknown — still checkpoint at step boundaries
- Do not embed personal paths, tokens, or session IDs in versioned artifacts

## Install path

After host Publish-Policy / `scripts/sync-cursor.ps1`: published under the host rules surface from `core/policy/context-management.md` (see `docs/INSTALL.md`)
