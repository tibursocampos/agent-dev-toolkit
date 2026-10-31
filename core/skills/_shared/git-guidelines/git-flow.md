# Git Flow and Workflow Guidelines

## Branching Strategy

Each repository defines its own branches, flow, and release rules, in its `.github/` folder and its docs. The toolkit does not set them.

The toolkit enforces one rule for development work: do not commit or push directly on the integration branches `main`, `master`, or `develop`. Development work happens on a separate branch, and the repository's convention names it. Use the operator's explicit branch name when given.

## Pull Requests and Code Review

- **Base branch:** the repository's default integration branch, unless the operator or the PLAN names another. The repository's PR template or docs state the rule.
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
