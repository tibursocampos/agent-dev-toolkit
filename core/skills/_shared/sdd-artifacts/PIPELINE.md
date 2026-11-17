# SDD pipeline contract (spec / plan / implement)

Execution order, approval boundaries, canonical paths, and artifact ownership. Load at **step -1** of `sdd-spec`, `sdd-plan`, `sdd-develop`, and Orchestrated Delivery `orchestrate-*` - do not paste into PRD/PLAN bodies.

Install path after sync: `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/PIPELINE.md`

Companion: `STORAGE.md` (folders, `.gitignore`, **portable path** for artifact cross-refs, **Navigation block** / `## Related`) and `STORAGE-RESOLUTION.md` (manifest / dynamic roots when needed).

**Artifact cross-refs:** FEATURE / CONTINUITY / STORY / PRD / PLAN / ANALYSIS / ARCH / SEC / bank cites and typed handoffs use **portable paths** (`STORAGE.md` § Portable path) — never OS absolute / user-home InstallRoot embeds in written artifacts. Confirm UI may show absolute; Writes use portable paths.

## Navigation block

Normative SoT: `STORAGE.md` § Navigation block (Related). Summary for pipeline / Write skills:

| Rule | Value |
|------|-------|
| Title | `## Related` only (RN05 — **not** `## See also`) |
| Paths | Portable (`STORAGE.md` § Portable path) |
| Omit | Skip sibling if absent — never stub a file only for a link |
| Classic | PRD ↔ PLAN on Write; STORY if on-disk |
| O1+ | Link relevant on-disk siblings (FEATURE / STORY / ANALYSIS\|ARCH\|SEC / PRD / PLAN); CONTINUITY is optional context |

Templates under `skills/_shared/templates/` include the block. Skill Write MUST details belong in `sdd-*` / `orchestrate-*` (not here). Do **not** create `feature-refinement.md`.

## Simplified Delivery contract

This section is the shared source of truth for approval, questions, execution progress, and artifact requirements in Classic SDD and Orchestrated Delivery. It supersedes older per-artifact confirmation, SESSION, claim, and continuity instructions in this guide. Skill procedures may explain how to apply it but must not add duplicate gates.

- **Preparation and approval:** O1/O2 and Classic spec/plan may create and revise draft documents as part of the authorized work. Present the complete PLAN for one explicit approval before implementation. A material change to behavior, acceptance, scope, access, or implementation decisions requires a new decision for the affected work. Writing drafts does not require separate approval.
- **Questions:** block only when an unanswered decision prevents determining behavior, acceptance, scope, required access, or an implementation choice. Keep minor questions and optional improvements visible; independent work may continue.
- **Implementation progress:** the PLAN is the sole persisted progress source for Classic and O1/O2/O3 implementation. Its single execution table records step, dependencies, state, evidence/validation, and blocker/next action. Do not add competing session flags, claims, checklists, CONTINUITY status mirrors, or task-state tables. A live table is a chat projection, owned once by the active coordinator or direct skill per `LIVE-STAGE-TABLE.md`.
- **Cadence:** Classic develop and O3 use the cadence selected at implementation start or persisted in the approved PLAN. `step_by_step` stops after a completed step. `continuous` advances through eligible steps until completion or a real blocker. O3 dispatches one child at a time, one step per child.
- **Legacy context:** existing CONTINUITY, CHANGE, and TASKS files may be consulted when useful. New or resumed work does not require creating, converting, synchronizing, or deleting them. Missing, stale, or conflicting context is reconciled from current canonical requirements and PLAN; ask only when a material ambiguity remains.
- **Preserved authorization:** approval covers only the named PLAN and scope. Dependencies, acceptance, required validation, access controls, path containment, and separately authorized external or destructive actions remain in force. No commit, push, PR, publication, or installation is implied.

### Closeout

At the end of an approved implementation scope, complete the validation required by its PLAN and one substantive review. Reuse a current validation result when it covers the same stack, command, and unchanged working tree; do not rerun a full suite only because review also checks tests. If review leads to an in-scope correction, rerun only validations that the change affects; record when no rerun was needed. Ask for a decision before a material scope or acceptance change. Request security, data, or architecture review when a concrete risk needs it, not as a universal per-step gate. Record results, limits, and remaining blockers in the canonical PLAN evidence; do not add a second progress ledger. O3 and direct Classic use their single live table for any requested closeout activities. ADT retains its closeout checks and records them in its own plan and the same contextual table it already owns.

### Consumer matrix

| Consumer | Simplified contract | Separate contract retained |
|---|---|---|
| Classic `sdd-spec` / `sdd-plan` | Draft writing is part of preparation; no separate write or repeated approval gate. | Canonical feature/story paths and portable references in `STORAGE.md`; direct skill stops at handoff. |
| Classic `sdd-develop` | PLAN-only progress; selected step-by-step or continuous cadence; no SESSION/claim prerequisites. | Approved scope, dependencies, acceptance, required validation, path safety. |
| O1 / O2 | One plan approval before implementation; only material questions block; legacy sidecars optional. | STORY/FEATURE/PRD remain requirement sources when used; scoped specialist evidence stays attributable. |
| O3 | Serial child dispatch and PLAN reconciliation after each step; no claims, SESSION flags, or CONTINUITY progress mirror. | One step per child; parent reviews the result and stops on real blockers or material scope changes. |
| ADT Delivery | Preserve its own plan, approval, cadence, and external progress summary; use the single table-owner rule when it calls internal steps. | ADT skills keep their distinct contracts; this is compatibility guidance, not an ADT redesign. |
| Backlog Refine | STORY remains useful; task breakdown is optional. | Direct refinement and `split-story-checklist` remain independently invocable. |
| `document-implement` and other consumers | Not migrated by this change. | Existing SESSION or task-specific contracts remain only where those consumers explicitly require them. |

## Work tracks

| Track | Flow | Canonical writes |
|-------|------|------------------|
| **Classic SDD** | `sdd-spec` -> `sdd-plan` -> `sdd-develop` | `features/NNN-slug/USnn/{PRD,PLAN}/` (default story `US01`) |
| **Backlog Refine** | `refine-story` -> `split-story-checklist` (-> optional SDD / developer) | Prefer `features/.../STORY.md` + story subfolders; `docs/backlog/` shortcut |
| **Orchestrated Delivery** | `orchestrate-analyze` -> `orchestrate-deliver` -> `orchestrate-develop` **or** manual `sdd-develop` | Same `features/` tree; Memory Bank and CONTINUITY are optional context |

Tracks coexist. Skill ids (`sdd-*`, `orchestrate-*`, `refine-story`, …) are **unchanged**. Classic SDD does not require FEATURE, STORY, Memory Bank, or orchestration. Create ARCH or other specialist analysis only when a concrete decision or risk needs it; brownfield classification alone does not require mirrored architecture documentation. A material architecture choice still needs an explicit decision before dependent implementation.

## Skill order

- **Classic SDD**: Fixed sequence: **`sdd-spec` -> `sdd-plan` -> `sdd-develop`**. Never skip a stage unless shortcut selected. Memory-bank optional.
- **Orchestrated Delivery**: `orchestrate-analyze` (O1) -> `orchestrate-deliver` (O2) -> (`orchestrate-develop` (O3) | `sdd-develop`). O1 investigates proportionally and can prepare independent analysis in parallel. O2 prepares stories and their PRDs/PLANs, then obtains one explicit approval of the complete implementation plan(s). Minor questions do not block unrelated stories. O3 runs serially, one PLAN step per child, and reconciles each result in the PLAN. Closeout validation follows the approved PLAN and relevant repository checks.

| Skill | Writes | Must not in same session |
|-------|--------|
| `spec` | PRD + manifest under feature story | PLAN; production/test code (`*.cs`, migrations, etc.) |
| `plan` | PLAN + manifest under feature story | PRD body; production/test code |
| `sdd-develop` | Code (English) + PLAN progress | New PRD/PLAN files; **multiple PLAN steps** |
| `memory-bank-init` | Resolved `bank_root` (+ `.inventory/`) | App code; bank under `features/`; edit `.gitignore` in global mode |
| `orchestrate-analyze` | FEATURE and justified stories/analysis | App code; promote suggestions to scope without a decision; require CONTINUITY or mirrored ARCH without a concrete need |
| `orchestrate-deliver` | PRD and PLAN per selected story | App code; create mandatory CHANGE/TASKS; require repeated document approvals |
| `orchestrate-develop` | One child per eligible PLAN step; serial reconciliation | App code in parent; more than one step per child; dispatch next step before reconciling prior results |

## Canonical paths

### Valid PRD (classic - new writes)

Preferred (Classic SDD / Orchestrated Delivery):

- `features/NNN-slug/USnn/PRD/NNN_*.md` or `features/NNN-slug/TSnn/PRD/NNN_*.md` (workspace)
- `{{SDD_ROOT}}/<repo-id>/features/NNN-slug/USnn/PRD/NNN_*.md` (global; or manifest classic path)

Classic SDD when story unspecified: use **`US01`**.

`NNN` = three digits. Slug after underscore in filename.

### Valid PLAN (classic - new writes)

- `features/NNN-slug/USnn/PLAN/PLAN_NNN_*.md` (or `TSnn`)
- Global equivalent under `<classic.path>/features/...`

PLAN `NNN` **must match** source PRD `NNN`.

### Forbidden paths (not used)

Do **not** read, write, or continue Classic SDD from:

- Repo-root `PRD/` / `PLAN/` / `docs/PRD/` / `docs/PLAN/` (gitignore safety net only - not an active flow)
- Global-flat `{{SDD_ROOT}}/<repo-id>/PRD/` or `.../PLAN/` outside `features/`
- Loose `REFINE/`, `ANALYSIS/`, `ARCH/`, `SEC/` at repo root
- `{{TOOLKIT_ROOT}}/` outside `sdd/<repo-id>/features/` (classic)
- `docs/backlog/*.md`, arbitrary `docs/*.md`, repo-root `*.md` without feature tree

**O3 input:** `orchestrate-develop` / `sdd-develop` execute from the canonical PLAN under `features/`; existing relevant memory-bank files may be consulted when available. A cited plan scratch file can be read as input but is not itself the canonical O3 execution PLAN.

### Use of cited material

Read cited files that are relevant and authorized. Synthesize their material into the canonical PRD or PLAN when useful; a citation, rich content, or host plan scratch file does not require a separate promotion artifact. Preserve the cited source unless the user asks to replace or delete it. New canonical PRD/PLAN files still use the feature paths below. O3 execution always resolves its PLAN from the canonical feature tree.

Manifest-backed roots resolve per `STORAGE-RESOLUTION.md` (`features/` root).

## Host session mode

**Product limit:** In **Plan** and **Ask**, `Write`/`Edit` and often shell are blocked. User permission in chat does not enable disk writes. This is not an invocation context (`INVOCATION-CONTEXTS.md`).

| Phase | Modes | Actions |
|-------|-------|---------|
| **A - Collect & draft** | Plan, Ask, Agent | Questions, `Read`/Glob/Grep, PRD/PLAN draft in chat |
| **B - Persist** | **Agent** only | Persist authorized documents; `sdd-develop` code; `test-coverage` and `run-tests` runs |

| Mode | `sdd-spec` / `sdd-plan` | `sdd-develop` | `test-coverage` | `run-tests` |
|------|-----------------|-------------|-----------------|-------------|
| Agent | Write within authorized task scope | Allowed | Allowed | Allowed |
| Plan | Phase A only; no `Write`; never claim “saved” | Draft/analysis only; no `Edit` on code | Explain tests need Agent | Explain tests need Agent |
| Ask | Same as Plan | Block code changes | Block test execution | Block test execution |

### Phase A complete - explain host limitation

Render the prompt in the user chat language (`LANGUAGE.md`). Meaning:

```text
Draft ready. To write the file at `{path}` (or to run tests),
switch to the mode that can persist and send:

/<name> - write

(Optional: paste the PRD/PLAN path if it is already chosen.)
```

If the user stays in Plan: continue Phase A only. Never state that a PRD or PLAN was saved without a successful `Write`.

## Plan approval boundary

Draft preparation and saving are part of the authorized specification/planning workflow. Before code changes begin, present the complete implementation PLAN and obtain one explicit approval. Do not add separate PRD-content, PLAN-write, or artifact-write gates. Reopen approval only for a material change to the approved outcome, acceptance, scope, access, or implementation decisions.

## Prior context (chat, Plan, code-review, feature tree)

When the thread already has requirements, review findings, or refined backlog:

- Do **not** run the full `spec` questionnaire.
- Provide a structured summary + all necessary gap questions, in blocks of at most **5**.
- Map code-review items to PRD sections (acceptance criteria, risks, out of scope) per `spec/reference.md`.
- Prefer current, relevant sources over re-asking. A cited file may be used directly when authorized; no promotion copy is required solely to make it context.
- **Selective retrieval** (`SELECTIVE-RETRIEVAL.md`, rule `SR-NO-FULL-DUMP`): **must not** dump entire `memory-bank/` or paste the full PRD into prompts/handoffs — cite portable paths; read named bank files only. Enforcement: `scripts/validation/Assert-CoreContracts.ps1`.

### Feature / story siblings (Classic SDD / Orchestrated Delivery)

When the working path is under `features/NNN-slug/` (or the user names that feature):

1. Read the canonical PRD/PLAN and any existing FEATURE/STORY/ANALYSIS/ARCH/SEC/CONTINUITY/CHANGE/TASKS material that is relevant to the current decision.
2. Do not require a sidecar because a flag, brownfield label, or old scaffold names it. Create or update specialist analysis only for a concrete question, risk, or decision within the approved scope.
3. Ask focused questions only when a material decision remains open. Minor questions do not stop unrelated work.
4. Keep retrieval selective: summarize and cite paths; do not dump full guidelines, a whole memory bank, or full PRD bodies.

If no `features/` artifacts exist, do **not** fall back to root `PRD/`/`PLAN/` for new canonical artifacts. Use the demand or cited material to create the appropriate artifact under `features/...`.

## Missing canonical artifact

Use the demand and available evidence to prepare missing PRD/PLAN artifacts within the authorized workflow. `sdd-plan` may work directly from a sufficiently specified demand when no PRD exists. `sdd-develop` needs an executable PLAN; if none exists, prepare it when requirements are sufficient, or ask only for the missing material input. Do not force a fixed choice menu or invent product behavior.

### Path validation helper

Before `Write`, confirm the target matches **new-write** patterns:

- PRD: `features/[^/]+/(US|TS)\d+/PRD/\d{3}_.+\.md` (workspace-relative) or same under `.../sdd/<repo-id>/features/`
- PLAN: `features/[^/]+/(US|TS)\d+/PLAN/PLAN_\d{3}_.+\.md` or global equivalent

Root or flat `PRD/` / `PLAN/` paths are not new canonical destinations. Read a relevant user-cited plan as input and use the canonical feature path for new PLAN writes; do not require a separate promotion artifact.

### Classic SDD path example (full)

```text
features/004-export-profile/US01/PRD/004_export_profile.md
features/004-export-profile/US01/PLAN/PLAN_004_export_profile.md

/sdd-plan - features/004-export-profile/US01/PRD/004_export_profile.md
/sdd-develop - features/004-export-profile/US01/PLAN/PLAN_004_export_profile.md - Step 1
```

If validation fails, correct the new destination before writing.

## Integration

| Consumer | Use |
|----------|-----|
| `sdd-spec`, `sdd-plan`, `sdd-develop` | Step -1 load; steps reference § by name |
| `orchestrate-*` | Orchestrated Delivery order; relevant feature context when present |
| `refine-story`, `split-story-checklist` | Backlog Refine; prefer feature STORY paths |
| `STORAGE.md` | Folders, `.gitignore`, portable paths, invalid-path summary |
| `STORAGE-RESOLUTION.md` | Manifest schema and dynamic repository/global roots |
| `rules/sdd-pipeline-guards.mdc` | Short always-on reminder |
| `code-review` | Handoff to `sdd-spec` for new PRD; read-only SDD discovery |
| `test-coverage` | Phase B / Agent for shell; report paths in `reference.md` |
| `run-tests` | Phase B / Agent for shell; does not replace `test-coverage` |
