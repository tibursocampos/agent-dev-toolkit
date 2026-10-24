## Baby-step sizing checklist

`sdd-plan` does not invent steps and does not size them by duration. Resolve `invocation_context` first:

- `direct`: by default derive PLAN-native IDs, titles, dependencies, and grouping from the approved PRD's distinct behaviors, REQ, and CA. If an explicitly linked valid checklist is adopted, preserve its IDs and dependencies exactly. Do not fabricate checklist IDs or require `REFINE/tasks.md`.
- `orchestrated`: use the stable step IDs, titles, and dependencies from the validated O2 checklist produced by `split-story-checklist`; do not rewrite or renumber them.

In either context, name each step by a verifiable outcome, not a file, class, or implementation layer. Use complexity only as the granularity signal defined in `checklist-acquisition.md`; it does not replace behavior-based grouping.

If the context is `orchestrated` and a medium/complex checklist is absent, follow `references/checklist-acquisition.md`: coordinate `split-story-checklist`, validate its output, and resume only after success. In `direct`, the missing checklist is expected and does not block. Never author or renumber a checklist in this skill.

- [ ] In `orchestrated`, step id copied from `tasks.md`; no extra step. In `direct`, IDs are derived from PRD behavior unless an explicitly linked valid checklist is adopted; never invent checklist IDs
- [ ] No duration on any step
- [ ] No step with 4+ new files without the split already grouping them that way
- [ ] EF migration and mapping separated when both apply and the split says so
- [ ] **Anti file-named steps:** no step title that is only a file/class/script/path (`story-sizing.md`, `anti-task-shatter.md`)
- [ ] Acceptance cites REQ-NNN/CA + a verifiable check (`references/challenge-vagueness.md`)
- [ ] When story `ARCH/` / `ANALYSIS/` exist, PLAN **cites** those portable paths — does not paste bodies
- [ ] Project docs language follows the chat language (`LANGUAGE.md`), not a fixed locale

---
