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
| Spec | `{{TOOLKIT_ROOT}}/skills/sdd-spec/SKILL.md` | Canonical PRD under story `PRD/` |
| Plan | `{{TOOLKIT_ROOT}}/skills/sdd-plan/SKILL.md` | Canonical PLAN under story `PLAN/` |

## Reconcile before advancing a story

Before treating a story output as accepted, resuming it, or emitting its O2 handoff, reconcile the material content against the consumer and the existing owner contracts (`SEMANTIC-SUFFICIENCY.md`, `ARTIFACT-OWNERSHIP.md`, `CONTRACT-PROVENANCE.md`, and `RECEIPT.md`):

1. **Check identity and material section.** Match a supplied `source_context` envelope's schema, kind, portable path, and applicable feature/story/file identity to the expected story artifact. A matching envelope avoids an opaque reread solely to rediscover identity. It does not establish approval, freshness, the body or section content, or sufficiency for a material question. When the needed body/section is absent, relevant content changed, or a material fact is missing, read only the current section needed to resolve that gap; record why the read is needed. A wrong identity blocks that story.
2. **Check the output, approval, and recorded validation.** Confirm the expected canonical output exists for this story, the applicable existing approval is recorded, and every validation outcome required by the owning contract is recorded with its real result. A child/task `done`, receipt, path, identifier, or envelope alone is not the artifact, approval, or validation result. Missing output, approval, or required result blocks this story and names the existing owner and next gate; do not execute an owner's process by shortcut.
3. **Check each dependency boundary.** For every dependent US/TS being advanced, compare the upstream output with that consumer's declared input, output, and applicable rules. Confirm the relevant normative section supports the dependency, not merely that IDs or paths link. If a required input is missing, claims conflict, or a boundary is incompatible, do not write or advance that story; stop only its affected branch and return reconciliation to the existing owner and approval gate. Keep independent stories eligible and preserve their own gates.
4. **Classify changes before resuming.** Use `CONTRACT-PROVENANCE.md`'s existing change classes at the affected consumer boundary. Formatting or operational drift does not invalidate work after semantic equivalence is confirmed. A material or incompatible change requires its existing owner to reconcile affected content and obtain applicable approval before consumers rely on it. Do not infer that an old approval covers changed material content; do not automatically invalidate or edit every downstream artifact.

Keep these findings in the existing story result, approval, and O2 handoff. Do not add a hash/tag, workflow status, receipt field, ledger, or parallel state source. O2 remains `orchestrated`; this check does not change the `direct` fallback or any source owner's write/dependency gate.

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

When external evidence is cited by O1 as `external:<alias>/<relative-path>`, preserve the exact alias and relative path in the PRD / PLAN evidence section and the O3 handoff wherever that evidence is needed for a PLAN step. Never substitute an absolute root or a repository-relative guess. This carries the reference only: O2 does not authorize aliases. Before O3 dispatch, its coordinator must authorize the alias and relevant path prefix and supply a separate alias-to-root map; O3's receipt guard accepts the alias only from that map plus the coordinator scope (`STORAGE.md` § External evidence references for O3; `RECEIPT.md`).

**Per-story STOP:** if this story still lacks a flag-gated required sibling (`ANALYSIS/` / `ARCH/` / `SEC/`): **STOP** that story — do **not** Write PRD/PLAN; return to O1. Max-3 gap questions do **not** replace this gate.

**Per-story readiness STOP:** any unanswered question on the required story files, including `MINOR`, stops that story with `open_question`. Do not write the PRD. Folder presence ≠ READY (**RN02**). The max-3 gap-question cap does not apply to this gate.

**Brownfield analysis sufficiency:** before writing this story's PRD, inspect the required `ANALYSIS/` / `ARCH/` content against `{{TOOLKIT_ROOT}}/skills/_shared/agents/BROWNFIELD-ANALYSIS.md` and the affected scope. Confirm relevant conventions and impacts are backed by repository paths, confidence is stated, and reuse, affected areas, and material gaps are recorded using the artifact owner's format. Artifact/folder presence or unsupported generic defaults do not establish sufficiency. If a material evidence gap could change this story's contract or plan, request targeted repository investigation where feasible; if it remains unresolved, stop this story before PRD/PLAN and return the gap to O1. Technical pattern discovery is repository investigation, not a product question when behavior and acceptance are clear. Preserve the specialist's analysis ownership; O2 evaluates and consumes it without silently replacing it.

Order per story. Do not jump from spec to plan.

1. Check `STORY.md` and the `ANALYSIS/`, `ARCH/`, and `SEC/` folders required by `needs_*`. Run the same research as `{{TOOLKIT_ROOT}}/skills/refine-story/references/feature-research.md`. For brownfield, also apply the sufficiency check above to the required analysis content. An unanswered product/contract question stops **this** story with `open_question`; insufficient material technical evidence stops it for targeted investigation/return to O1, not by inventing a generic convention. Do not write the PRD. A stuck story does not erase the others and does not re-slice the feature.
2. `sdd-spec` writes the PRD under `features/NNN-slug/{USnn|TSnn}/PRD/`. Then run the contestation in `{{TOOLKIT_ROOT}}/skills/refine-story/references/tech.md` § Story PRD contestation on that PRD. An open question means the PRD is not accepted. Do not call the plan.
3. Only after that acceptance, the parent runs `split-story-checklist` when FEATURE complexity is `medium` or `complex`. That skill writes `REFINE/tasks.md`. `trivial` does not get the file. The parent does not ask `sdd-plan` to create it.
4. Only then `sdd-plan`. It reads the checklist ids. If `medium` or `complex` and `REFINE/tasks.md` is missing, `sdd-plan` coordinates `split-story-checklist` (native specialist when available, owner workflow inline otherwise), validates the canonical output, then resumes this same plan. The owner skill remains the only checklist writer; its gates and open questions remain active. Failure or invalid output blocks this story. O2's normal route should still run the checklist before calling `sdd-plan`:

```text
/split-story-checklist - features/NNN-slug/{USnn|TSnn}/STORY.md
/sdd-plan - features/NNN-slug/{USnn|TSnn}/PRD/NNN_*.md
```

`trivial` features do not get a tasks file.

The PIPELINE cap of 3 gap questions does **not** apply to `open_question`. Ask every open question.

| Stage | Contract | Must follow |
|-------|----------|-------------|
| Story files | `feature-research.md` | Required siblings; any open question, including `MINOR`, stops this story |
| Spec | `sdd-spec` | PRD in the chat language; no PLAN in this stage; no app code; `## Related` (REQ-009); contestation before the PRD is accepted |
| Checklist | `split-story-checklist` | After contestation accepts the PRD; medium/complex only; sole writer of `REFINE/tasks.md`; also callable by `sdd-plan` recovery when missing |
| Plan | `sdd-plan` | After contestation and, when required, a valid checklist. May coordinate the owner skill only for a missing checklist; validates and preserves IDs. Two self-reviews and the preview before write. The parent does not accept a PLAN that skipped them and does not rewrite the plan sections |

**Navigation (REQ-009 / CA3):** Parent Writes of PRD/PLAN **MUST** honor `sdd-spec` / `sdd-plan` Related obligations (`STORAGE.md` § Navigation block). Classic minimum: **PRD ↔ PLAN** mutual portable-path cite when both exist; cite **STORY** if on-disk; upward FEATURE / CONTINUITY only when present. **Omit-if-absent** — never stub siblings solely for links. After each story lands, refresh CONTINUITY / FEATURE / STORY Related edges for new PRD/PLAN paths (still paths-only — not a second navigation SoT).

**Série:** for each story S, run its story-file gate, spec, contestation, checklist when required, plan, and applicable approval gate in that order. **sim** does not skip an open question, contestation, or another story's gate. After the current story's applicable approval is recorded, recompute the eligible queue from canonical feature/story artifacts and dependencies; do not rely on a possibly stale `CONTINUITY.md` alone. Read the next eligible US/TS `STORY.md`, required siblings, and relevant feature context before starting its complete O2 cycle. Continue automatically without an extra “continue?” question. Stop for a material blocker, a decision or approval gate actually due, or when every story is closed. A previous story's approval never authorizes the next story's artifact writes; all per-story owner and write gates remain in force. A blocker affects only its dependent branch when other stories remain eligible.

**Paralelo (native only):** one gate per wave. Do not draft a PLAN in the same return as a PRD that still has an open question or that has not passed contestation. Do not draft the plan before `REFINE/tasks.md` exists when the feature is medium or complex. Child returns notes or a draft only. Child must **not** `Write` PRD/PLAN to disk. Parent writes after the gate for that artifact is clear. If Task is unavailable, run série in-parent. Do not hard-fail.

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
