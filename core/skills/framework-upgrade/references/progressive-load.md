# Progressive load — framework-upgrade

Aligns with `SELECTIVE-RETRIEVAL.md` (`SR-NO-FULL-DUMP`) and `SKILL-REFERENCE-RETRIEVAL.md`.

## Rule

Load **only** the paths needed for the active mode + pack section. Prefer portable path cites + short summaries over bodies.

## Shared layer (this skill)

| Need | Load |
|------|------|
| Step order | `references/command.md` |
| Mode contract | `references/modes.md` |
| Versions / range | `references/version-policy.md` |
| Out of range | `references/research-protocol.md` |
| Normative vs auxiliary URLs | `references/sources-catalog.md` |
| Decisions | `references/decision-register.md` |
| Done claims | `references/evidence.md` |
| OOS / Skip D | `references/skip-policy.md` |

Never preload all of the above at once.

## Pack layer (when packs exist)

1. `packs/REGISTRY.md` — discover ids only.
2. `packs/<id>/PACK.md` — detect, `supported_range`, pointer index.
3. **One** `packs/<id>/references/<section>.md` per hop/step.
4. Optional pointer into `skills/_shared/<stack>-guidelines/` — **one** guideline file, never the whole tree.

## Forbidden

- Dump entire Supply / external brand corpora
- Paste full PRD/PLAN/bank into the upgrade session
- Preload every pack reference “for convenience”
- Embed Athena / Jarvis / ADO mutate playbooks
