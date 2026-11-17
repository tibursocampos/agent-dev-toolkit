# Portable agent roster (Orchestrated Delivery)

Shared prompts and roles for `orchestrate-*` subagents. **English** prompt bodies. Keep this roster small - do **not** add 40 agent files.

Install path after sync: `{{TOOLKIT_ROOT}}/skills/_shared/agents/`

**Spawn / degrade:** `SPAWN.md` (capability `subagents`, native vs fallback, child limits, no guideline paste). Do **not** duplicate that policy here.

**Subagent model policy:** `SUBAGENT-MODEL.md` (omit `model` by default; one session question for a different pair).

**Receipt:** `RECEIPT.md` (lazy-load when Caveman ON or child returns findings).

## Roster (maximum)

| Role id | When to spawn | Minimum assignment input | Writes (under feature/story) | Expected result / receipt meaning | Must not |
|---------|---------------|-------------------------|------------------------------|----------------------------------|----------|
| `repo-analyst` | Brownfield / impact unclear / `needs_api` | Question and affected repository paths; local instructions and representative evidence to inspect | `ANALYSIS/` notes (**folder on disk**) | Findings use the finding contract in `RECEIPT.md`; Agent outcome is separate. Parent checks the assigned artifact. | App code; invent APIs; CONTINUITY-only substitute |
| `architect` | `needs_domain`, cross-cutting design, **greenfield**, or **brownfield** (mirror) | Problem, scope, constraints, relevant repository evidence, and the design decision or mirror analysis needed | `ARCH/` notes (**folder on disk**; draft until confirm on greenfield) | `done`: scoped design result delivered; `blocked`: decision/confirmation/input missing; `failed`: design attempt failed. `done` does not bypass an applicable approval gate. | App code; corporate patterns; silent style default; final ARCH before operator **sim** on greenfield; skip ARCH on brownfield |
| `security` | `needs_security` | Threat surface, assets/trust boundaries, and affected paths or components | `SEC/` notes (**folder on disk**) | `done`: scoped review delivered; `blocked`: required evidence/scope missing; `failed`: review attempt failed. Parent checks the assigned review scope. | compliance theater; route findings to CONTINUITY instead of `SEC/` |
| `database` | `needs_database` or brownfield with persistence | Persistence scope, relevant schema/data contracts, and affected paths | `ARCH/` DB slice (**folder on disk**) | `done`: assigned data design/migration result delivered; `blocked`: required schema/input unavailable; `failed`: assigned work failed. Parent checks step acceptance and required validation. | Force a vendor; corp DBA rules; CONTINUITY-only substitute |
| `developer-child` | A stack `*-developer` flow delegates implementation | Approved task/PLAN excerpt, writable paths, relevant local patterns, and required scoped validation | Scoped code changes | Reduced receipt: `{ files[], testsSummary }`; no `planPath` or `step`. `testsSummary` states the scoped validation actually performed; deferred tests remain explicit. Parent owns PLAN/session reconciliation. | PLAN edits or state; add relay-only fields; build outside the requested US-close flow |
| `shell-runner` | A bounded script/batch/build/test command is explicitly authorized | Exact command, working directory, allowed evidence path, and scope limits | Command output/evidence path only | Command receipt: exact scoped commands, exit result, portable evidence path, next action. Build is assigned only at US close when applicable. | App code/design; duplicate parent-run commands; unbounded command suites |
| `qa_checklist` | Before handoff / review | Story/CONTINUITY path and acceptance criteria to cover; this role is not an Agent spawn | Checklist bullets in CONTINUITY or STORY only | Parent-authored checklist context; no Agent receipt or terminal Agent status. | Write production tests silently; **no** Agent spawn; **no** `prompts/qa*.md` file |

## qa_checklist (HIGH — in-parent only)

`qa_checklist` is a **role**, not an Agent specialist. Parent (or refine/O1 handoff) writes checklist bullets into CONTINUITY or STORY. It does not return an Agent receipt and cannot set persisted step state. Do **not** create `prompts/qa*.md`. Do **not** emit org-only lifecycle-tags / org-prefixed tokens.

Minimum HIGH checklist before handoff / review (adapt to story; keep portable paths):

| Area | Bullet intent |
|------|---------------|
| AC coverage | Each CA / AC has an observable Then or explicit deferred note |
| Gates | SESSION / confirm-before-write / architecture confirm respected when applicable |
| Language | Artifacts = content-language; identifiers English; no hard-coded locale (`LANGUAGE.md`) |
| Provenance | Invented gaps labeled; secrets redacted (`CONTRACT-PROVENANCE.md`) |
| Selective retrieval | No full bank/PRD dump in handoff notes |
| OOS | Explicit exclusions still honored; no silent scope creep |
| Tests | Test plan or evidence pointer present when complexity ≥ medium |

Stacks (`react`, `dotnet`, …) are **not** duplicated here - route via existing `*-developer` skills (`ROUTING.md`).

## Flags (`needs_*`) - canonical spawn map (O1 source of truth)

Set on `FEATURE.md` during O1 triage. Spawn an Agent specialist **only** when the flag is **true**. `orchestrate-analyze` SKILL must point here - do not maintain a divergent table in the SKILL body.

| Flag | Spawn when true | Specialist / action | Prompt |
|------|-----------------|---------------------|--------|
| `needs_api` | A concrete API / package / integration question affects behavior, scope, or acceptance | `repo-analyst` (+ `architect` when a material contract decision needs design); persist useful findings in the canonical story/feature artifact or a justified `ANALYSIS/` note | `prompts/repo_analyst.md` (+ optionally `architect.md`) |
| (brownfield / impact unclear) | A specific unresolved current-behavior or impact question could change scope, acceptance, risk, or implementation | Select only the specialist needed for that question (`repo-analyst`, `architect`, and/or `database`); no mirrored architecture or analysis artifact based on brownfield classification alone | Relevant specialist prompt(s) |
| (greenfield / no established style) | A material architecture choice is required to define behavior, boundaries, or implementation | `architect` may present options and a recommendation; request an operator decision only when the choice materially blocks the approved outcome or implementation; persist the decision where useful | `prompts/architect.md` + `code-guidelines/principles/architecture-selection.md` |
| `needs_domain` | A concrete domain / cross-cutting design question affects the feature | `architect` when specialist reasoning is useful; record relevant decisions in the canonical feature/story artifact or a justified `ARCH/` note | `prompts/architect.md` |
| `needs_database` | A persistence or schema decision is within scope and affects the design | `database`; record the relevant decision in the canonical artifact or a justified `ARCH/` database slice | `prompts/database.md` |
| `needs_frontend` | UI work requires specialist analysis during O1 | No O1 Agent by default; route via `ROUTING.md` at implementation and persist a material analysis only when useful | - |
| `needs_security` | Auth, secrets, PII, supply-chain, or threat-surface evidence needs specialist analysis | `security`; persist findings in the canonical artifact or a justified `SEC/` note | `prompts/security.md` |
| `needs_devops` | Deployment or pipeline behavior is material to the feature | Consult a specialist only when a concrete question needs it; persist useful findings in the canonical artifact or a justified analysis note | - |

### Implementer, finding, verifier, and relay contracts

- `developer-child` uses its reduced receipt in `RECEIPT.md`; stack `*-developer` prompts remain responsible for their own implementation details and do not emit the O3 relay receipt.
- Finding specialists (`repo-analyst`, `architect`, `security`, `database`) use the finding contract. Their severity labels are mapped in `RECEIPT.md` and must not be collapsed into readiness or terminal status.
- The O3 implementer (`sdd-develop`) returns the canonical relay receipt defined in `RECEIPT.md`, including optional `deletedFiles[]` for removed paths. The parent validates it against PLAN, session, and claim before reconciliation.
- The optional read-only verifier uses its verifier contract; it cannot implement, edit PLAN, or substitute for evidence validation.
- `prompts/` is canonical. `core/agents/` files are thin discoverable wrappers; `shell-runner` and `developer-child` also have canonical prompt files because roster/workflow consumers call them.

**Specialist evidence:** a flag or brownfield classification alone does not require a specialist folder or sidecar. Persist material decisions in the canonical FEATURE/STORY when appropriate; create ANALYSIS/ARCH/SEC only when a distinct evidence record is useful. O1 may prepare and revise backlog artifacts without a separate backlog approval gate. Optional CONTINUITY notes are not required to represent specialist findings.

**Material architecture decision:** do not require a confirmation solely because the repository is greenfield, lacks an established style, or is brownfield. If a concrete choice materially affects the intended behavior, acceptance, scope, or implementation, present it to the operator and resolve it before dependent work; otherwise record useful evidence and continue without an ARCH approval gate. Brownfield classification alone never requires mirrored architecture, database, or pipeline notes.

**TE01 / security signals:** Prefer `false` for ambiguous flags **except** when auth, secrets, PII, feed tokens, or supply-chain appear in the description - then ask explicitly or set `needs_security=true` (do not default those signals to `false`).

## Triage

| Dimension | Values |
|-----------|--------|
| Nature | `greenfield` \| `brownfield` \| `operational` |
| Complexity | `trivial` \| `medium` \| `complex` |
| Scope | `backend` \| `frontend` \| `fullstack` |

| Complexity | Suggested path |
|------------|----------------|
| `trivial` | `developer` / stack skill (skip O1) |
| `medium` | Classic SDD or Backlog Refine |
| `complex` | Orchestrated Delivery O1 |

## Prompt files

| File | Use |
|------|-----|
| `prompts/repo_analyst.md` | Impact / brownfield map (role `repo-analyst`) |
| `prompts/architect.md` | Solution shape; greenfield → architecture-selection + user confirm |
| `prompts/security.md` | Security subset review |
| `prompts/database.md` | Data model / migration risks |
| `prompts/developer-child.md` | Reduced-receipt implementation child for stack `*-developer` flows |
| `prompts/shell-runner.md` | Bounded command execution and command receipt |
| `prompts/impact.md` | Stage: impact summary |
| `prompts/risk.md` | Stage: risk register |
| `prompts/generate-story.md` | Stage: draft US/TS STORY.md |

`qa_checklist` has **no** prompt file - it is a CONTINUITY/STORY checklist role only (validators must not require `prompts/qa*.md`).

## Must not

- Port org-only tracker/IdP agents
- Create one file per aspirational design-md agent
- Let orchestrator parent implement application code

## Depth

Depth is 1. The parent spawns the specialist and receives the result. The specialist does not spawn another specialist.
