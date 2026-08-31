# Skill reference retrieval (lazy-load contract)

Install path after sync: `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/SKILL-REFERENCE-RETRIEVAL.md`

**Language:** This guideline is **English**. Chat prompts to the operator stay **pt-BR** per toolkit policy.

Companion: `SELECTIVE-RETRIEVAL.md` (`SR-NO-FULL-DUMP`), skill `SKILL.md` Lazy-load tables, `reference.md` indexes under `references/` (or `reference/` for skills that use that folder, e.g. impeccable).

---

## Purpose

Applies to **all invocable skills**. Keep context lean by loading **only** the reference section needed for the current Process step — not entire monolithic `reference.md` files when a section-specific file exists under `references/` (or `reference/`).

## Verifiable rule

**Rule ID:** `SR-LAZY-REFERENCE`

When a skill ships `references/<section>.md` (or `reference/<section>.md`):

1. **Never** Read the full `reference.md` if a section-specific file exists for the current step.
2. Read `reference.md` **only** as a routing index (≤50 lines) to pick the correct section file.
3. Load **one** section file per Process step unless the step explicitly lists multiple sections.

## Mandatory sections (all invocable skills)

Every invocable skill (`core/skills/*/SKILL.md` with YAML `name:`) **must** include:

| Section | Required content |
|---------|------------------|
| `## Lazy-load` | Situational routing table (`When` \| `Path`) |
| `**Never by default:**` | Explicit list of paths/skills **not** to preload at skill start |

**Reference routing (optional table):** Orchestrate skills (`orchestrate-*`) and other skills that already ship a `## Reference routing` table map situations to `references/<section>.md`. Skills without that heading still satisfy this contract via `## Lazy-load` + Process step paths — do **not** invent a Reference routing section solely to match orchestrate layout.

## Operating procedure (agents)

1. Start with `SKILL.md` gate + Lazy-load (and Reference routing **when present**) only.
2. For Process step *N*, Read `references/<section>.md` (or `reference/<section>.md`) named in that step (or Reference routing row when the skill has one).
3. Do **not** glob-read all files under `references/` / `reference/` at skill start.
4. If `reference.md` has no split folder and is ≤150 lines, reading the full file is allowed.
5. If `references/` or `reference/` exists, treat `reference.md` as index-only — never load it for procedural detail.

## Split layout (when extended detail is needed)

Use this layout when a skill needs more procedural detail than fits in `SKILL.md` — **not** every invocable skill must split. Thin skills may keep a short `reference.md` (≤150 lines) with no `references/` folder.

```text
skill-id/
  SKILL.md              # gates + Lazy-load + **Never by default:** + Process (paths to references/)
  reference.md          # index only (≤50 lines) → references/ (or reference/)
  references/           # preferred: one concern per file
    section-a.md
    section-b.md
    ...
```

Alternate folder name (existing convention): `reference/` (singular) — e.g. `impeccable/reference/`. Assert accepts either `references/` or `reference/` as a valid split.

Examples that use the split: `orchestrate-analyze`, `orchestrate-deliver`, `orchestrate-develop`, and Wave 1A skills such as `code-review`, `open-github-pr`, `test-coverage`, `sdd-develop`, `refine-story`, `split-story-checklist`, `document-plan`, `commit`.

## Enforcement

| Check | How |
|-------|-----|
| Documented | This file + skill Lazy-load (and Reference routing when present) |
| Automated | `scripts/validation/Assert-SkillLazyLoad.ps1` |

Fail conditions (blocking):

- Invocable skill missing `## Lazy-load` table (`When` \| `Path`)
- Invocable skill missing `**Never by default:**`
- `reference.md` >150 lines without `references/` **or** `reference/` split

Soft warning only: `reference.md` index >50 lines when a split folder exists.

Fail the assert → fix the skill before marking lazy-load reference work done.

## Must not

- Preload full `reference.md` when a section file exists for the current step
- Omit `## Lazy-load` or `**Never by default:**` from invocable skills
- Use `reference.md` as a second SKILL body (>50 lines when a split folder exists)
- Treat reading all `references/*.md` / `reference/*.md` as default context assembly
- Require a `## Reference routing` table on skills that only use Lazy-load + Process paths
- Assume the split layout applies only to `orchestrate-*` skills (or that every skill must split)
