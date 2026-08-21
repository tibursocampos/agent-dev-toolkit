# Selective retrieval (SDD contracts)

Install path after sync: `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/SELECTIVE-RETRIEVAL.md`

**Language:** This guideline is **English**. Chat prompts to the operator stay **pt-BR** per toolkit policy.

Companion: `PIPELINE.md` § Prior context, `MEMORY-BANK.md` § Selective read, `context-management.mdc`.

---

## Purpose

Keep token use low and context lean for Classic SDD / Backlog Refine / Orchestrated Delivery **without** a second SoT (no SQLite/FTS in this contract). Agents load **only** the paths needed for the current skill step.

## Verifiable rule (CT5 / REQ-002)

**Rule ID:** `SR-NO-FULL-DUMP`

Skills and guides in scope **must not** prescribe a full dump of:

| Corpus | Forbidden prescription examples |
|--------|----------------------------------|
| `memory-bank/` | "dump entire memory-bank", "paste all bank files", "load every file under memory-bank/" |
| PRD | "paste the full PRD into the prompt", "include the entire PRD body in context" |

**Allowed (and required):** selective path lists, summaries, portable path cites, "never dump" / "must not dump" prohibitions, max gap-question caps.

### In-scope files (US 005 PASSO 1+)

| Path | Role |
|------|------|
| `core/skills/sdd-spec/SKILL.md` | Enforce selective Prior context |
| `core/skills/sdd-spec/reference.md` | Template pointer + quality gates |
| `core/skills/sdd-plan/SKILL.md` | Summarize PRD; do not paste full body into PLAN/chat dumps |
| `core/skills/sdd-plan/reference.md` | Template pointer + quality gates |
| `core/skills/refine-story/SKILL.md` | Lean intake; no bank/PRD dump |
| `core/skills/refine-story/reference.md` | Boundaries + guardrails |
| `core/skills/_shared/templates/sdd/PRD.md` | REQ/AC/OOS contract |
| `core/skills/_shared/templates/sdd/PLAN.md` | REQ→step + selective note |
| This file | Normative rule |

### Enforcement

| Check | How |
|-------|-----|
| Documented | This file + skill Must-not / Process bullets |
| Automated smoke | `scripts/validation/Assert-SelectiveRetrieval.ps1` (exit ≠ 0 if a dump prescription is found, or required anti-dump markers are missing) |

Fail the assert → fix the skill/guide text before marking CA1 / REQ-002 done.

## Operating procedure (agents)

1. Prefer **paths + short summaries** over bodies.
2. `memory-bank/`: read only named files needed for the step (e.g. `architecture.md`, `tech-stack.json`); never recurse-load the whole tree into the prompt.
3. PRD: `Read` for authoring/planning; do **not** paste the full PRD into CONTINUITY, child Task prompts, or PLAN bodies — cite the **portable path**.
4. Prior context: structured summary + **at most 3** gap questions (`PIPELINE.md`).
5. Challenge vague acceptance language before writing REQ/AC (see `sdd-spec` / `refine-story`).

## Checklist (manual CT5)

- [ ] No in-scope skill instructs dumping all of `memory-bank/`
- [ ] No in-scope skill instructs pasting the entire PRD into prompts/handoffs
- [ ] Each in-scope skill cites this file or restates `SR-NO-FULL-DUMP`
- [ ] `Assert-SelectiveRetrieval.ps1` exits 0

## Must not

- Treat SQLite/FTS as the retrieval solution for this rule
- Invent `openspec/` / `.specs/` / `.specify/` trees for selective context
- Weaken this rule in touched skills for "convenience"
