# Conventions

## Language & naming

- Source, tests, and commit messages: English identifiers.
- Chat output follows the user. Spawn prompts and receipts stay en-US (`core/skills/_shared/agents/LANGUAGE.md`).
- SDD artifact prose follows content-language (`LANGUAGE.md`): invocation override, then `preferences.json` `artifact_language`, then manifest, else chat. Do not hard-code one locale.
- Published files `core/policy/user-language-pt-br.md` and `core/policy/sdd-artifact-language-pt-br.md` are install defaults when the operator session is pt-BR. They do not override the `LANGUAGE.md` matrix when chat or preferences say otherwise.

## Structure

- Agent-neutral material stays under `core/` (skills, policy, router, `core/sdd/` contracts).
- Host-specific publish code stays under `adapters/<id>/` and is registered in `adapters/registry.json`.
- Operator CLI and validation asserts stay under `scripts/`.
- Memory bank for this repo is `memory-bank/` (repository storage). Do not place it under `features/`.
- SDD feature artifacts, when written, use `features/NNN-slug/` with portable paths relative to the repo root.

## Testing

- Prefer: in-repo PowerShell asserts under `scripts/validation/` and fixture smokes. CI job runs `validate-core` and does not sync a live agent home.
- Layout: `scripts/validation/Assert-*.ps1`, `scripts/validation/validate-core.ps1`, fixtures under `scripts/validation/fixtures/`.

## Git / branches

- Commit messages follow Conventional Commits (`core/policy/conventional-commits.md`).
- Commit and push only from `feature/<slug>` or `feat/<id>` (`core/policy/branch-validation.md`).
- Do not add `/memory-bank/` to the SDD `.gitignore` block. Commit bank prose when it is product knowledge. Never commit secrets.

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
