## Session report template

Use after PLAN is saved:

```markdown
## Step N complete

**PLAN:** <portable-plan-path>
**Step:** N - [title]
**Branch:** feature/... or feat/...
**Files:** [list]
**Tests:** [pass/fail summary]
**Progress:** N/M (X%)

**Next (new chat):**
/sdd-develop - <portable-plan-path> - Step N+1
```

---

## Context checkpoint (mandatory)

From `context-management.mdc` after PLAN persist:

1. Update control file (PLAN).
2. Assess context usage if visible.
3. At **≥ 40%:** show pause message; do not start the next PLAN step in this session.
4. At **≥ 80%:** stop definitively; user must start new chat.

Include in pause message: saved PLAN path, last step completed, next step id/title.

---
