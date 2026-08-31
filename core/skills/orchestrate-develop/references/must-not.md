## Must not (full)

- Skip Step 0 Memory Bank Gate (unless explicit user `skip-memory-bank`)
- Create `memory-bank/` under `features/` or dump bank into CONTINUITY / child prompts
- Parent writes application/production code or tests
- Merge N PLAN steps into one Task / one session context
- Bypass or weaken `sdd-develop` one-step-per-session contract
- Auto-commit / auto-push
- Create external work-item tracker or org-only compliance content
- Force multi-angle code-review
- Introduce git worktrees for multi-US parallelism (MVP)
- Write new PRD/PLAN (O2 / sdd-spec / sdd-plan own that)
- Require memory-bank for manual Classic SDD `sdd-develop` (CA7)
- Pass Task `model` without `SUBAGENT-MODEL.md` gate + user **sim** (or user-named slug); ask model on routine PLAN steps
- Hard-fail when `subagents` is `none` or Task is unavailable (use **fallback** handoff to `/sdd-develop` per `SPAWN.md`)
- Exceed orchestrate ≤4 concurrent Tasks without user-approved wave/série (`SPAWN.md`)
- Paste guideline packs into Task child prompts
- Write SDD artifacts containing OS absolute paths matching `^[A-Za-z]:/` or user-home InstallRoot embeds (`…/.cursor/sdd/…`, `…/.claude/sdd/…`) — use portable paths per `STORAGE.md` § Portable path
- Use O3 / Task parallelism as the evidence verifier (**Verifier ≠ O3**; evidence-or-zero is sequential `validate-evidence` in `sdd-develop`)
- Mark develop children done at level ≥ `cheap` without passing `validate-evidence` (`EVD-STATE-CONTRACT.md`)
- Use O3 / Task parallelism as the archive / TRACE verifier (**Verifier ≠ O3**; living loop is sequential `validate-trace`)
- Declare feature archive done without `validate-trace -RequireArchiveComplete` (`TRACE-ARCHIVE-CONTRACT.md`)
- Read full `reference.md` when a `references/<section>.md` exists for the current Process step (`SKILL-REFERENCE-RETRIEVAL.md`)

---

## Explicit exclusions

- Parent implementation of app/test code
- Multi-step children or auto-chained steps without **sim**
- Forked develop process that skips sdd-develop gates
- Mandatory multi-angle review
- Git worktrees for multi-US
- external work-item tracker or org-only compliance content
- Spec Kit / `.specify` (removed from toolkit - use Classic SDD / Backlog Refine / Orchestrated Delivery)
- Weakening `sdd-develop` one-step contract
