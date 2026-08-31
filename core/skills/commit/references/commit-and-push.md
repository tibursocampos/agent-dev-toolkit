## Commit

After approval, write the **exact** user-approved text to a message file. The file must contain **only** Conventional Commits content - no footers, no trailers, no `Co-authored-by` lines.

```bash
git add <explicit paths>
git commit -F <path-to-approved-message.txt>
```

Use **only** `-F` or a single `-m` with the approved subject (and optional body via `-F`). Do **not** use:

- `git commit --trailer` / `--trailer=…` (any trailer flag)
- Extra `-m` blocks for footers or attribution
- `--author` overrides for Cursor or any AI agent
- Any line containing `Co-authored-by:` in the message you write

**Never** append `Co-authored-by: Cursor`, `Co-authored-by: Antigravity`, or similar - not in the message file, not in chat drafts shown to git, not in any form.

### Post-commit verification (mandatory)

Cursor or other tooling may inject `Co-authored-by: Cursor` **after** the agent runs `git commit`. The agent must **not** leave that in place.

Immediately after every commit:

```bash
git log -1 --format=%B
```

If the output contains `Co-authored-by:` (any variant, any email), strip it and amend:

1. Rewrite the message file with **only** the approved Conventional Commits text (no `Co-authored-by` lines).
2. Run `git commit --amend -F <path-to-approved-message.txt>`.
3. Re-check with `git log -1 --format=%B`.
4. If the trailer is still present, run `git commit --amend -F <path-to-approved-message.txt> --no-verify` **only** to remove the unauthorized co-author line - do not skip hooks for any other reason.
5. If the trailer **still** remains (`prepare-commit-msg` may run even with `--no-verify`), amend with hooks disabled:

```bash
git -c core.hooksPath=<empty-directory> commit --amend -F <path-to-approved-message.txt>
```

Use a temporary empty folder (not the repo `.git/hooks`). Re-check `git log -1 --format=%B`.

Report the final message body in chat (without co-author trailers).

Do not use `git commit --amend` on shared or pushed history unless the user explicitly requests it and amend rules apply.

## Push (optional)

Push only when the user asks:

```bash
git push -u origin HEAD
```

Never `git push --force` to `main`, `master`, or `develop`.

After a successful push from this skill, follow `/push` §3: **ask** whether to open a PR with **`/open-github-pr`**. Do **not** create the pull request here — hand off to that skill on **sim**.

If the user asked for commit + push + PR in one message (EN/pt-BR), treat PR intent as already granted for **handoff only**:

| Phrase examples (non-exhaustive) | After commit (+ push if approved) |
|----------------------------------|-----------------------------------|
| `fluxo completo`, `faça o fluxo completo` | **Read and follow** `open-github-pr/SKILL.md` end-to-end |
| `abra o PR`, `abrir PR`, `criar PR`, `faça o PR` | same |
| `commit + push + PR`, `push and open PR`, `open the PR` | same |

Do **not** open the PR inside `/commit`. Do **not** skip `/open-github-pr` confirmation or its auto-merge ask. Load that skill’s `SKILL.md` before any PR-creation action.

## Report

- Branch name
- Short commit hash (`git rev-parse --short HEAD`)
- Files included
- Push status (if applicable)
- SDD handoff: if mid-PLAN, remind to update PLAN via `sdd-develop` before the next step in a new chat
- If push succeeded and PR was not declined: remind that PR opening is **`/open-github-pr`** only
