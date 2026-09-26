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

Artifact prose follows the user chat language (`LANGUAGE.md`). Identifiers and skill names stay English. Do not hard-code a locale.

---

## Contract reuse (do not fork)

| Stage | Load and follow | Output |
|-------|-----------------|--------|
| Spec | `skills/sdd-spec/SKILL.md` | Canonical PRD under story `PRD/` |
| Plan | `skills/sdd-plan/SKILL.md` | Canonical PLAN under story `PLAN/` |

Prior context for each story: `STORY.md` + `REFINE/` when present (optional / on demand) + `ANALYSIS|ARCH|SEC` when FEATURE flags (or brownfield) require them (**not** optional in that case) + feature `FEATURE.md` / `CONTINUITY.md`. Prefer promoted siblings/bank over re-asking. Max **3** gap questions if Prior context incomplete (`PIPELINE.md`). Max-3 gap questions do **not** replace the required-siblings STOP: missing `ANALYSIS/` / `ARCH/` / `SEC/` when flags require them → **STOP** / return to O1; do **not** Write PRD/PLAN. Open **B**/**I** on Prior/STORY/REFINE → **STOP** Write; `NEEDS_CLARIFICATION` (`readiness-severity.md`); presence ≠ READY (**RN02**).

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

**Per-story readiness STOP:** any unanswered question on the required story files, including `MINOR`, stops that story with `open_question`. Do not write the PRD. Folder presence ≠ READY (**RN02**). The max-3 gap-question cap does not apply to this gate.

Order per story. Do not jump from spec to plan.

1. Check `STORY.md` and the `ANALYSIS/`, `ARCH/`, and `SEC/` folders required by `needs_*`. Run the same research as `refine-story/references/feature-research.md`. An open question in any of those files stops **this** story with `open_question`. Do not write the PRD. A stuck story does not erase the others and does not re-slice the feature.
2. `sdd-spec` writes the PRD under `features/NNN-slug/{USnn|TSnn}/PRD/`. Then run the contestation in `refine-story/references/tech.md` § Story PRD contestation on that PRD. An open question means the PRD is not accepted. Do not call the plan.
3. Only then `sdd-plan`.

The PIPELINE cap of 3 gap questions does **not** apply to `open_question`. Ask every open question.

| Stage | Contract | Must follow |
|-------|----------|-------------|
| Story files | `feature-research.md` | Required siblings; any open question, including `MINOR`, stops this story |
| Spec | `sdd-spec` | PRD in the chat language; no PLAN in this stage; no app code; `## Related` (REQ-009); contestation before the PRD is accepted |
| Plan | `sdd-plan` | Only after the PRD has no open question; two self-reviews and the preview before write; the parent does not accept a PLAN that skipped them; the parent does not rewrite the plan sections |

**Navigation (REQ-009 / CA3):** Parent Writes of PRD/PLAN **MUST** honor `sdd-spec` / `sdd-plan` Related obligations (`STORAGE.md` § Navigation block). Classic minimum: **PRD ↔ PLAN** mutual portable-path cite when both exist; cite **STORY** if on-disk; upward FEATURE / CONTINUITY only when present. **Omit-if-absent** — never stub siblings solely for links. After each story lands, refresh CONTINUITY / FEATURE / STORY Related edges for new PRD/PLAN paths (still paths-only — not a second navigation SoT).

**Série:** for story S, run the three steps above. **sim** does not skip an open question. Then optional per-story approval, then the next story.

**Paralelo (native only):** one gate per wave. Do not draft a PLAN in the same return as a PRD that still has an open question. Child returns notes or a draft only. Child must **not** `Write` PRD/PLAN to disk. Parent writes after the gate for that artifact is clear. If Task is unavailable, run série in-parent. Do not hard-fail.

Respect story **deps**: do not parallelize a story before its dependency stories have PRD+PLAN (or user explicitly waives). Waive-deps is for **story order** only — not for missing `SEC/` / `ARCH/` / `ANALYSIS`.

See also § Contract reuse + § Task child prompt skeleton + § Per-story path layout.

---

## Task child prompt skeleton (paralelo)

Give each child:

1. Full story path + feature path
2. Instruction: draft only the artifact the current gate allows for **this story**. Do not draft a PLAN while the PRD still has an open question. **Do not** `Write` files to disk.
3. Prior-context files to Read (list paths; do not paste bodies)
4. Intended canonical paths for PRD and PLAN (for the return payload)
5. Return format: `{ storyId, prdPath, planPath, prdDraft, planDraft, bullets[≤5], blockedReason? }`
6. Must not: app code; other stories; expand roster; disk Write of PRD/PLAN

Parent merges drafts -> human **sim** -> parent runs `sdd-spec` / `sdd-plan` contracts and performs the only disk writes.
