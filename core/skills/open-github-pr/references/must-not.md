## Must not

- Create a PR without Step -1 gate approval and content confirmation (`sim`)
- Create a PR without asking the auto-merge question in Step 6 (even when auto-merge is unavailable)
- Enable auto-merge or merge with a method the repository does not allow, or with a method this skill picked without the repository's rules or the operator saying so
- Open a PR whose base is not the base confirmed in Step 0
- Skip reading this `SKILL.md` and jump straight to `gh pr create` / web compare
- Open a PR from `main` / `master` / `develop` or from an invalid branch name
- Force-push protected branches
- Skip push handoff when the branch is not on `origin`
- Use Caveman Mode or compress PR title/body
- External work-item tracker APIs or mandatory org-only PR analyzers
- Implement or invoke a future `/open-pr` orchestrator (out of scope)
