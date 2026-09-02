## Must not

- Push from invalid branch
- Force push default branches
- External work-item APIs or mandatory PR creation
- **Creating or merging a GitHub pull request from this skill** (CLI or web compare) — always hand off to `/open-github-pr`
- Skipping the handoff when PR intent was already clear (`fluxo completo`, `abra o PR`, etc.) — still load `/open-github-pr` for confirmation + auto-merge ask
