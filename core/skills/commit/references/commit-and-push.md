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

## Push and pull request (same request only)

Run `git push` only when the same operator request that started `/commit` already includes push. Do not ask whether to push. Do not start the `/push` skill.

```bash
git push -u origin HEAD
```

Never `git push --force` to `main`, `master`, or `develop`.

Do not follow `/push` to ask about a pull request. Hand off to `/open-github-pr` only when that same operator request already includes a pull request. Do not create the pull request inside `/commit`. Load that skill’s `SKILL.md` before any pull-request action. Do not skip that skill’s confirmation when the handoff is in scope.

| Phrase in the same request (non-exhaustive) | After the confirmed commit |
|---------------------------------------------|----------------------------|
| `fluxo completo`, `faça o fluxo completo`, `commit + push + PR`, `push and open PR` | Push, then read and follow `open-github-pr/SKILL.md` |
| push without a pull request (`push`, `git push`, `faça o push`) | Push only, then stop. Do not offer a pull request. |
| pull request without push (`abra o PR`, `abrir PR`, `criar PR`, `faça o PR`, `open the PR`) | Hand off to `/open-github-pr`. Do not push unless that same request also includes push. |

## Report

- Branch name
- Short commit hash (`git rev-parse --short HEAD`)
- Files included
- Push status only when the same request included push
- Stop. Do not start memory bank, documentation, `/push`, or a pull request from this report.
