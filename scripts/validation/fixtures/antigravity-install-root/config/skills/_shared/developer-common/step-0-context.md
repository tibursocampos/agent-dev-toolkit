# Step 0: Repository context

**Required:** Run before other developer-common steps (unless the parent skill already loaded context).

---

## 0.1. Read project router docs (critical)

If the repository has `AGENTS.md` or `README.md` at the root, read the sections relevant to your task. Project docs override generic toolkit defaults.

| Source | Rule |
|--------|------|
| `AGENTS.md` | Workflows, lazy-load paths, language rules |
| `README.md` | Build commands, folder layout, contribution notes |
| `docs/` | Feature-specific standards when listed in PLAN/PRD |
| None | Infer conventions from existing code (Glob, Grep, Read) |

Do not preload entire `{{TOOLKIT_ROOT}}/skills/_shared/` trees.

---

## 0.2. Confirm workspace

1. You are in the **target repository** (not this toolkit repo unless that is the subject).
2. Note default branch (`main`, `develop`, etc.) - ask if unclear.
3. For SDD work: confirm PRD/PLAN paths when the user provides them. For **`code-review`**, resolve artifacts via `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/STORAGE.md` (repo + `{{SDD_ROOT}}/<repo-id>/`) - do not assume absence from an empty workspace `PRD/` folder alone.

---

## 0.3. High-level task list

Create a short tracked list (Cursor todos or equivalent) at the start:

1. Read `AGENTS.md` / `README.md` - `in_progress`
2. Review guidelines (step 0.5)
3. Create or checkout feature branch (step 3)
4. Implement change + tests
5. Pre-commit validation (step 3.5)
6. Commit and optional push (step 4)
7. Pre-PR checklist (step 7)

**Rules:** update status as you go; keep one item `in_progress` at a time; max ~10 items.

Detailed PLAN steps use the PLAN file as the control artifact - do not duplicate every PLAN step in this list.

Template: `templates/todo-list.md`.

---

## Step 0 checklist

- [ ] `AGENTS.md` or `README.md` reviewed when present
- [ ] Project conventions understood
- [ ] High-level task list created
- [ ] First item marked in progress
