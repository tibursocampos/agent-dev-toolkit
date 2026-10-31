# Conventions

## Language & naming

- Source, tests, and commit messages: English identifiers.
- Chat output follows the user. Spawn prompts and receipts stay en-US (`core/skills/_shared/agents/LANGUAGE.md`).
- SDD artifact prose follows content-language (`LANGUAGE.md`): invocation override, then `preferences.json` `artifact_language`, then manifest, else chat. Do not hard-code one locale.
- Published files `core/policy/user-language-pt-br.md` and `core/policy/sdd-artifact-language-pt-br.md` are install defaults when the operator session is pt-BR. They do not override the `LANGUAGE.md` matrix when chat or preferences say otherwise.

## Structure

- Agent-neutral material stays under `core/` (skills, policy, router, `core/skills/_shared/sdd-artifacts/` contracts).
- Host-specific publish code stays under `adapters/<id>/` and is registered in `adapters/registry.json`.
- Operator CLI and validation asserts stay under `scripts/`.
- Memory bank for this repo is `memory-bank/` (repository storage). Do not place it under `features/`.
- SDD feature artifacts, when written, use `features/NNN-slug/` with portable paths relative to the repo root.
- `core/skills/_shared/skills-catalog/CATALOG.md` and `OPERATOR.md` are the help-skills source of truth. Exhaustive mirrors must match invocable skill IDs; README previews may remain partial and must not imply completeness.

## Testing

- Prefer the cheapest check that distinguishes a named regression risk. A wide suite is not the default. A removed test names the guarantee and the cheaper check that still covers it.
- In-repo PowerShell asserts live under `scripts/validation/` with fixture smokes. The default CI `validate` job runs named asserts and does not sync a live agent home. `validate-core` stays a local core suite.
- Layout: `scripts/validation/Assert-*.ps1`, `scripts/validation/validate-core.ps1`, fixtures under `scripts/validation/fixtures/`.
- Run core checks with `pwsh -NoProfile -File scripts/validation/validate-core.ps1`; use `-Only <check-name>` for a bounded assertion. Build the docs site strictly with `pip install -r docs-site/requirements-docs.txt` followed by `python -m mkdocs build --strict -f docs-site/mkdocs.yml`.
- `scripts/toolkit.ps1` dispatches CLI scripts through `scripts/_lib/Invoke-ToolkitChildScript.ps1`; preserve this process boundary so a child script's top-level `exit` cannot terminate the interactive menu. `Assert-ToolkitScriptIsolation.ps1` is the regression check.
- Catalog changes must keep all 45 invocable IDs aligned across source, `CATALOG.md`, `docs/SKILLS.md`, and both docs-site first-use pages. `Assert-SkillCatalogParity.ps1` checks these exhaustive surfaces.

## Git / branches

- Commit messages follow Conventional Commits (`core/policy/conventional-commits.md`).
- Commit and push only from `feature/<slug>` or `feat/<id>` (`core/policy/branch-validation.md`).
- `sdd-spec`, `sdd-plan`, `orchestrate-analyze`, and `orchestrate-deliver` write the canonical artifact on the current branch. `orchestrate-develop`, `sdd-develop`, and `*-developer` still state the branch before code changes.
- `/commit` confirms the message and commits. It does not start a memory-bank refresh, documentation, `/push`, or a pull request unless that same operator request already includes them.
- `/code-review` does not suggest a pull request, a memory-bank refresh, or documentation. Report prose follows `LANGUAGE.md`. Band tokens stay English.
- Do not add `/memory-bank/` to the SDD `.gitignore` block. Commit bank prose when it is product knowledge. Never commit secrets.
- Normal release path is a `develop` to `master` PR merged with a merge commit (never squash or rebase, so `master` keeps `develop` history); the release workflow tags/publishes, then reconciles the promoted commit back to `develop`. For recovery, dispatch `release.yml` on `master` with `reconcile_only=true` and no version; do not create a second tag for reconciliation.
- Keep `RELEASE_SYNC_APP_ID` and `RELEASE_SYNC_APP_PRIVATE_KEY` in GitHub Actions secrets only. The App needs contents and pull-request write permissions without branch-rule bypass.

## Do / don't

| Do | Don't |
|----|--------|
| Default publish to an in-repo fixture | Write a live user home without `-AllowUserHome` |
| Treat registry `subagents` as `native` or `none`; use effective Antigravity probe | Assume OpenHands can spawn children |
| Keep one PLAN step per `sdd-develop` session | Continue into the next PLAN step in the same session |
| Cite env var names only | Copy tokens, connection strings, or raw `.env` values into the bank |

## Notes

Align with `README.md`, `core/policy/`, and `core/skills/_shared/agents/LANGUAGE.md`.
**No secrets.**
