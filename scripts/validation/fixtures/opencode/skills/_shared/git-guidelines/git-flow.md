# Git Flow and Workflow Guidelines

## Branching Strategy

Toolkit and consumer repos that follow this guide use:

1. **`develop`**: Integration branch. Default PR target for day-to-day work. Do not commit or push directly.
2. **`master` / `main`**: Release / stable. Updated only from `develop` via PR. Do not commit or push directly.
3. **Feature branches**: All work. Branch from `develop` (or the baseline the user/PLAN names). Merge back via PR into `develop`.

Naming convention for branches (enforced by `branch-validation`):

- `feature/<slug>` — e.g. `feature/add-oauth-login`
- `feat/<id>` — e.g. `feat/123`, `feat/PLAN-001`

Do not use `fix/` or `chore/` as branch prefixes under this model; keep those as Conventional Commit **types**, not branch names.

Flow:

```text
feature/* or feat/*  →  PR →  develop  →  PR →  master / main
```

## Pull Requests and Code Review

- **Default base:** `develop` for feature work; `master`/`main` only for release PRs whose head is `develop`.
- **Small, focused PRs**: One responsibility per PR when practical.
- **Descriptive titles and summaries**: Context, why, how tested. Link issues when relevant (`Refs #42`).
- **Approvals**: Follow the repository ruleset (toolkit repos often allow 0 approvals for a solo owner; app teams may require peer review or CODEOWNERS).

## Pre-Commit Hooks (Husky)

When the consumer project uses pre-commit hooks, configure them so formatting and linting run before commit.

- **Automated Formatting**: Tools like CSharpier, Prettier, or ESLint in pre-commit hooks.
- **Installation**: On first clone, run the project setup (e.g. `dotnet husky install`, `npm run prepare`).
- **Bypassing**: Only bypass hooks (`--no-verify`) in emergencies or when the user explicitly approves.

> [!TIP]
> Always run your tests locally before opening a PR. Although CI/CD pipelines will catch failures, local testing saves time and CI resources.

---

## AI Stealth Policy

- **PR descriptions and commit messages** must not reference AI, generation, or automation. Write as a developer who owns the code.
- **No AI co-author trailers** (`Co-authored-by: Cursor`, `cursoragent@cursor.com`, GitHub Copilot, Antigravity, or similar).
- Output must be indistinguishable from work produced without AI assistance. See `guardrails.mdc` § 9.
