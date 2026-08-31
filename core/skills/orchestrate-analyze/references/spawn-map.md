## Flag -> specialist mapping

**Canonical source:** `skills/_shared/agents/ROSTER.md` (`needs_*` table). Keep this section as a short pointer - edit ROSTER when the map changes.

Spawn Task **only** when `subagents=native` **and** ROSTER says so (`SPAWN.md`). If `subagents=none` or Task unavailable → **fallback** **in-parent write** to `ANALYSIS/` / `ARCH/` / `SEC/` (never skip; never CONTINUITY substitute for those flags). Parallelize when multiple specialists apply; concurrent Task cap **≤4** per `SPAWN.md`. Brownfield / impact-unclear -> `repo_analyst` **and** `architect` (mirror ARCH; skip style re-pick only) + `database` when persistence is in scope. Greenfield / no established style -> spawn `architect` and run **Architecture confirm gate**. ARCH is **not** optional when `needs_domain` or brownfield. Optional stage notes: `impact` / `risk` / `generate-story` prompts.

**Stacks are not roster roles** - do not spawn `react`/`dotnet` agents in O1. Route implementation later via `ROUTING.md`.

**Must not (specialists):** app code; org-only tooling unless the repo already uses it; invent APIs; expand to 40 agent files. `qa_checklist` = CONTINUITY/STORY only (no Task).

---

## Process — Spawn Task specialists

**SPAWN first:** load `SPAWN.md`; consult capability `subagents` (`native` \| `none`). Prefer Task when `native`; if `subagents=none` or Task unavailable → **fallback** **in-parent write** to `ANALYSIS/` / `ARCH/` / `SEC/` — **never skip** required folders; never substitute a CONTINUITY handoff note for `needs_api` / `needs_domain` / `needs_database` / `needs_security` / brownfield. Never hard-fail for missing Task. Concurrent Task cap **≤4** per `SPAWN.md` (wave if more; do not invent a new cap). `needs_frontend` / `needs_devops` stay CONTINUITY-only (no Task).

Spawn a Task subagent **only** when `subagents=native` **and** `ROSTER.md` canonical `needs_*` / brownfield rules say so. Load prompt from `skills/_shared/agents/prompts/`. When multiple specialists apply, spawn **in parallel** within the SPAWN ≤4 cap; if more flags apply, batch in waves of ≤4 or ask (pt-BR) to run série.

**Model (`SUBAGENT-MODEL.md`):** omit Task `model` by default (inherit parent / Auto). Ask about a premium slug **only** for very hard work per that contract; on **não** / silence, spawn without `model`. Never pick a costlier model alone.

| Signal (see ROSTER) | Specialist | Prompt |
|---------------------|------------|--------|
| `needs_api` or brownfield / impact unclear | `repo_analyst` → `ANALYSIS/` | `prompts/repo_analyst.md` |
| `needs_domain`, contract-heavy API, **greenfield**, or **brownfield** (mirror; skip style re-pick only) | `architect` → `ARCH/` | `prompts/architect.md` |
| `needs_database` or brownfield with persistence | `database` → `ARCH/` DB slice | `prompts/database.md` |
| `needs_security` | `security` → `SEC/` | `prompts/security.md` |
| `needs_frontend` | *(no O1 specialist)* - CONTINUITY note only; route at implement via `ROUTING.md` |
| `needs_devops` | short CONTINUITY note only (no Task) | - |
| Story drafting aid | use `generate-story` patterns | `prompts/generate-story.md` |
| Optional stage notes | `impact` / `risk` | `prompts/impact.md`, `prompts/risk.md` |

Parent keeps lean context: synthesis + paths. Specialists must **not** write app code. Do **not** call `*-developer` to implement. `qa_checklist` is CONTINUITY/STORY only - never spawn a Task for it.

See also § Flag -> specialist mapping.
