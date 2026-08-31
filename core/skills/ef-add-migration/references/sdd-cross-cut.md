## SDD cross-cut

When a PLAN step says “add EF migration”, the **implement** skill hands off here instead of embedding `dotnet ef` steps in the PLAN body. After migration files exist, resume:

```
/sdd-develop - <full-plan-path> - Step N
```

Use the **same** SDD PLAN path `sdd-develop` passed in (`features/**/PLAN/PLAN_*.md` or global `{{SDD_ROOT}}/<repo-id>/features/**/PLAN/` per `STORAGE.md`). Do not use root/flat `PLAN/` or `docs/documentation-plan/plan.md`.
