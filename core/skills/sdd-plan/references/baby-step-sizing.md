## Baby-step sizing checklist

`sdd-plan` does not invent steps and does not size them by duration. Step ids, titles, dependencies, and waves come from `split-story-checklist` (`REFINE/tasks.md`).

- [ ] Step id copied from `tasks.md`; no extra step
- [ ] No duration on any step
- [ ] No step with 4+ new files without the split already grouping them that way
- [ ] EF migration and mapping separated when both apply and the split says so
- [ ] **Anti file-named steps:** no step title that is only a file/class/script/path (`story-sizing.md`, `anti-task-shatter.md`)
- [ ] Acceptance cites REQ-NNN/CA + a verifiable check (`references/challenge-vagueness.md`)
- [ ] When story `ARCH/` / `ANALYSIS/` exist, PLAN **cites** those portable paths — does not paste bodies
- [ ] Project docs language follows the chat language (`LANGUAGE.md`), not a fixed locale

---
