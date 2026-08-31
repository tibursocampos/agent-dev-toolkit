## Boundaries vs O1 / sdd-* / O3

| Aspect | O1 `orchestrate-analyze` | O2 `orchestrate-deliver` | Classic SDD `sdd-spec`/`sdd-plan` | O3 `orchestrate-develop` |
|--------|--------------------------|--------------------------|-----------------------------------|--------------------------|
| Purpose | Triage + US/TS backlog | PRD+PLAN per approved story | One story PRD or PLAN | Implement PLAN steps |
| Input | Feature description | Approved `features/NNN-slug/` | Story/requirements | Approved PLAN paths |
| Output | FEATURE + CONTINUITY + STORY | PRD + PLAN per US/TS | Single PRD or PLAN | Code + PLAN checkboxes |
| Contracts | Specialists (`needs_*`) | **Reuses** sdd-spec / sdd-plan | Is the contract | **Reuses** sdd-develop |
| App code | No | No | No | Children only; parent no |

Escalate **to Classic SDD alone** when only one story and user skips O2 batching.

Escalate **to O1** when backlog not approved, stories missing, or flag-gated required siblings (`ANALYSIS/` / `ARCH/` / `SEC/`) are missing.

Do **not** claim `sdd-develop` one-step contract changed.

---

## Must not (full)

- Skip Step 0 Memory Bank Gate (unless explicit user `skip-memory-bank`)
- Create `memory-bank/` under `features/NNN-slug/` or replace CONTINUITY with bank body
- Dump entire memory-bank into parent or child prompts
- Write application/production code or tests (`*.cs`, `*.tsx`, `*.ts`, `*.js`, `*.vue`, `*.py`, migrations, etc.)
- Call `*-developer` / `developer` / `sdd-develop` / `orchestrate-develop` to **implement** (handoff strings only)
- Rewrite or fork the `sdd-spec` / `sdd-plan` process into a parallel undocumented flow
- Skip human approval or treat silence as `sim`
- Advance develop handoff when brownfield lacks `features/NNN-slug/CHANGE.md`, or when greenfield was forced an empty CHANGE stub
- Advance when FEATURE complexity is `medium`/`complex` and TASKS checklist is missing without operator **sim** deferral
- Write PRD/PLAN when FEATURE `needs_*` (or brownfield) is true and the story lacks matching `ANALYSIS/` / `ARCH/` / `SEC/` — **STOP** / return to O1; max-3 gap questions do not replace this gate
- Treat waive-deps as a waiver for missing `SEC/` / `ARCH/` / `ANALYSIS` (waive-deps is **story order** only)
- Exit O2 with Memory-bank status `fresh` if style changed or ARCH was approved this feature (set `refreshed`; point-promote `architecture.md` if not already)
- Write PRD/PLAN at repo root or outside the story folder
- Create external work-item tracker or org-only compliance content
- Change the `sdd-develop` one-step-per-session contract
- Create `REFINE/` / `ANALYSIS/` / `ARCH/` / `SEC/` / `PRD/` / `PLAN/` at **repo root**
- Assume série vs paralelo without asking
- Let parallel Task children `Write` PRD/PLAN to disk (parent-only writes after **sim**)
- Resolve feature paths outside `$Cwd/features/` or `<classic.path>/features/`, or accept `..` segments
- Require memory-bank for Classic SDD / manual `sdd-*` (CA7 - gate is Orchestrated Delivery `orchestrate-*` only)
- Pass Task `model` without `SUBAGENT-MODEL.md` gate + user **sim** (or user-named slug); ask model on routine story drafts
- Hard-fail when `subagents` is `none` or Task is unavailable (use **fallback** série **in-parent** per `SPAWN.md`)
- Exceed orchestrate ≤4 concurrent Tasks without user-approved wave/série (`SPAWN.md`)
- Paste guideline packs into Task child prompts
- Write SDD artifacts containing OS absolute paths matching `^[A-Za-z]:/` or user-home InstallRoot embeds (`…/.cursor/sdd/…`, `…/.claude/sdd/…`) — use portable paths per `STORAGE.md` § Portable path
- Read full `reference.md` when a `references/<section>.md` exists for the current Process step (`SKILL-REFERENCE-RETRIEVAL.md`)

---

## Explicit exclusions

Do **not** introduce:

- Application or test source writes in O2
- Forked “mini-spec” that skips sdd-spec/sdd-plan gates
- External work-item tracker CLI/API commands
- External work-item tracker or org-only compliance fields
- Assumed série/paralelo without asking
- Changes to `sdd-develop` one-PLAN-step-per-session contract
- Spec Kit / worktree multi-US changes (out of Orchestrated Delivery MVP)
- Repo-root `PRD/` / `PLAN/` new writes
