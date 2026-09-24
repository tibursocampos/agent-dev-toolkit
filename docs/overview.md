# Overview

**agent-dev-toolkit** is a multi-agent developer toolkit: one shared **core** of Agent Skills, policy, router, and SDD contracts, plus **adapters** that publish that core into each agent’s native install layout.

## Problem it solves

Teams use different coding agents (Cursor, Claude Code, Codex, Copilot, and others). Duplicating skills and rules per agent drifts quickly. This repo keeps a single source under `core/` and maps it through adapters at sync time.

## Architecture (summary)

```text
┌─────────────────────────────────────────────────────────┐
│  core/                                                  │
│    skills/   policy/   router/   sdd/                   │
└──────────────────────────┬──────────────────────────────┘
                           │ Publish-* (placeholders resolved)
┌──────────────────────────▼──────────────────────────────┐
│  adapters/<agent>/  ← registry.json                     │
│    Cursor · Claude · Codex · Copilot · Hermes · OpenHands · … │
└──────────────────────────┬──────────────────────────────┘
                           │ InstallRoot (fixture or live home)
┌──────────────────────────▼──────────────────────────────┐
│  Agent home: ~/.cursor · ~/.claude · ~/.hermes · …      │
│  Codex optional USER skills / OpenHands user skills: ~/.agents/skills │
└─────────────────────────────────────────────────────────┘
```

| Layer | Responsibility |
|-------|----------------|
| **Core** | Agent-neutral content; no hardcoded IDE home paths (use `{{TOOLKIT_ROOT}}`, `{{SDD_ROOT}}`, `{{GUARDRAILS_PATH}}`); shared `code-guidelines` + architecture selection (A/B/C, one-style load); **41** skills + `_shared` (agent SoT via `help-skills` → `skills-catalog/CATALOG.md` + `OPERATOR.md`) |
| **Adapters** | Map core → agent layout; merge hooks/settings safely; keyed uninstall (all registered adapters); Publish honesty (inherit/depth/threads); TRACE emitters per adapter honesty matrix |
| **CLI** | Select agent; sync / validate / list / uninstall |
| **Validation** | Contract suite + fixture smokes; inventory / preflight / TRACE harvest scripts; CI never requires `%USERPROFILE%` |

## Workflow for operators

1. **Release bootstrap** (recommended): HTTPS zip → SHA256 → extract → `toolkit.ps1` — [INSTALL.md § 0](INSTALL.md#0-release-bootstrap-https--checksum--toolkit); no `gh` / Node / bootstrap `.exe`. Or **clone** the repo for option 1 / 2+.
2. **Option 1 — interactive:** `pwsh -NoProfile -File .\scripts\toolkit.ps1` (Sync wizard). **Option 2+ — scripting/CI:** `toolkit.ps1 -Action Sync -Agent <id>` or `sync-agent.ps1 -Agent <id>`. Live home needs `-AllowUserHome`. Codex defaults to **plugin-only**; add `-UserScope` only when you need the USER skills mirror (see [ADAPTERS.md](ADAPTERS.md) § Codex).
3. **Validate** with `validate-core.ps1` and/or `Invoke-*CiSmoke.ps1` (e.g. `validate-agent.ps1 -Agent codex` against the fixture). Optional ops: memory-bank inventory, PRD/PLAN/CHANGE preflight, TRACE harvest; authorship git-notes only via opt-in script (default off — never TRACE SoT).
4. **Use skills** in the agent (e.g. `help-skills` → `CATALOG.md` + `OPERATOR.md` for the installed map of **41** skills including `framework-upgrade`; parallel specialists are the **router default** after sync — see [SPAWN.md](SPAWN.md); language surfaces: `core/skills/_shared/agents/LANGUAGE.md`; `sdd-spec` after sync; ops: `commit` → `push` → `open-github-pr`).

See [INSTALL.md](INSTALL.md), [VALIDATION.md](VALIDATION.md), [SKILLS.md](SKILLS.md), [guides/02-using-skills.md](guides/02-using-skills.md), [guides/09-authorship-git-notes.md](guides/09-authorship-git-notes.md).

## Domains

| Domain | Doc | What you learn |
|--------|-----|----------------|
| Core | [domains/core.md](domains/core.md) | Skills tree, policy, router, SDD contracts (tracks, REQ/validate/CHANGE/EVD/STATE/TRACE, navigation `## Related`, readiness B/I, invocation/provenance, PLAN-LEDGER + session gate, `read-sdd-artifact`, repository vs global storage); shared guidelines + architecture selection (A/B/C) |
| Git ops | [domains/git-ops.md](domains/git-ops.md) | `/commit` (living-artifacts) → `/push` → `/open-github-pr` (feature **squash** / release **rebase**); code-review recommended loop; branch rules |
| Adapters | [domains/adapters.md](domains/adapters.md) | Registry, publish surfaces (incl. Codex dual-root, Hermes, OpenHands), Publish knobs honesty, TRACE emitter matrix, Shell allowlist tip |
| CLI | [domains/cli-scripts.md](domains/cli-scripts.md) | toolkit / sync / validate; inventory (portable paths), session gate, readiness, preflight, TRACE harvest |
| Validation & CI | [domains/validation-ci.md](domains/validation-ci.md) | Fixtures, smokes, WS1/3/7/10 asserts, workflow |

Related deep docs: [ARCHITECTURE.md](ARCHITECTURE.md), [ADAPTERS.md](ADAPTERS.md), [guides/02-using-skills.md](guides/02-using-skills.md).

## Maturity surfaces (feature 006)

Same skill call flow as before — additional contracts and ops scripts, not a second toolkit:

| Surface | Role (paths under `core/` or `scripts/` after sync) | Domain detail |
|---------|------------------------------------------------------|---------------|
| **Invocation / provenance / language** | `INVOCATION-CONTEXTS.md` (`direct` vs `orchestrated`); `CONTRACT-PROVENANCE.md` (`agreed` vs `invented`); `LANGUAGE.md` + spawn model lock | [Invocation](domains/core.md#invocation-contexts-direct-vs-orchestrated) · [Provenance](domains/core.md#contract-provenance-agreed-vs-invented) · [Language / spawn](domains/core.md#language-surfaces-and-spawn-lock) |
| **Normalized artifact read** | Skill `read-sdd-artifact` → `source_context` envelope for FEATURE/STORY/PRD/PLAN under `features/` | [`read-sdd-artifact`](domains/core.md#skill-read-sdd-artifact-source_context) |
| **PLAN-LEDGER** | Atomic step claim contract + `sdd-plan` / `orchestrate-develop` refs | [PLAN-LEDGER](domains/core.md#plan-ledger--develop-session-gate) |
| **Operator TRACE / inventory / preflight** | `TRACE-ARCHIVE-CONTRACT.md`; harvest script; memory-bank inventory (`ready`\|`not-ready`, portable paths); PRD/PLAN/CHANGE preflight | [TRACE](domains/core.md#trace-archive-living-loop) · [cli-scripts](domains/cli-scripts.md#operator-workflow-inventory--preflight--develop--harvest) · [VALIDATION](VALIDATION.md#operator-scripts-pointers) |
| **Develop session + ledger** | `Invoke-DevelopSessionGate.ps1` + `Invoke-PlanLedgerClaim.ps1` (MUST `-File`; opt-in Shell allowlist) | [Session gate](domains/core.md#plan-ledger--develop-session-gate) · [allowlist](domains/cli-scripts.md#shell-allowlist-tip-ws10--req-013) |
| **Clarification readiness** | `readiness-severity.md` B/I/MINOR → READY \| NEEDS_CLARIFICATION; SiblingReadinessGate | [Readiness](domains/core.md#clarification-readiness-b--i--minor) |
| **Navigation `## Related`** | Portable sibling links; `Assert-NavigationBlock.ps1` | [Navigation](domains/core.md#navigation-block-related) |
| **Invocation axes / Publish honesty** | Axis B omit/inherit (`SUBAGENT-MODEL`); PublishSpawnKnobs; `Assert-InvocationAxes.ps1` | [SPAWN](SPAWN.md) · [Publish knobs](domains/adapters.md#publish-knobs-honesty-depth--threads--inherit) |
| **Composable skills** | Phased splits; `refine-story` modes (`feature` / `tech` / `split`); agnostic `api-standards` | [Composable skills](domains/core.md#composable-skills-lazy-refs-mode-playbooks) · [SKILLS Backlog Refine](SKILLS.md#backlog-refine) · [Using skills](guides/02-using-skills.md#backlog-refine--modes--checklist) |
| **Product artifact quality** | `_shared/backlog-item-types/` (INVEST, anti-task-shatter, Gherkin budget) wired into analyze / refine / split / spec | [Product artifact quality](domains/core.md#product-artifact-quality-backlog-item-types) |
| **Publish honesty** | Adapter Publish knobs (inherit/depth/threads); TRACE emitters claimed only where wired | [Publish knobs](domains/adapters.md#publish-knobs-honesty-depth--threads--inherit) · [TRACE emitters](domains/adapters.md#trace-emitter-honesty) |
| **Post-delivery handoffs** | `/commit` living-artifacts ask; `/code-review` recommended loop; `document-plan` Kind new vs update | [git-ops](domains/git-ops.md) · [SKILLS](SKILLS.md) |

## Feature 008 surfaces (remaining)

Same call flow — additional install/ops paths and one catalog skill, not a second toolkit:

| Surface | Role | Detail |
|---------|------|--------|
| **Release bootstrap** | `scripts/bootstrap/*` — HTTPS zip → SHA256 → extract → `toolkit.ps1` | [INSTALL § 0](INSTALL.md#0-release-bootstrap-https--checksum--toolkit) · [getting started](guides/01-getting-started.md) |
| **`framework-upgrade`** | Generic orchestrator (`audit`\|`plan`\|`migrate`\|`validate`); pluggable packs; skill id must not pin a major | [SKILLS](SKILLS.md) · catalog via `help-skills` |
| **Authorship git-notes** | `Invoke-AuthorshipGitNotes.ps1` **opt-in / default off**; parallel to TRACE; never SoT | [Guide 09](guides/09-authorship-git-notes.md) · [TRACE](domains/core.md#trace-archive-living-loop) |
| **PR merge policy** | `open-github-pr`: feature → `develop` = **squash**; release `develop` → `main`/`master` = **rebase** | [git-ops](domains/git-ops.md) |

## Design constraints

- **Fail closed on home:** paths under the user profile need `-AllowUserHome`.
- **Fixture-first CI:** smokes use `scripts/validation/fixtures/…`.
- **Keyed uninstall:** remove toolkit-managed artifacts only for all registered adapters. Preserves `sdd/sessions` and `sdd/manifest.json`.
- **Sync prepare:** every sync runs `Get-SddRoot -Prepare` (`sdd/sessions/` + seed `manifest.json` when absent; seed never overwrites). Manifest schema v2; storage modes and work tracks in [domains/core.md](domains/core.md) § SDD / [STORAGE.md](../core/sdd/STORAGE.md).
- **Same skill call flow:** Classic SDD / Backlog Refine / Orchestrated Delivery add internal gates and artifacts (REQ, validate scripts, CHANGE, EVD, STATE, TRACE, selective retrieval, skill lazy-load, invocation/provenance, PLAN-LEDGER) — not new slash tracks or a second toolkit. SQLite/FTS remains out of scope as a deliverable.
- **Authorship notes ≠ TRACE:** optional `refs/notes/toolkit-authorship` is opt-in and must not replace `features/NNN-slug/TRACE.jsonl`.
- **Bootstrap honesty:** Release zip path uses HTTPS + SHA256 before extract; asset names are parameters/env — not permanent script SoT.
- **Honest capabilities:** registry / `Get-Capabilities` flags and TRACE emitter claims reflect real publish support (see adapter honesty docs) — do not claim hooks or emitters the adapter does not wire.
- **Path/secrets guards:** native pre-tool deny via shared `adapters/_shared/GuardCommon.ps1` — see [ADAPTERS.md](ADAPTERS.md) § Shared path/secrets guard.
- **Codex dual-root:** plugin skills + CATALOG live under `InstallRoot/plugin`; Publish-Policy writes `InstallRoot/rules`; product/AGENTS/hooks parent is InstallRoot (live `~/.codex`). Optional `-UserScope` mirrors skills to fixture `InstallRoot/.agents/skills` or live `~/.agents/skills` — default sync is **plugin-only**. Do not treat skills and rules as one shared TOOLKIT_ROOT.

## Navigation

- [Documentation index](README.md)
- [Getting started](guides/01-getting-started.md)
- [Using skills](guides/02-using-skills.md)
- [Caveman mode](guides/07-caveman-mode.md)
- [Orchestrator mode](guides/08-orchestrator-mode.md)
- [Credits](CREDITS.md)
- [Spawn / subagents](SPAWN.md)
- Language surfaces: `core/skills/_shared/agents/LANGUAGE.md`
- [Guides hub](guides/README.md)
