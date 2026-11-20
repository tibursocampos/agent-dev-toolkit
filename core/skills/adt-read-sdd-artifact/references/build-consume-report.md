## Build envelope, consumption, and report

### Build envelope

Emit `source_context` with `schema`, `artifact_kind`, `portable_path`, and `identity` as in `references/envelope-schema.md`. Do **not** invent story_id for FEATURE root.

### Consumption contract (no opaque re-read)

| Situation | Required behavior |
|-----------|-------------------|
| Handoff / receipt already includes `source_context` for path P | Child **must not** re-Read P solely to rediscover identity |
| Need file body and envelope has no body | Single explicit Read of `portable_path` only; attach under caller control — not a second identity probe |
| Path fail | Report `reason` + short `message`; return **no** `source_context` key |

### Report

Success: print/return the envelope (YAML or JSON). Failure: `{ ok: false, reason, message }` only.
