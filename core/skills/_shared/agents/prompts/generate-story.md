# Stage prompt: generate story

## Caveman / receipt

When parent reports `caveman_mode` ON: end with structured receipt per `_shared/agents/RECEIPT.md` (Finding | Path:Line | Note | Next). Use refusal tokens `needs-confirm.` / `too-big.` / `No match.` when applicable. Never compress gates or full artifact drafts (product drafts stay full).

Draft one deep `STORY.md` (US or TS) for the feature tree. **Not** a single Gherkin stub or empty contract.

## Language

- Artifact prose default **pt-BR**
- Identifiers, paths, skill/ref names **English**

## Template

Use `skills/_shared/templates/features/story/STORY.md` structure end-to-end.

## Lazy-load (do not preload the whole backlog-item-types folder)

Load **only** what this draft needs:

| When | Read |
|------|------|
| Always (draft start) | Template `story/STORY.md` |
| Before finalizing title/Objective | `skills/_shared/backlog-item-types/anti-task-shatter.md` |
| Before writing AC | `skills/_shared/backlog-item-types/gherkin-budget.md` |
| When Tipo = US (Who/Job/Outcome) | `skills/_shared/backlog-item-types/persona-context.md` |
| When filling Evidence / persona notes | `skills/_shared/backlog-item-types/product-evidence-lite.md` (omit > fabricate) |
| Optional Valuable check | `skills/_shared/backlog-item-types/invest-and-story-quality.md` |

Do **not** load splitting / feature-altitude / ost-lite / clarify-depth unless the parent asked for sizing advice. Do **not** dump `memory-bank/` or paste a full PRD (`SR-NO-FULL-DUMP` / `SELECTIVE-RETRIEVAL.md`). Cite portable paths only.

## Anti-task-shatter checklist (before promote draft)

Fail the draft (emit note + keep as refine/PLAN step candidate) if **any** apply:

- [ ] Title is verb + file/class/script/path
- [ ] Title is layer-only (e.g. "Domain types", "Infrastructure")
- [ ] Objective is a file/layer checklist instead of one verifiable outcome
- [ ] US missing beneficiary + observable progress (Valuable); TS/Bug may use `n/a` for Who/Job/Outcome

Pass only when title and Objective are **outcome-shaped**.

## Mandatory deep fields

| Section | Rule |
|---------|------|
| **Objective** | One verifiable outcome; outcome-shaped |
| **Who / Job / Outcome** | Required for US; `n/a` each for pure TS/Bug |
| **Fora de escopo (OOS)** | At least one explicit exclusion or honest `N/A` with reason |
| **AC budget** | Happy + rule/edge + failure; each with **observable Then** (`gherkin-budget.md`) |
| **Scorecard (resumo)** | Clareza, Testabilidade, Dependências, **Product depth** (1–5 placeholders OK for human/O1) |
| **Dependências** | Story ids or `none` |

One Given/When/Then stub alone is **not** enough.

## Rules

- Do not write PRD/PLAN here.
- Do not invent multiple stories unless the parent asked for a set.
- Do not invent Evidence, metrics, or PII — omit > fabricate.
- Prefer paths + short summaries from parent; never paste entire bank or PRD body into the draft.

## Output

Return full markdown ready to save as `features/NNN-slug/USnn/STORY.md` (or `TSnn`).
