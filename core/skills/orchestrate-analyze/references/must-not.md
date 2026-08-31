## Must not (full)

- Skip Step 0 Memory Bank Gate (unless explicit user `skip-memory-bank`)
- Create or place `memory-bank/` under `features/NNN-slug/`
- Duplicate memory-bank body into CONTINUITY (path + status only)
- Dump entire memory-bank into the parent orchestrator context
- Write application/production code or tests (`*.cs`, `*.tsx`, `*.ts`, `*.js`, `*.vue`, `*.py`, migrations, etc.)
- Call `*-developer` / `developer` to **implement** code (suggesting the trivial shortcut is allowed)
- Skip human backlog approval or treat silence as `sim`
- Skip the architecture confirm gate on greenfield / `needs_domain` (no established style), or write final ARCH / pick a silent style default before operator **sim**
- Skip `architect` / `database` (or skip writing mirror ARCH) on brownfield — skip **style re-pick / confirm gate** only
- Leave `memory-bank/architecture.md` draft / `needs-confirm` after ARCH **sim** (point-promote that file; not a full inventory refresh)
- Pile unresolved product/schema choices only in CONTINUITY when `needs_database` / `needs_domain` (write them under `ANALYSIS/` / `ARCH/`; CONTINUITY may pointer only)
- Approve backlog when required `ANALYSIS/` / `ARCH/` / `SEC/` folders are missing for true flags / brownfield
- Treat pointer-only cited `.md` as promoted; treat `.cursor/plans/` as O3 input
- Write PRD/PLAN (O2 owns that via `sdd-spec` / `sdd-plan` contracts)
- Create external work-item tracker or org-only compliance content
- Create ~40 agent files or expand the roster beyond `ROSTER.md`
- Modify toolkit `.gitignore` as part of porting this skill into the toolkit repo; at runtime follow `STORAGE.md` only for consumer repo SDD patterns
- Change the `sdd-develop` one-step-per-session contract
- Create `REFINE/` / `ANALYSIS/` / `ARCH/` / `SEC/` / `PRD/` / `PLAN/` at **repo root**
- Resolve feature paths outside `$Cwd/features/` or `<classic.path>/features/`, or accept `..` segments
- Pass Task `model` without `SUBAGENT-MODEL.md` gate + user **sim** (or user-named slug); ask model on routine spawns
- Hard-fail when `subagents` is `none` or Task is unavailable (use **fallback** **in-parent write** to `ANALYSIS/` / `ARCH/` / `SEC/` per `SPAWN.md`; never skip required folders)
- Exceed orchestrate ≤4 concurrent Tasks without user-approved wave/série (`SPAWN.md`)
- Paste guideline packs into Task child prompts
- Write SDD artifacts containing OS absolute paths matching `^[A-Za-z]:/` or user-home InstallRoot embeds (`…/.cursor/sdd/…`, `…/.claude/sdd/…`) — use portable paths per `STORAGE.md` § Portable path
- Read full `reference.md` when a `references/<section>.md` exists for the current Process step (`SKILL-REFERENCE-RETRIEVAL.md`)

---

## Explicit exclusions

Do **not** introduce:

- Write of application or test source as part of O1
- `memory-bank/` under `features/NNN-slug/`
- Full memory-bank dump into CONTINUITY or parent chat
- Skip of Step 0 without explicit `skip-memory-bank`
- External work-item tracker CLI/API commands
- External work-item tracker or org-only compliance fields
- Forty aspirational agent files from design.md
- Changes to `sdd-develop` one-PLAN-step-per-session contract
