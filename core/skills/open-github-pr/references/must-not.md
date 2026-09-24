## Must not

- Create a PR without Step -1 gate approval and content confirmation (`sim`)
- Create a PR without asking the auto-merge question in Step 6 (even when auto-merge is unavailable)
- Enable auto-merge or merge a **feature** PR with `--merge` / `--rebase` instead of **`--squash`**
- Enable auto-merge or merge a **release** PR with **`--squash`** (or a noisy merge commit when rebase/FF-compatible merge is available) — release must stay linear (`--rebase`)
- Silently fall back to a different merge method when the mode-required method is disabled in repo settings
- Skip reading this `SKILL.md` and jump straight to `gh pr create` / web compare
- Open a feature PR from `main` / `master` / `develop` or an invalid branch name
- Open a release PR unless head is `develop` and base is `master` or `main`
- Force-push protected branches
- Skip push handoff when the branch is not on `origin`
- Use Caveman Mode or compress PR title/body
- External work-item tracker APIs or mandatory org-only PR analyzers
- Implement or invoke a future `/open-pr` orchestrator (out of scope)
