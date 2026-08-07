# Specialist receipt (Caveman ON)

When/how to spawn children (native vs fallback, limits): `SPAWN.md` — do not paste spawn policy here. Parent orchestrator policy: `core/policy/orchestrator-session.md`.

**Subagent I/O is Caveman-scoped:** child prompts, execution style, and returns honor `skills/_shared/caveman/CAVEMAN.md` + parent prefs intensity. Parent passes scoped paths + receipt requirement + role — not guideline dumps.

When `caveman_mode` is true in `{{SDD_ROOT}}/preferences.json`, every Forma C specialist pass must end with a **structured receipt** (ultra style). Parent chat may stay Full/Lite per skill cap; the **reinjected** specialist summary uses this schema.

When caveman is OFF: still prefer a compact receipt / tight bullets (token control); schema recommended.

## Receipt schema

```text
## Receipt
| Finding | Path:Line | Note | Next |
|---------|-----------|------|------|
| … | `path`:N or — | one short fact | action or — |
```

Rules:

- Max **12** rows unless user asked for exhaustive list.
- Path:Line when grounded in a file; otherwise `—`.
- Note = one fact; no preamble; no invented abbrevs (`cfg`/`impl`); no prose `→`.
- Never compress confirmation gates or proposed artifact bodies — put those **outside** the receipt.
- Inherit parent Auto-Clarity: security / irreversible / ambiguous order → clear prose block, then resume receipt.

## Refusal tokens (machine-parseable)

Use alone on a line when the pass cannot proceed:

| Token | Meaning |
|-------|---------|
| `needs-confirm.` | User must approve scope/path before continue |
| `too-big.` | Scope exceeds one specialist pass; split stories or ask parent |
| `No match.` | No relevant finding in scoped files |

## Parent duty

After each specialist: paste or summarize via receipt into `CONTINUITY.md` (facts only). Do not dump full specialist chat into CONTINUITY.
