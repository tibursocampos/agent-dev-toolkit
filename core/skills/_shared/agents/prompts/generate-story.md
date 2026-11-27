# Stage prompt: generate story

## Caveman / receipt

When parent reports `caveman_mode` ON, compress the conversational wrapper only. Never omit or shorten required findings, evidence, limits, alternatives, affected work, validation, or artifact content. Any required receipt must retain every required field and value; do not replace it with shorthand or append a generic finding receipt unless assigned. Follow this prompt's `## Output`. Use refusal tokens only when applicable.

Draft one deep `STORY.md` (US or TS) for the feature tree. **Not** a single Gherkin stub or empty contract.

## Language

- Artifact prose: **content-language** per `_shared/agents/LANGUAGE.md` (inferred from chat; invocation/prefs/manifest overrides; `null` ≠ pt-BR). Do **not** hard-code a locale.
- Prompt body / receipt fields: **en-US** (this file is an internal prompt).
- Identifiers, paths, skill/ref names: **English**

## Template

Use `skills/_shared/templates/features/story/STORY.md` structure end-to-end.

## Inputs

The parent provides the feature path, authorized story scope, source demand, and relevant evidence or canonical paths. Draft one US or TS story only unless the parent explicitly requests a set. Ask the parent about a missing material decision; do not fill it by inference.

## Output

Return one complete Markdown `STORY.md` draft ready to save as `features/NNN-slug/USnn/STORY.md` (or `TSnn`), following the canonical template's headings, order, and applicable fields. The parent consumes the draft for review and persistence. Include specified acceptance, exclusions, dependencies, evidence, and quality fields with evidence-based content; omit absent optional content instead of inventing it.

The full draft is the primary deliverable and must not be compressed. When Caveman is on, append only the compact completion receipt required by `_shared/agents/RECEIPT.md`; do not repeat the draft in the receipt.

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

## HIGH density (feature / story draft)

Before returning the draft, ensure:

| Check | Rule |
|-------|------|
| Outcome-shaped title + Objective | Fail anti-task-shatter; no verb+path titles |
| AC budget | Happy + rule/edge + failure; observable Then each |
| OOS | At least one exclusion or honest `N/A` + reason |
| Provenance | Do not invent Evidence / metrics / PII (`omit > fabricate`); mark agent fill-ins if parent asked |
| Selective retrieval | Paths + short excerpts only — no full PRD / `memory-bank/` dump |
| No org-only tags | Do **not** emit lifecycle-tags / org-only tracker markup |

Parent synthesizes chat in user language; this child stays **en-US** for receipts.
