# Finding format

Canonical shape for a clarification finding. Skill, agent, and reference prose stay **English**. When a finding is written into an SDD artifact, narrative sentences follow content-language (`LANGUAGE.md`). Tokens, type ids, and severity ids stay English.

Companion: `readiness-severity.md` § Open-question gate, `clarify-depth.md`, `STORAGE.md` § Portable path.

Do **not** create a second severity vocabulary beside `readiness-severity.md`.

## Finding types

Assign exactly one type:

| Type | Meaning |
|------|---------|
| `AMBIGUITY` | The text supports materially different interpretations. |
| `ACCEPTANCE_GAP` | An acceptance condition is absent or cannot be checked by someone who did not write it. |
| `GAP` | A relevant case, state, actor, flow, or contract is not addressed. |
| `CONTRADICTION` | Sections disagree with each other or with cited evidence. |
| `RISK` | The statement is clear, and an important consequence is not acknowledged. |
| `DEPENDENCY` | The text depends on an external owner, artifact, system, or decision. |

## Severity tokens

| Source wording | Local token |
|----------------|-------------|
| `BLOCKING` | `B` |
| `IMPORTANT` | `I` |
| `MINOR` | `MINOR` |

Write `B`, `I`, or `MINOR` only.

This file does **not** rewrite the global severity table in `readiness-severity.md`. Outside the four open-question gates, that table still says whether `MINOR` blocks READY.

At the four gates named in `readiness-severity.md` § Open-question gate, any unanswered question blocks the next artifact, including `MINOR`. Stop code: `open_question`. Do not ask only `B` and `I` at those gates. Ask every open question, in one batch.

## Block shape

Stable id: `FND-001`, `FND-002`, … Do not reuse an id inside the same artifact.

Each finding contains:

1. Id, severity token, and type.
2. Section heading (or a short excerpt of that section).
3. What is ambiguous, missing, contradictory, risky, or dependent.
4. Evidence: a portable path, or the token `no-evidence`.
5. A recommendation line that is labeled as a recommendation. A recommendation is not a decided fact and does not close the finding.

```text
[FND-001 | B | AMBIGUITY] <section heading>
Evidence: <portable path> | no-evidence
<what competes or is missing>
Recommendation: <recommendation, not a decision>
```

Without a portable evidence path, do not mark the finding resolved. `no-evidence` keeps it open.

## Closing a finding

Close only when one of these is recorded against the finding id:

1. Cited evidence: a portable path the reader can open.
2. An explicit user answer.

Silence does not close a finding. "I do not know" (any chat language) leaves it open. Another owner's unanswered handoff leaves it open.

Do not treat a filled recommendation as the close.
