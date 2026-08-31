# Portable agent roster (Orchestrated Delivery)

Shared prompts and roles for `orchestrate-*` Task subagents. **English** prompt bodies. Keep this roster small - do **not** add 40 agent files.

Install path after sync: `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/agents/`

**Spawn / degrade:** `SPAWN.md` (capability `subagents`, native vs fallback, child limits, no guideline paste). Do **not** duplicate that policy here.

**Task model policy:** `SUBAGENT-MODEL.md` (omit `model` by default; rare premium gate + user **sim**).

**Receipt:** `RECEIPT.md` (lazy-load when Caveman ON or child returns findings).

## Roster (maximum)

| Role id | When to spawn | Writes (under feature/story) | Must not |
|---------|---------------|------------------------------|----------|
| `repo_analyst` | Brownfield / impact unclear / `needs_api` | `ANALYSIS/` notes (**folder on disk**) | App code; invent APIs; CONTINUITY-only substitute |
| `architect` | `needs_domain`, cross-cutting design, **greenfield**, or **brownfield** (mirror) | `ARCH/` notes (**folder on disk**; draft until confirm on greenfield) | App code; corporate patterns; silent style default; final ARCH before operator **sim** on greenfield; skip ARCH on brownfield |
| `security` | `needs_security` | `SEC/` notes (**folder on disk**) | compliance theater; route findings to CONTINUITY instead of `SEC/` |
| `database` | `needs_database` or brownfield with persistence | `ARCH/` DB slice (**folder on disk**) | Force a vendor; corp DBA rules; CONTINUITY-only substitute |
| `qa_checklist` | Before handoff / review | Checklist bullets in CONTINUITY or STORY only | Write production tests silently; **no** Task spawn; **no** `prompts/qa*.md` file |

Stacks (`react`, `dotnet`, …) are **not** duplicated here - route via existing `*-developer` skills (`ROUTING.md`).

## Flags (`needs_*`) - canonical spawn map (O1 source of truth)

Set on `FEATURE.md` during O1 triage. Spawn a Task specialist **only** when the flag is **true**. `orchestrate-analyze` SKILL must point here - do not maintain a divergent table in the SKILL body.

| Flag | Spawn when true | Specialist / action | Prompt |
|------|-----------------|---------------------|--------|
| `needs_api` | API / package / integration surface | `repo_analyst` (+ `architect` if contract-heavy); **write `ANALYSIS/`** | `prompts/repo_analyst.md` (+ optionally `architect.md`) |
| (brownfield / impact unclear) | Nature `brownfield` or impact unclear | `repo_analyst` **and** `architect` (discover / **mirror ARCH**; skip style re-pick only) + `database` when persistence is in scope; folders on disk | `prompts/repo_analyst.md`, `prompts/architect.md`, `prompts/database.md` |
| (greenfield / no established style) | Nature `greenfield` **or** no in-repo architecture style | `architect` → **architecture-selection** propose + operator **confirm** before final ARCH; **write `ARCH/`** | `prompts/architect.md` + `code-guidelines/principles/architecture-selection.md` |
| `needs_domain` | Domain / cross-cutting design | `architect` (same confirm gate when style is not yet established); **write `ARCH/`** | `prompts/architect.md` |
| `needs_database` | Persistence / schema | `database`; **write `ARCH/` DB slice** | `prompts/database.md` |
| `needs_frontend` | UI work | No O1 Task - note in CONTINUITY only; route via `ROUTING.md` at implement | - |
| `needs_security` | Auth, secrets, PII, supply-chain, threat surface | `security`; **write `SEC/`** | `prompts/security.md` |
| `needs_devops` | Deploy / pipeline notes | Short CONTINUITY note only (no Task) | - |

**Folder on disk:** when a flag above is **true** (or nature is brownfield), spawn Task when `subagents=native`, else **in-parent write**. The matching story folder **must exist on disk** before backlog approval: `needs_api` / brownfield → `ANALYSIS/`; `needs_domain` / brownfield → `ARCH/`; `needs_database` → `ARCH/` (DB slice); `needs_security` → `SEC/`. Do **not** substitute a CONTINUITY handoff note for these flags. `needs_frontend` / `needs_devops` remain CONTINUITY-only (no Task, no specialist folder).

**Architecture confirm gate (greenfield / `needs_domain` without established style):** architect returns ARCH **draft** → parent asks operator (**sim** / ajustar / cancelar) → only on **sim** write ARCH **approved**. Until **sim**, treat receipt as `needs-confirm.` — silence is not approval. **Brownfield:** skip **style re-pick / style-id confirm gate** only. Still spawn `architect` and `database` (when persistence is in scope) and write a mirror ARCH slice (layers, DDL, EF vs Dapper or equivalent, pipeline).

**TE01 / security signals:** Prefer `false` for ambiguous flags **except** when auth, secrets, PII, feed tokens, or supply-chain appear in the description - then ask explicitly or set `needs_security=true` (do not default those signals to `false`).

## Triage

| Dimension | Values |
|-----------|--------|
| Nature | `greenfield` \| `brownfield` \| `operational` |
| Complexity | `trivial` \| `medium` \| `complex` |
| Scope | `backend` \| `frontend` \| `fullstack` |

| Complexity | Suggested path |
|------------|----------------|
| `trivial` | `developer` / stack skill (skip O1) |
| `medium` | Classic SDD or Backlog Refine |
| `complex` | Orchestrated Delivery O1 |

## Prompt files

| File | Use |
|------|-----|
| `prompts/repo_analyst.md` | Impact / brownfield map |
| `prompts/architect.md` | Solution shape; greenfield → architecture-selection + user confirm |
| `prompts/security.md` | Security subset review |
| `prompts/database.md` | Data model / migration risks |
| `prompts/impact.md` | Stage: impact summary |
| `prompts/risk.md` | Stage: risk register |
| `prompts/generate-story.md` | Stage: draft US/TS STORY.md |

`qa_checklist` has **no** prompt file - it is a CONTINUITY/STORY checklist role only (validators must not require `prompts/qa*.md`).

## Must not

- Port org-only tracker/IdP agents
- Create one file per aspirational design-md agent
- Let orchestrator parent implement application code
