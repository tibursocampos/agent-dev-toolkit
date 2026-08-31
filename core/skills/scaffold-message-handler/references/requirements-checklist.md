## Requirements checklist

Collect before proposing files. Copy into chat and fill with user answers.

```markdown
## Message consumer requirements

| Item | Answer |
|------|--------|
| **Queue / topic** | |
| **Subscription** (if any) | |
| **Message contract** | Type name, namespace, schema owner |
| **Trigger / event** | What published the message |
| **Processing** | Side effects (DB, API, cache, downstream publish) |
| **Idempotency** | Key / store / "not required" + justification |
| **Retry** | Count, backoff, where configured |
| **DLQ / error queue** | Name or broker behavior |
| **Ordering** | Required? partition key? |
| **Failure visibility** | Logs, metrics, alerts (repo conventions) |
| **Tests** | Unit only / integration with test container / manual |
```

### Idempotency prompts

If not stated, ask:

- Can the same message be delivered twice?
- Is there a natural business key to deduplicate?
- Does the repo use outbox/inbox tables?

### Retry / DLQ prompts

- What happens after max retries?
- Is there a dead-letter queue or MassTransit `_error` / `_skipped`?
- Should failures be logged and skipped or block the pipeline?

---
