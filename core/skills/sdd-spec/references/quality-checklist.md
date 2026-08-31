## Quality checklist (before handoff)

- [ ] User confirmed **sim** on canonical path (`PIPELINE.md` § Confirm before write)
- [ ] Path matches `features/**/PRD/NNN_*.md` or global `.../features/**/PRD/NNN_*.md` only
- [ ] Body follows `templates/sdd/PRD.md` (REQ-NNN ids, verifiable CA, OOS; EARS only if useful)
- [ ] Vague AC/REQ challenged and rewritten
- [ ] `validate-prd` exit 0 on the written path
- [ ] Brownfield: `CHANGE.md` present + `validate-change` exit 0; greenfield: no empty CHANGE forced
- [ ] No implementation code in the PRD; no production/test code edited in `spec` session
- [ ] No full memory-bank / PRD dump prescribed in this skill session
- [ ] Body in pt-BR unless English override
- [ ] Type/method/API names in English where cited
- [ ] Status **Pronto para planejamento** (or **Ready for planning** if EN override)
- [ ] Handoff: `/sdd-plan - <portable-prd-path>`
