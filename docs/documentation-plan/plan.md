# Documentation plan: agent-dev-toolkit

| Field | Value |
|-------|--------|
| **Repository** | agent-dev-toolkit (`E:/Source/Repos/agent-dev-toolkit`) |
| **Doc language** | English |
| **Stack detected** | PowerShell 5.1 scripts (`scripts/toolkit.ps1`, adapters), Markdown Agent Skills (`core/skills`), JSON adapter registry. GitHub Actions: `validate-toolkit.yml`, `publish-release-bootstrap.yml`, `enforce-release-source.yml`. `.github/workflows/docs.yml` exists and is out of scope. |
| **Overview** | docs/overview.md (refreshed in this planning session; no step rewrites it) |
| **Progress** | 7/7 (fact fixes). Operator narrative is [sessions/README.md](../sessions/README.md). `guides/07-caveman-mode.md` was removed; compression is one section of [guides/session-behavior.md](../guides/session-behavior.md). |

```
[🟢🟢🟢🟢🟢🟢🟢] 100% (7/7)
```

## Goals

- [x] G1: English, RAG-ready docs for architecture, skills/tracks, adapters/spawn, install/CLI, validation/CI, operator guides, and root governance
- [x] G2: Reuse existing markdown: correct drifted facts, delete the stale CI duplicate, leave accurate files untouched
- [x] G3: Facts evidenced from `core/`, `adapters/registry.json`, `scripts/`, and the workflows above

**Out of scope for every step:** `docs-site/`, `site/`, `memory-bank/`, `core/`, `adapters/`, `scripts/`, and any MkDocs or `*.pt.md` work. Do not delete `core/policy/user-language-pt-br.md` or `core/policy/sdd-artifact-language-pt-br.md`.

## Target doc tree (consumer repo)

```
docs/
├── overview.md
├── README.md
├── ARCHITECTURE.md
├── SKILLS.md
├── ADAPTERS.md
├── SPAWN.md
├── INSTALL.md
├── VALIDATION.md
├── CREDITS.md
├── REPO_GOVERNANCE.md
├── DESIGN-BRIEF.md          # leave untouched (site brief)
├── documentation-plan/
│   └── plan.md
├── guides/
│   ├── README.md
│   ├── 01-getting-started.md
│   ├── 02-using-skills.md
│   ├── session-behavior.md
│   ├── 08-orchestrator-mode.md
│   └── 09-authorship-git-notes.md
└── domains/
    ├── core.md
    ├── adapters.md
    ├── cli-scripts.md
    └── git-ops.md
```

`docs/domains/validation-ci.md` is removed in STEP 5 (stale duplicate of `VALIDATION.md`).

## Reuse classification

| Path | Class | Why |
|------|--------|-----|
| `README.md` | keep-and-correct | Says CI runs on push/PR; `validate-toolkit.yml` is `pull_request` only |
| `PRODUCT.md` | leave-untouched | Site brief; no toolkit-fact leak into README or overview |
| `SECURITY.md` | leave-untouched | Reporting policy matches CONTRIBUTING |
| `CONTRIBUTING.md` | keep-and-correct | Required check named `validate`; workflow gate is `ci-ok` |
| `docs/README.md` | keep-and-correct | Index still lists `domains/validation-ci.md` |
| `docs/overview.md` | keep-and-correct | Replaced in this planning session (no feature-id sections, no site) |
| `docs/INSTALL.md` | leave-untouched | Already states AllowUserHome, Copilot `-Mode`, Codex `-UserScope`, keyed uninstall, Backup stub |
| `docs/SKILLS.md` | keep-and-correct | Does not state that tracks are not prerequisites |
| `docs/VALIDATION.md` | keep-and-correct | Job table is right; absorb unique assert/local-parity detail from the domain file and state the trigger |
| `docs/ARCHITECTURE.md` | keep-and-correct | Layers and CI section say push/PR and Windows-only |
| `docs/ADAPTERS.md` | keep-and-correct | Add declared `subagents` column; registry flags already match |
| `docs/SPAWN.md` | keep-and-correct | Says OpenCode and Grok skip Publish-Agents (`agents=false`); registry has `agents: true` for both |
| `docs/CREDITS.md` | leave-untouched | Matches Caveman / Impeccable / Spec Kit boundaries in core |
| `docs/REPO_GOVERNANCE.md` | keep-and-correct | Audience map should name the `ci-ok` check |
| `docs/DESIGN-BRIEF.md` | leave-untouched | Site brief; do not expand the site |
| `docs/guides/README.md` | keep-and-correct | Decision tree should state tracks are recommendations, not prerequisites |
| `docs/guides/01-getting-started.md` | leave-untouched | First skill is `/sdd-spec`; greenfield line says prefer, not must |
| `docs/guides/02-using-skills.md` | leave-untouched | Invoke matrix matches `core/router/AGENTS.md` |
| `docs/guides/07-caveman-mode.md` | removed | Folded into `guides/session-behavior.md` |
| `docs/guides/08-orchestrator-mode.md` | keep-and-correct | Default `preferences.json` example omits `verify_mode` |
| `docs/guides/09-authorship-git-notes.md` | leave-untouched | Opt-in notes beside TRACE |
| `docs/domains/core.md` | keep-and-correct | Folder table puts Backlog Refine skills under Ops; language section omits the pt-BR policy-file trade-off |
| `docs/domains/adapters.md` | leave-untouched | Summary matches registry, keyed uninstall, Backup stub, Copilot mode, Codex `-UserScope` |
| `docs/domains/cli-scripts.md` | keep-and-correct | Omits `-UserScope` and `Publish-Agents`; says validate-agent always runs core (`-SkipCore` exists) |
| `docs/domains/git-ops.md` | leave-untouched | Squash feature PRs and rebase release PRs match `open-github-pr` |
| `docs/domains/validation-ci.md` | delete | CI section says `windows-latest` only and push/PR; `VALIDATION.md` already has both jobs and `ci-ok` |

---

## Implementation steps

### ✅ STEP 1: Architecture

**Status:** Completed | **Completed:** 2026-09-25 | **Deps:** none | **Est.:** 35 min

**Deliverables:**
- [x] Edit `docs/ARCHITECTURE.md` — layers table and `## CI`: `pull_request` to `master`, `main`, `develop`; jobs `validate` (windows), `validate-ubuntu`, gate `ci-ok`; name `publish-release-bootstrap.yml` and `enforce-release-source.yml`; one sentence that `.github/workflows/docs.yml` exists and is not part of this guide. Point CI detail at `docs/VALIDATION.md` only (drop the `domains/validation-ci.md` link). Keep per-agent install layouts.

**Tasks:**
1. Read `.github/workflows/validate-toolkit.yml`, `publish-release-bootstrap.yml`, and `enforce-release-source.yml`.
2. Rewrite the CI sentences that say push/PR or Windows-only.
3. Write in **English**. Paths and job names stay as in the YAML.

**Acceptance:**
- [x] A reader can name the three toolkit workflows and the `ci-ok` gate without opening the YAML
- [x] No `docs-site/` or feature-id sections added

**Implementation notes:**
- Layers table and `## CI` now match `validate-toolkit.yml` (`pull_request` to `master`, `main`, `develop`; jobs `validate`, `validate-ubuntu`, gate `ci-ok`) and name `publish-release-bootstrap.yml` and `enforce-release-source.yml`. One sentence states `.github/workflows/docs.yml` exists and is not part of this guide. CI detail points at `docs/VALIDATION.md` only.

---

### ✅ STEP 2: Skills and tracks

**Status:** Completed | **Completed:** 2026-09-25 | **Deps:** none | **Est.:** 40 min

**Deliverables:**
- [x] Edit `docs/SKILLS.md` — under Work tracks, state that Classic SDD, Backlog Refine, and Orchestrated Delivery are recommendations and not prerequisites of each other (operator may start at `/sdd-spec` or `/sdd-plan`).
- [x] Edit `docs/domains/core.md` — folder table: `refine-story` and `split-story-checklist` under Backlog Refine, not Ops. In the language section, name `core/policy/user-language-pt-br.md` and `core/policy/sdd-artifact-language-pt-br.md` as shipped pt-BR install defaults and point the surface SoT at `core/skills/_shared/agents/LANGUAGE.md` (chat follows the user; spawn/receipts stay en-US). Do not delete those policy files.

**Tasks:**
1. Re-count `name:` in `core/skills/*/SKILL.md` (expect 41) and keep the catalog tables aligned with `CATALOG.md`.
2. Read `core/skills/_shared/agents/LANGUAGE.md` and the two policy files before editing the language section.
3. Write in **English**.

**Acceptance:**
- [x] Skill count stays **41**
- [x] Tracks are described as coexisting recommendations
- [x] Policy files are explained, not scheduled for deletion

**Implementation notes:**
- Re-counted `name:` in `core/skills/*/SKILL.md`: 41 unique skill ids. Catalog tables in `docs/SKILLS.md` already matched `core/skills/_shared/skills-catalog/CATALOG.md` (same 41 ids, same track grouping). Count left at 41.
- `docs/SKILLS.md` Work tracks now states Classic SDD, Backlog Refine, and Orchestrated Delivery are recommendations and not prerequisites of each other; operator may start at `/sdd-spec` or `/sdd-plan`.
- `docs/domains/core.md` folder table: `refine-story` and `split-story-checklist` moved to Backlog Refine. Language section names both policy files as shipped pt-BR install defaults and points the surface SoT at `core/skills/_shared/agents/LANGUAGE.md`. Policy files were not deleted.

---

### ✅ STEP 3: Adapters and spawn

**Status:** Completed | **Completed:** 2026-09-25 | **Deps:** none | **Est.:** 30 min

**Deliverables:**
- [x] Edit `docs/ADAPTERS.md` — honesty matrix gains a `subagents` column from `adapters/registry.json` (OpenHands `none`; other nine declared `native`). Keep the Antigravity effective-probe paragraph (declared vs effective).
- [x] Edit `docs/SPAWN.md` — specialists section: `agents: true` publish for OpenCode and Grok (`Publish-Agents` → `InstallRoot/agents/`). `agents: false` remains Antigravity and Hermes. OpenHands still `subagents=none` with roster files under `.agents/agents/`.

**Tasks:**
1. Diff the capability table against `adapters/registry.json`.
2. Diff the Antigravity probe list against `core/skills/_shared/agents/SPAWN.md` (override → product version ≥ 2.0.0 → `agy --version` ≥ 1.0.0 as harness proxy → else `none`).
3. Write in **English**. Do not edit `docs/domains/adapters.md` (already aligned).

**Acceptance:**
- [x] OpenCode and Grok are not described as `agents=false`
- [x] OpenHands remains the only declared `subagents=none`
- [x] Probe order matches the core SPAWN contract

**Implementation notes:**
- Honesty matrix `subagents` column matches `adapters/registry.json`: declared `native` for cursor, antigravity, claude, codex, copilot, opencode, grok, zcode, hermes; `none` only for openhands. Antigravity declared-vs-effective paragraph kept. Probe order: `ADT_ANTIGRAVITY_SUBAGENTS` override → product version `>= 2.0.0` → `agy --version` `>= 1.0.0` as 2.0 harness proxy → else `none`.
- `docs/SPAWN.md` specialists: OpenCode and Grok `agents: true` (`Publish-Agents` → `InstallRoot/agents/`). Antigravity and Hermes stay `agents: false`. OpenHands stays `subagents=none` with roster files under `.agents/agents/`. `docs/domains/adapters.md` was not edited.

---

### ✅ STEP 4: Install and CLI

**Status:** Completed | **Completed:** 2026-09-25 | **Deps:** none | **Est.:** 30 min

**Deliverables:**
- [x] Edit `docs/domains/cli-scripts.md` — `sync-agent.ps1` parameters include optional `-UserScope` (Codex); publish order includes `Publish-Agents`; `validate-agent.ps1` runs `validate-core` by default and skips it only with `-SkipCore`. Keep Backup as a non-interactive fail-closed stub and uninstall as keyed.

**Tasks:**
1. Read the `.SYNOPSIS` blocks of `scripts/toolkit.ps1`, `scripts/sync-agent.ps1`, and `scripts/validate-agent.ps1`.
2. Align the CLI domain page with those parameters. Do not rewrite `docs/INSTALL.md` (leave-untouched).
3. Write in **English**.

**Acceptance:**
- [x] Codex `-UserScope`, Copilot `-Mode user|repo`, and `-AllowUserHome` appear on the CLI page
- [x] Backup is still described as a stub that does not call an adapter

**Implementation notes:**
- `docs/domains/cli-scripts.md` now matches the three script synopses: optional `-UserScope` (Codex `Publish-Skills` mirror), publish order includes `Publish-Agents`, and `validate-agent.ps1` runs `validate-core` unless `-SkipCore`. Copilot `-Mode user|repo` and `-AllowUserHome` stay on the page. Backup remains the non-interactive fail-closed stub (`Invoke-ToolkitStubAction`; no adapter). Uninstall stays keyed via `Uninstall-Toolkit`. `docs/INSTALL.md` was not edited. The `validation-ci.md` link is left for STEP 5.

---

### ✅ STEP 5: Validation and CI

**Status:** Completed | **Completed:** 2026-09-25 | **Deps:** 1 | **Est.:** 40 min

**Deliverables:**
- [x] Edit `docs/VALIDATION.md` — state trigger `pull_request` to `master`, `main`, `develop` (no push). Keep jobs `validate`, `validate-ubuntu`, and `ci-ok`. Fold any assert or local-parity detail that exists only in `docs/domains/validation-ci.md`. Name `publish-release-bootstrap.yml` and `enforce-release-source.yml`. One sentence: `.github/workflows/docs.yml` exists and this page does not document the site.
- [x] Delete `docs/domains/validation-ci.md`.
- [x] Edit `docs/README.md` — remove the `domains/validation-ci.md` row; validation readers go to `VALIDATION.md`.
- [x] Edit `docs/domains/cli-scripts.md` — replace the related link to `validation-ci.md` with `VALIDATION.md`.

**Tasks:**
1. Diff `docs/domains/validation-ci.md` against `docs/VALIDATION.md` and keep unique assert names.
2. Delete the domain file only after those facts are in `VALIDATION.md`.
3. Grep `docs/` for `validation-ci` and fix remaining links (expect `ARCHITECTURE.md` already cleaned in STEP 1).
4. Write in **English**. Do not edit `.github/workflows/docs.yml`.

**Acceptance:**
- [x] No doc under `docs/` still links to `domains/validation-ci.md`
- [x] CI trigger and `ci-ok` match `validate-toolkit.yml`

**Implementation notes:**
- `docs/VALIDATION.md` now states `pull_request` to `master`, `main`, and `develop` (no push), keeps jobs `validate`, `validate-ubuntu`, and `ci-ok`, and names `publish-release-bootstrap.yml` and `enforce-release-source.yml`. Unique assert names and the local-parity command list from `docs/domains/validation-ci.md` were folded in before that file was deleted. `.github/workflows/docs.yml` is named as existing and not documented on this page.
- `docs/README.md` no longer lists `domains/validation-ci.md`; validation readers stay on `VALIDATION.md`. `docs/domains/cli-scripts.md` related links point at `VALIDATION.md` only. `docs/ARCHITECTURE.md` already pointed at `VALIDATION.md`.

---

### ✅ STEP 6: Operator guides

**Status:** Completed | **Completed:** 2026-09-25 | **Deps:** 2 | **Est.:** 30 min

**Deliverables:**
- [x] Edit `docs/guides/README.md` — work-tracks section: tracks are recommendations, not prerequisites (Classic SDD may start without `orchestrate-analyze`).
- [x] Edit `docs/guides/07-caveman-mode.md` — remove the Related links to `docs-site/caveman.md` and `docs-site/caveman.pt.md`. Keep the pointer to `docs/CREDITS.md` and `core` caveman policy.
- [x] Edit `docs/guides/08-orchestrator-mode.md` — default preferences example includes `verify_mode: false`, matching `scripts/_lib/Initialize-SddPreferences.ps1`.

**Tasks:**
1. Read `core/policy/caveman-mode.md`, `core/policy/orchestrator-session.md`, and `Initialize-SddPreferences.ps1`.
2. Leave `docs/guides/01-getting-started.md`, `docs/guides/02-using-skills.md`, and `docs/guides/09-authorship-git-notes.md` unchanged.
3. Write in **English**. Do not edit `docs-site/`.

**Acceptance:**
- [x] Guides no longer link into `docs-site/`
- [x] Default preferences JSON includes `verify_mode`
- [x] Track choice matches `core/router/AGENTS.md` operator track choice

**Implementation notes:**
- `docs/guides/README.md` work tracks now state that tracks are recommendations, never prerequisites. Classic SDD may start with `/sdd-spec` or `/sdd-plan` without `orchestrate-analyze`, matching `core/router/AGENTS.md` § Operator track choice.
- `docs/guides/07-caveman-mode.md` no longer links to `docs-site/caveman.md` or `docs-site/caveman.pt.md`. Credits stay on `docs/CREDITS.md`; the always-on policy pointer stays on published `caveman-mode`. The missing-file preferences example now includes `"verify_mode": false`, matching `core/policy/caveman-mode.md` and `scripts/_lib/Initialize-SddPreferences.ps1`.
- `docs/guides/08-orchestrator-mode.md` default preferences example now includes `"verify_mode": false` in the same field order as `New-ToolkitDefaultPreferencesObject`.

---

### ✅ STEP 7: Root governance

**Status:** Completed | **Completed:** 2026-09-25 | **Deps:** 5 | **Est.:** 30 min

**Deliverables:**
- [x] Edit `README.md` — CI sentence: `pull_request` to `develop` / `master` / `main`, not push. Mention jobs that feed `ci-ok`. Keep the 10-agent and 41-skill claims.
- [x] Edit `CONTRIBUTING.md` — required CI check is `ci-ok` (`.github/workflows/validate-toolkit.yml`), not the job name `validate` alone.
- [x] Edit `docs/REPO_GOVERNANCE.md` — maintainer row names the `ci-ok` check and `enforce-release-source.yml`.

**Tasks:**
1. Re-read `SECURITY.md` and `docs/CREDITS.md`. Leave both files unchanged.
2. Leave `PRODUCT.md` and `docs/DESIGN-BRIEF.md` unchanged.
3. Write in **English**.

**Acceptance:**
- [x] README, CONTRIBUTING, and REPO_GOVERNANCE agree on `pull_request` plus `ci-ok`
- [x] SECURITY, CREDITS, PRODUCT, and DESIGN-BRIEF are unmodified

**Implementation notes:**
- `README.md` Safety section now states CI runs on `pull_request` to `develop`, `master`, and `main` (not `push`). Jobs `validate` and `validate-ubuntu` feed `ci-ok`. Ten agent CI smokes and the Skills preview (41) claims stay; `adapters/registry.json` has 10 agents and `core/skills` has 41 `SKILL.md` files.
- `CONTRIBUTING.md` names the required check `ci-ok` in `.github/workflows/validate-toolkit.yml` and says branch protection must not require the job name `validate` alone.
- `docs/REPO_GOVERNANCE.md` maintainer row names `ci-ok` (`pull_request` to `develop`, `master`, and `main`) and `.github/workflows/enforce-release-source.yml`.
- `PRODUCT.md`, `SECURITY.md`, `docs/CREDITS.md`, and `docs/DESIGN-BRIEF.md` were read where required and left unmodified.

---

## Execution order

**Critical path:** 1 → 5 → 7. Steps 2, 3, and 4 may run in any order relative to step 1. Step 6 after step 2. Step 5 after step 1. Step 7 after step 5.

**Next step:** none (all steps complete). Handoff: `/code-review`

## Update protocol (document-implement skill)

After each completed step, `document-implement` updates this file: status, progress bar, **Next step** line, and checked deliverables. One step per session.
