# Status legend

Step status tokens, English only:

| Token | Meaning |
|-------|---------|
| `PENDING` | Not started |
| `IN_PROGRESS` | The active implement session |
| `BLOCKED` | Stopped with a recorded cause |
| `COMPLETED` | Acceptance and the step test passed |
| `SKIPPED` | Explicitly skipped |

`SKIPPED` is not a passing result and does not satisfy acceptance, a completed dependency, or overall PLAN closure. Resolve omitted work through the PLAN owner and an explicitly approved PLAN update; do not infer that its acceptance is unnecessary.

Overall implementation status for a new PLAN: `NOT_STARTED`.

Progress line: `0/N`. Prose around the token follows the chat language (`LANGUAGE.md`). Do not write the status word in another language. Do not use a duration.

**Implement skill:** step headings may use `STEP` or `PASSO`. The status token stays one of the five above.
