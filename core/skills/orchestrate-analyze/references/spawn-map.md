## Flag -> specialist mapping

**Canonical source:** `skills/_shared/agents/ROSTER.md` (`needs_*` table). Keep this section as a short pointer - edit ROSTER when the map changes. That table owns the flag-to-role/prompt mapping, including brownfield pairing, required artifact folders, and greenfield architecture confirmation.

Spawn Agent **only** when `subagents=native` **and** ROSTER says so (`SPAWN.md`). If `subagents=none` or Agent unavailable → **fallback** **in-parent write** to `ANALYSIS/` / `ARCH/` / `SEC/` (never skip; never CONTINUITY substitute for those flags). Parallelize when multiple specialists apply; concurrent Agent cap **≤4** per `SPAWN.md`. Brownfield / impact-unclear -> `repo-analyst` **and** `architect` (mirror ARCH; skip style re-pick only) + `database` when persistence is in scope. Greenfield / no established style -> spawn `architect` and run **Architecture confirm gate**. ARCH is **not** optional when `needs_domain` or brownfield. Optional stage notes: `impact` / `risk` / `generate-story` prompts.

**Stacks are not roster roles** - do not spawn `react`/`dotnet` agents in O1. Route implementation later via `ROUTING.md`.

**Must not (specialists):** app code; org-only tooling unless the repo already uses it; invent APIs; expand to 40 agent files. `qa_checklist` = CONTINUITY/STORY only (no Agent).

---

## Process — Spawn Agent specialists

**SPAWN first:** load `SPAWN.md`; consult capability `subagents` (`native` \| `none`). Prefer Agent when `native`; if `subagents=none` or Agent unavailable → **fallback** **in-parent write** to `ANALYSIS/` / `ARCH/` / `SEC/` — **never skip** required folders; never substitute a CONTINUITY handoff note for `needs_api` / `needs_domain` / `needs_database` / `needs_security` / brownfield. Never hard-fail for missing Agent. Concurrent Agent cap **≤4** per `SPAWN.md` (wave if more; do not invent a new cap). `needs_frontend` / `needs_devops` stay CONTINUITY-only (no Agent).

Spawn an Agent subagent **only** when `subagents=native` **and** `ROSTER.md` canonical `needs_*` / brownfield rules say so. Load prompts from `skills/_shared/agents/prompts/`; follow the finding-block return shape in `refine-story/references/finding-format.md`. When multiple specialists apply, spawn in parallel within the SPAWN ≤4 cap; if more flags apply, batch in waves of ≤4 or ask in the user chat language to run série.

**Model configuration:** see `skills/_shared/agents/SUBAGENT-MODEL.md`.

| Signal | O1 action |
|--------|----------|
| `needs_*`, brownfield, or greenfield | Follow the canonical mapping and artifact requirements in `ROSTER.md`. |
| Story drafting aid | Use `generate-story` patterns: `prompts/generate-story.md`. |
| Optional stage notes | `impact` / `risk`: `prompts/impact.md`, `prompts/risk.md`. |

Parent keeps lean context: synthesis + paths. Specialists must **not** write app code. Do **not** call `*-developer` to implement. `qa_checklist` is CONTINUITY/STORY only - never spawn an Agent for it.

See also § Flag -> specialist mapping.
