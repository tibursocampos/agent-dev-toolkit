## SDD PLAN resolution (read-only)

When the handoff table says **PLAN already exists**, resolve the path before suggesting `sdd-develop`:

1. Load `STORAGE.md`.
2. Glob `features/**/PLAN/PLAN_*.md` only (workspace + global feature root).
3. Do **not** resolve root/flat `PLAN/PLAN_*.md` or `{{SDD_ROOT}}/<repo-id>/PLAN/` for execution.
4. If the user named a feature or `NNN`, pick the matching file under `features/`.
5. If zero or multiple remain, ask once in pt-BR with numbered full paths.
6. Pass **full path** in the handoff.

Do **not** use `docs/documentation-plan/plan.md`.

---
