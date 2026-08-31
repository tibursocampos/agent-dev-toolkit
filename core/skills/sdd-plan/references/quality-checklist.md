## Quality checklist (before handoff)

- [ ] User confirmed **sim** on canonical PLAN path (`PIPELINE.md` § Confirm before write)
- [ ] Canonical PRD on disk; PRD path and `NNN` match the PLAN filename
- [ ] Body follows `templates/sdd/PLAN.md` (REQ→step map; Aceite cites REQ/CA)
- [ ] Every PRD REQ and acceptance criterion appears in some step
- [ ] Vague Aceite challenged and rewritten
- [ ] `validate-prd` and `validate-plan` exit 0 on the written paths
- [ ] Step prose in pt-BR (unless English override)
- [ ] No full implementation code blocks in the PLAN
- [ ] No full PRD / memory-bank dump in PLAN or handoff prompts
- [ ] PLAN magro: SQL/DDL/JSON/OpenAPI omitted **only** if a canonical path already exists (bank phase 2 or `ARCH/` / `ANALYSIS/`); otherwise create that file first and cite the path
- [ ] Output path: `features/**/PLAN/PLAN_NNN_*.md` or global `.../features/**/PLAN/` only (not root `PLAN/`, ad-hoc `docs/`, or `{{TOOLKIT_ROOT}}/` outside `sdd/.../features/`)
- [ ] Handoff: `/sdd-develop - <portable-plan-path> - Step 1`
- [ ] Initial progress `0/N`
