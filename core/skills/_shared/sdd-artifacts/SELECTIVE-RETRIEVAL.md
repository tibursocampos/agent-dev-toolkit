# Selective retrieval (SDD contracts)

Install path after sync: `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/SELECTIVE-RETRIEVAL.md`

**Language:** This guideline is **English**. Chat prompts to the operator mirror the **user chat language** (`LANGUAGE.md`).

Companion: `PIPELINE.md` § Prior context and `MEMORY-BANK.md` § Selective read. These selective-read rules are independent of context-usage thresholds.

---

## Purpose

Keep token use low and context lean for Classic SDD / Backlog Refine / Orchestrated Delivery **without** a second SoT (no SQLite/FTS in this contract). Agents load **only** the paths needed for the current skill step.

## Verifiable rule

**Rule ID:** `SR-NO-FULL-DUMP`

Skills and guides in scope **must not** prescribe a full dump of:

| Corpus | Forbidden prescription examples |
|--------|----------------------------------|
| `memory-bank/` | "dump entire memory-bank", "paste all bank files", "load every file under memory-bank/" |
| PRD | "paste the full PRD into the prompt", "include the entire PRD body in context" |

**Allowed (and required):** selective path lists, summaries, portable path cites, "never dump" / "must not dump" prohibitions, gap-question block limits.

### In-scope files (US 005 PASSO 1+)

| Path | Role |
|------|------|
| `core/skills/sdd-spec/SKILL.md` | Enforce selective Prior context |
| `core/skills/sdd-spec/reference.md` | Template pointer + quality gates |
| `core/skills/sdd-plan/SKILL.md` | Summarize PRD; do not paste full body into PLAN/chat dumps |
| `core/skills/sdd-plan/reference.md` | Template pointer + quality gates |
| `core/skills/refine-story/SKILL.md` | Lean intake; no bank/PRD dump |
| `core/skills/refine-story/references/boundary.md` | Boundaries (no bank/PRD dump) |
| `core/skills/refine-story/references/guardrails.md` | Guardrails / checklist |
| `core/skills/_shared/templates/sdd/PRD.md` | REQ/AC/OOS contract |
| `core/skills/_shared/templates/sdd/PLAN.md` | REQ→step + selective note |
| This file | Normative rule |

### Enforcement

| Check | How |
|-------|-----|
| Documented | This file + skill Must-not / Process bullets |
| Automated smoke | `scripts/validation/Assert-CoreContracts.ps1` (exit ≠ 0 if a dump prescription is found, or required anti-dump markers are missing) |

Fail the assert → fix the skill/guide text before marking CA1 / REQ-002 done.

## Operating procedure (agents)

1. Prefer **paths + short summaries** over bodies.
2. `memory-bank/`: read only named files needed for the step (e.g. `architecture.md`, `tech-stack.json`); never recurse-load the whole tree into the prompt.
3. PRD: `Read` for authoring/planning; do **not** paste the full PRD into CONTINUITY, child Task prompts, or PLAN bodies — cite the **portable path**.
4. Prior context: structured summary + all necessary gap questions, in blocks of at most **5** (`PIPELINE.md`).
5. Challenge vague acceptance language before writing REQ/AC (see `sdd-spec` / `refine-story`).

### Evidence decisions

For each question, state the fact that would answer it, then use this sequence:

1. **Select relevant evidence.** Open candidate sources whose subject and scope match the requested fact. Treat keyword overlap as a discovery hint only: compare each source's subject and claim with the question, then reject out-of-scope decoys from both the evidence set and citations. Prefer a source that directly states the fact over a merely similar or adjacent source.
2. **Establish a gap before returning `insufficient`.** Inspect the available sources that match the question's subject and scope. Cite the relevant source(s) checked and name the specific requested fact they do not establish. Do not infer that evidence is absent merely because the first candidate does not answer the question.
3. **Surface contradictions.** When relevant sources make incompatible claims, inspect and cite both claims, identify the disagreement, and return `conflict`. Do not silently choose one by recency or wording. Resolve it only when the sources themselves establish an authoritative supersession or scope distinction; cite that basis.
4. **Stop at sufficient evidence.** Once the relevant source or sources support the answer, stop retrieval. Do not load adjacent files, broad indexes, or unrelated context “just in case”; expand the search only when a concrete gap or contradiction requires it.

## Bounded retrieval evaluation

When a task changes retrieval guidance, memory indexes, or handoffs, compare the current behavior against the synthetic cases in `scripts/validation/fixtures/selective-retrieval-evaluation/`. The set covers a relevant source with an overlapping irrelevant decoy, unavailable evidence, and contradictory sources. Submit a report using `report.template.json`, then run `scripts/validation/Compare-SelectiveRetrieval.ps1` with the case set and report.

The comparison checks reported outcome (`answered`, `insufficient`, or `conflict`), required consulted/cited paths, and whether irrelevant or unavailable paths were used. Every report must include non-empty `runMetadata.host`, `runMetadata.retrievalGuidanceRevision`, and `runMetadata.runLabel`; use `unknown` when a value cannot be identified. For `insufficient`, cite the relevant source that establishes what is missing; do not report no evidence without inspecting the available sources. These are bounded path/oracle checks; they do not establish that answer prose is semantically correct or that a live host behaves the same. A human reviewer must assess answer meaning separately. `semanticReview` must be `not-reviewed`, `pass`, or `fail`: `not-reviewed` means semantic quality was not assessed and is **not** a semantic PASS. The evaluator reports objective path/outcome status separately; any `semanticReview: fail` makes the overall evaluation `REVIEW-FAIL` even when objective checks pass. Record token and duration metrics only when exposed by the host; otherwise omit them or mark them unavailable. The checked-in reference report is synthetic evaluator self-test data, not evidence of live-agent behavior.

## Checklist (manual CT5)

- [ ] No in-scope skill instructs dumping all of `memory-bank/`
- [ ] No in-scope skill instructs pasting the entire PRD into prompts/handoffs
- [ ] Each in-scope skill cites this file or restates `SR-NO-FULL-DUMP`
- [ ] `Assert-CoreContracts.ps1` (SelectiveRetrieval section) exits 0

## Must not

- Treat SQLite/FTS as the retrieval solution for this rule
- Invent `openspec/` / `.specs/` / `.specify/` trees for selective context
- Weaken this rule in touched skills for "convenience"
