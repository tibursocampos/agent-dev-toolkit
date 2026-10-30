---
name: framework-upgrade
description: Generic framework upgrade orchestrator (audit|plan|migrate|validate) with pluggable packs. Use when upgrading a framework version or invoking /framework-upgrade.
---

## STOP - Read before ANY tool call

Read `_shared/skill-boilerplate.md` first. It holds the guardrails read, the session gate rule, the user `sim` rule, the one-step rule, the gate check, and the user chat language rule. The steps below are skill-specific only.

1. After **ONE** upgrade session outcome (or explicit stop): **STOP** - handoff only; do not chain unrelated skills
---

# Skill: framework-upgrade

## Identity (stable)

| Field | Value |
|-------|--------|
| **Skill id** | `framework-upgrade` |
| **Slash** | `/framework-upgrade` |
| **Major pin** | **Forbidden** — never rename to `dotnet10-upgrade`, `angular-v*-upgrade`, or `framework-upgrade-vN` |

Version targets are **parameters** of the resolved pack (`currentVersion` → `targetVersion`), not part of this skill id.

## Trigger
**Negative signal:** applies as defined in `_shared/skill-boilerplate.md`; the skill-specific signals are listed below.

Invoke when the user asks for: `/framework-upgrade`, `framework upgrade`, `upgrade Angular/.NET/…`, or an explicit mode (`audit` / `plan` / `migrate` / `validate`).

## Outcome

1. Resolve `framework_id` via `references/detect.md` (TE03: 0 or >1 candidates → ask; packs own signals in `PACK.md`).
2. Load **one** mode contract from `references/modes.md` (`audit` \| `plan` \| `validate` \| `migrate`).
3. Validate versions / `supported_range` (`version-policy.md`); out of range → `research-protocol.md` (TE04 — no inventing local deltas).
4. Progressive-load shared + pack refs (never wholesale dump).
5. Record decisions in the decision register when planning or migrating.
6. Apply evidence gates before claiming migrate/validate done.
7. Honor Skip **D** and **silence ≠ approval** for migrate.

**Packs** live under `packs/` (`REGISTRY.md` + `packs/<id>/PACK.md`). Must packs `angular` and `dotnet` are on-disk. This skill orchestrates; packs provide detect, `supported_range`, and curated deltas.

## Required input

| Input | Rule |
|-------|------|
| Mode | Explicit or ask once: `audit` \| `plan` \| `migrate` \| `validate` — default ask; never silent `migrate` |
| `framework_id` | `references/detect.md` — detect or ask if 0 / >1 candidates; pack signals in `PACK.md` |
| `currentVersion` / `targetVersion` | Semantic per pack; `target > current`; outside `supported_range` → research |
| Operator **sim** | **Required** before any file-mutating migrate step; silence ≠ approval |

## Lazy-load (only when needed)

| When | Path (after syncing the active adapter) |
|------|----------------------------------------|
| Command playbook (after gates) | `{{TOOLKIT_ROOT}}/skills/framework-upgrade/references/command.md` |
| Modes contract | `{{TOOLKIT_ROOT}}/skills/framework-upgrade/references/modes.md` |
| Progressive load / SR-NO-FULL-DUMP | `{{TOOLKIT_ROOT}}/skills/framework-upgrade/references/progressive-load.md` |
| Decision register | `{{TOOLKIT_ROOT}}/skills/framework-upgrade/references/decision-register.md` |
| Evidence gates | `{{TOOLKIT_ROOT}}/skills/framework-upgrade/references/evidence.md` |
| Detect / `framework_id` | `{{TOOLKIT_ROOT}}/skills/framework-upgrade/references/detect.md` |
| Version policy | `{{TOOLKIT_ROOT}}/skills/framework-upgrade/references/version-policy.md` |
| Research protocol (out of range / TE04) | `{{TOOLKIT_ROOT}}/skills/framework-upgrade/references/research-protocol.md` |
| Sources catalog (normative vs auxiliary; RN08) | `{{TOOLKIT_ROOT}}/skills/framework-upgrade/references/sources-catalog.md` |
| Skip D (OOS brands / duration) | `{{TOOLKIT_ROOT}}/skills/framework-upgrade/references/skip-policy.md` |
| Selective retrieval companion | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/SELECTIVE-RETRIEVAL.md` |
| Pack registry (when present) | `{{TOOLKIT_ROOT}}/skills/framework-upgrade/packs/REGISTRY.md` |
| Pack body (when resolved) | `{{TOOLKIT_ROOT}}/skills/framework-upgrade/packs/<id>/PACK.md` + **one** pack `references/<section>.md` |
| Caveman Mode (if active) | `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md` - **Full cap** |
| Reference index (routing only) | `{{TOOLKIT_ROOT}}/skills/framework-upgrade/reference.md` |

**Never by default:** do not preload all `references/*.md`, all pack corpora, or `_shared/*-guidelines` wholesale. Load **one** section file per Process step (`SKILL-REFERENCE-RETRIEVAL.md` / `SR-NO-FULL-DUMP`).

## Reference routing

| Situation | Path |
|-----------|------|
| Step discovery after gates | `references/command.md` |
| Mode selection / contracts | `references/modes.md` |
| What to load next | `references/progressive-load.md` |
| Record / show decisions | `references/decision-register.md` |
| Before claiming done | `references/evidence.md` |
| Detect / ambiguous framework | `references/detect.md` |
| Version pair / range | `references/version-policy.md` |
| Target outside `supported_range` | `references/research-protocol.md` |
| Official vs auxiliary sources | `references/sources-catalog.md` |
| OOS / Skip D / duration ban | `references/skip-policy.md` |
| Pack resolve | `packs/REGISTRY.md` → `packs/<id>/PACK.md` |

## Process

After gates: **Read `references/command.md`**. Then load **one** `references/<section>.md` for the current step — never dump all refs.

### Step -1b - Caveman Mode (Full cap)

Apply Full caveman prefs when active.

### 1. Resolve mode

Load `references/modes.md`. If mode omitted: ask once. If caller implies implement/migrate without **sim**: stay in `audit` or `plan`.

### 2. Resolve pack + versions

1. Load `references/detect.md` — resolve `framework_id` (TE03: ask if 0 or >1 candidates; no silent default).
2. Load `references/version-policy.md` — validate `target > current` when versions apply.
3. If outside pack `supported_range` → `references/research-protocol.md` (reuses `sources-catalog.md` official first; TE04 STOP — do not invent local deltas).

### 3. Progressive load

Load `references/progressive-load.md`. Pull only the shared + pack sections needed for the active mode.

### 4. Execute mode

| Mode | Behavior |
|------|----------|
| `audit` | Inventory / gaps; no mutating writes |
| `plan` | Ordered baby steps + decision register; no mutate unless operator later says migrate + **sim** |
| `migrate` | Apply plan steps **only after explicit sim**; register each decision; evidence before next hop |
| `validate` | Build/test/gates per pack; evidence matrix; no silent promote to migrate |

### 5. Evidence + register

Load `references/evidence.md` and `references/decision-register.md` when claiming plan/migrate/validate outcomes.

### 6. Report

Summarize mode, pack, versions, decisions, evidence level, and next mode or stop. Offer `/commit` when files changed — do not auto-commit.

## Must not

- Rename skill id to a major-pinned id (`dotnet10-upgrade`, `angular-v*-upgrade`, `framework-upgrade-vN`)
- Enter `migrate` on silence, implied consent, or plan-only chat
- tracker work-item mutate, org-only prefixed contracts, external product brand in this skill/packs (Skip **D** / RN05)
- Duration / effort / story-point checkpoints
- Dump wholesale pack / guideline corpora into context
- Invent pack deltas for majors outside `supported_range` — research protocol + pack PR only; no in-session invented support
- Assume `framework_id` when 0 or >1 detect candidates
- Treat blogs/gists or offline snapshots as SoT when they conflict with official docs (RN08 — official wins; see `sources-catalog.md` + research checklist)
- Create sibling skills per framework — new frameworks = new **packs** only

## Handoff

| Situation | Next |
|-----------|------|
| Pack missing | Wait for `packs/<id>/` (registry) — orchestrator stays generic |
| Out of range | Research protocol → extend pack PR; no new skill id |
| Migrate done | `validate` mode or `/commit` |
| Review | `/code-review` when operator requests |
