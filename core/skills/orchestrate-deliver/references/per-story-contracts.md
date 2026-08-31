## Per-story path layout

```text
features/NNN-slug/
├── FEATURE.md
├── CONTINUITY.md
├── US01/
│   ├── STORY.md
│   ├── PRD/
│   │   └── NNN_short_slug.md          # sdd-spec contract
│   └── PLAN/
│       └── PLAN_NNN_short_slug.md     # sdd-plan contract
└── TS01/
    ├── STORY.md
    ├── PRD/
    │   └── NNN_ts01_slug.md
    └── PLAN/
        └── PLAN_NNN_ts01_slug.md
```

| O2 writes | O2 does **not** write |
|-----------|------------------------|
| `…/PRD/*.md`, `…/PLAN/*.md` via sdd contracts | App/test source |
| Updates to `CONTINUITY.md` / status fields | Repo-root `PRD/` / `PLAN/` |
| | Implementation via `sdd-develop` / O3 (handoff only) |

`NNN` in PRD/PLAN filenames **matches** feature `NNN`. Prefer short English slug per story.

Artifact prose default **pt-BR**; identifiers and skill names **English**.

---

## Contract reuse (do not fork)

| Stage | Load and follow | Output |
|-------|-----------------|--------|
| Spec | `skills/sdd-spec/SKILL.md` | Canonical PRD under story `PRD/` |
| Plan | `skills/sdd-plan/SKILL.md` | Canonical PLAN under story `PLAN/` |

Prior context for each story: `STORY.md` + `REFINE/` when present (optional / on demand) + `ANALYSIS|ARCH|SEC` when FEATURE flags (or brownfield) require them (**not** optional in that case) + feature `FEATURE.md` / `CONTINUITY.md`. Prefer promoted siblings/bank over re-asking. Max **3** gap questions if Prior context incomplete (`PIPELINE.md`). Max-3 gap questions do **not** replace the required-siblings STOP: missing `ANALYSIS/` / `ARCH/` / `SEC/` when flags require them → **STOP** / return to O1; do **not** Write PRD/PLAN.

Parent must **not** invent a shorter “PRD lite” process that skips confirm-before-write or acceptance sections required by those skills.

---

## Process — Per-story contracts

For each story in the work list:

**Target paths** (`PIPELINE.md` canonical):

```text
features/NNN-slug/{USnn|TSnn}/PRD/NNN_*.md
features/NNN-slug/{USnn|TSnn}/PLAN/PLAN_NNN_*.md
```

**Input to contracts:** `STORY.md` + `REFINE/` when present (on demand) + `ANALYSIS|ARCH|SEC` when FEATURE flags (or brownfield) require them + feature `FEATURE.md` / `CONTINUITY.md` + selective `memory-bank/` paths from Step 0 (Prior context - max 3 gap questions total per story if needed). Prefer promoted siblings/bank over re-asking.

**Per-story STOP:** if this story still lacks a flag-gated required sibling (`ANALYSIS/` / `ARCH/` / `SEC/`): **STOP** that story — do **not** Write PRD/PLAN; return to O1. Max-3 gap questions do **not** replace this gate.

| Stage | Contract | Must follow |
|-------|----------|-------------|
| Spec | `sdd-spec` | Confirm-before-write; pt-BR PRD; no PLAN; no app code |
| Plan | `sdd-plan` | Requires PRD on disk; baby-step PLAN; no app code |

**Série:** for story S: load `sdd-spec` -> write PRD after **sim** -> load `sdd-plan` -> write PLAN after **sim** -> optional per-story approval -> next story.

**Paralelo (native only):** when `subagents=native`, spawn Task with prompt that: (1) reads story siblings + **memory-bank path** (read-only, selective), (2) drafts PRD then PLAN content for **that story only** (in the Task return - markdown bodies or structured sections), (3) returns **intended** paths + 5-bullet summary + draft text, (4) **must not** `Write` PRD/PLAN to disk. Parent aggregates drafts -> presents for approval -> on **sim**, parent runs `sdd-spec` / `sdd-plan` contracts and performs the only disk writes. Else (**fallback**): run série **in-parent** — do not hard-fail for missing Task.

Respect story **deps**: do not parallelize a story before its dependency stories have PRD+PLAN (or user explicitly waives). Waive-deps is for **story order** only — not for missing `SEC/` / `ARCH/` / `ANALYSIS`.

See also § Contract reuse + § Task child prompt skeleton + § Per-story path layout.

---

## Task child prompt skeleton (paralelo)

Give each child:

1. Full story path + feature path
2. Instruction: draft PRD then PLAN content for **this story only** using `sdd-spec` / `sdd-plan` structure - **do not** `Write` files to disk
3. Prior-context files to Read (list paths; do not paste bodies)
4. Intended canonical paths for PRD and PLAN (for the return payload)
5. Return format: `{ storyId, prdPath, planPath, prdDraft, planDraft, bullets[≤5], blockedReason? }`
6. Must not: app code; other stories; expand roster; disk Write of PRD/PLAN

Parent merges drafts -> human **sim** -> parent runs `sdd-spec` / `sdd-plan` contracts and performs the only disk writes.
