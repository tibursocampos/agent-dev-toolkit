# 02 — Classic SDD

Classic SDD is three contracts plus a path reader. Orchestrated Delivery **loads** the first three. It does not reimplement them. A team can also start here when one story is already clear and specialist folders are not required.

| Order | Skill | Session rule | Output |
|-------|--------|--------------|--------|
| 1 | `sdd-spec` | This session writes a PRD only | `features/NNN-slug/USnn/PRD/NNN_slug.md` |
| 2 | `sdd-plan` | This session writes a PLAN only | `features/NNN-slug/USnn/PLAN/PLAN_NNN_slug.md` |
| 3 | `sdd-develop` | This session executes **one** PLAN step | Code, tests, PLAN progress |
| — | `read-sdd-artifact` | Read-only, any time | `source_context` envelope |

Default story folder when unspecified is `US01` (or `TSnn` for a technical story). Root-level `PRD/` or `PLAN/` folders are invalid. Global storage uses the SDD root’s `features/` tree for that repo id (`core/sdd/STORAGE.md`).

Plan/Ask mode drafts in chat. Files are written in Agent mode after **sim**.

Invocation context defaults to `direct` unless a parent passes `orchestrated`. That difference matters for missing specialist folders (below). Memory bank is **not** required on this direct path.

## `sdd-spec`

Trigger: `/sdd-spec`, “create spec”, “new feature”.

The PRD answers what and why. It does not contain implementation code. Identifiers stay English. Prose follows the artifact-language resolution in [session behavior](../guides/session-behavior.md). The template includes an execution-policy section.

Process:

1. Resolve storage (repository `features/` or global). First run may ask repository versus global and write `manifest.json`.
2. If the operator cites a markdown file outside `features/` and context is **direct**: read it, draft a PRD, confirm, write under `features/.../PRD/`. O1 is not required first.
3. If a `FEATURE.md` already exists, load story, continuity, refine notes, and specialist folders that the flags require. Prefer those files over repeating questions.
4. **Direct** and a missing specialist folder: ask (create inline, proceed at operator risk, or `/orchestrate-analyze`). Do not hard-stop.
5. **Orchestrated** (this skill called from O2) and a missing specialist folder: stop and return to [O1](01-orchestrated-delivery.md).
6. Collect feature, current behavior, expected behavior, context, and a stable `REQ-NNN` (an external issue id can map onto a REQ). At most a few gap questions, then up to about five clarify questions.
7. Challenge vague acceptance (“works correctly”). Require observable outcomes, explicit out of scope, metrics, MoSCoW, and severity on remaining open questions. Label inferences as invented until **sim** turns them into agreed.
8. Show title, number, portable path, REQ count, and status **Ready for planning** / **Pronto para planejamento**. Wait for **sim** / **ajustar** / **cancelar**.
9. Write the PRD. Run `scripts/validation/validate-prd.ps1`. Non-zero exit stops the handoff.
10. Brownfield: also write `features/NNN-slug/CHANGE.md` and run `validate-change.ps1`. Greenfield does not get an empty CHANGE stub.

`## Related` cites the PLAN only when that file already exists. It cites FEATURE, STORY, CONTINUITY, or ARCH only when those files are on disk.

Next session:

```text
/sdd-plan - features/NNN-slug/US01/PRD/NNN_slug.md
```

## `sdd-plan`

Trigger: `/sdd-plan`, “create plan”, “execution plan”.

A PLAN exists only after a canonical PRD whose status is ready for planning and that has no open question. The PLAN number matches the PRD number and lives in the **same** story folder. Step ids, titles, dependencies, and waves come from `split-story-checklist` (`REFINE/tasks.md`). This skill does not invent steps and does not size them by duration. Steps do not contain code blocks. A new plan is `NOT_STARTED`. Each step starts `PENDING`.

**Thin plan.** SQL, DDL, JSON, and OpenAPI stay in a canonical file (bank phase 2 or story `ARCH/` / `ANALYSIS/`). The PLAN cites that path. If the body does not exist yet: orchestrated runs stop so O1/O2 create it; direct runs create it inline or ask. The PLAN does not paste the body.

Process:

1. Find the PRD under `features/**/PRD/` only. No PRD: either hand off to `sdd-spec`, or the operator explicitly supplies the spec text (pipeline choice 2). A non-canonical markdown file is promoted through `sdd-spec`, not planned in place.
2. Summarize by path. Do not paste the whole PRD back.
3. Call `split-story-checklist` with `source=prd`. Read `REFINE/tasks.md`. Copy each step id, title, dependency, and wave. Map every `REQ-NNN` to one of those steps. Each step acceptance cites a REQ or acceptance id and an observable outcome. Step titles are not only a file, class, or script name.
4. Review the draft, fix it, and review it again. A second failure stops without writing. Then confirm path and step count. **sim** before write.
5. Write steps as `PENDING`, progress `0/N`, refresh `## Related` so PRD and PLAN cite each other. The open-decisions section stays empty.
6. Run `validate-plan` (and `validate-prd` on the source). That check does not replace the two reviews. Failure blocks `/sdd-develop`.

Next session, one step:

```text
/sdd-develop - features/NNN-slug/US01/PLAN/PLAN_NNN_slug.md - Step 1
```

## `sdd-develop`

Trigger: `/sdd-develop`, “implement step”, “execute step”.

Required: the canonical PLAN path and a step id. One session completes one step, including when pacing is `continuous`. The next step is a new chat.

After **sim**, persist `step_confirmed` with `scripts/session/Invoke-DevelopSessionGate.ps1` on `sessions/{repo-hash}/plan-{plan-hash}.json` (or `plan-{plan-hash}-step-{N}.json` when several children share one PLAN). When a ledger claim is required, also `scripts/ledger/Invoke-PlanLedgerClaim.ps1 -Action claim`. Do not hand-edit session JSON in a one-liner.

Process:

1. Plan acquisition **before** any code change. A root or flat PLAN path stops. No PLAN at all offers the pipeline choices; this skill does not create a PRD or PLAN.
2. Confirm the step exists and its dependencies are `COMPLETED`. Show the step id, the counts, and the mode. If the step was `BLOCKED`, say what the block was and that it is gone. Mark the step `IN_PROGRESS` and re-read the PLAN before editing.
3. Use a feature branch (`feature/<slug>` or `feat/<id>`).
4. Implement identifiers in English. Comments follow the surrounding code or a greenfield question. Load structure guidance and **one** matching guideline file for the step (see [04](04-implement-and-guidelines.md)). Do not glob every architecture file.
5. Build and targeted tests. A spawned child returns build, tests, and a short summary.
6. When the step claims acceptance coverage, or evidence level is `cheap` or higher: update `features/NNN-slug/EVD/` and `STATE.md`, run `validate-evidence.ps1`. Failure leaves the step pending. Levels: `off`, `cheap`, `standard`, `strict`.
7. When this step closes the feature wave: append `TRACE.jsonl`, converge, sync current docs, archive, then `validate-trace.ps1 -RequireArchiveComplete`. Mid-feature TRACE is optional. OpenSpec, `.specs/`, and SQLite are not the trace source of truth.
8. Update the PLAN in place (`COMPLETED` only when this step’s acceptance and tests passed; otherwise `BLOCKED` with the cause). Update progress and the checkpoint. Do not record duration. Preserve `## Related`.
9. Report `STEP_COMPLETED` or `STEP_BLOCKED` (step id, validation, next eligible steps, counts, portability). Optional `/commit` after the living-artifact questions (bank refresh-light, project docs) when those trees exist. Silence does not count as skip.

If the parent is `orchestrate-develop`, the child does not own `CONTINUITY.md`. The parent writes that file after the receipt.

Handoff when the PLAN is finished: `/code-review`, then `/run-tests`, then the `security` agent, then `/commit`, then `/push`. Review modes: [05](05-review-and-quality.md).

## `read-sdd-artifact`

Read-only. No **sim** gate and no caveman compression of the result.

It turns one portable path under `features/` into `source_context`: kind, path, feature slug, story id when the path has one, file name. Kinds allowed: FEATURE, STORY, PRD, PLAN. CONTINUITY, ANALYSIS, ARCH, SEC, CHANGE, and memory-bank paths are rejected.

Reject reasons (no partial envelope): `path_traversal`, `outside_features`, `absolute_path_forbidden`, `unsupported_kind`, `not_found`, `empty_path`, `invalid_portable_path`.

A later child that already holds `source_context` for that path does not re-read the file as if the path were opaque. This skill does not author the file.

## Where O2 and O3 sit on these contracts

| Caller | What it adds around the contract |
|--------|----------------------------------|
| `orchestrate-deliver` series | For each story: story files, then spec, then a contest of that PRD, then plan. Parent writes after **sim** |
| `orchestrate-deliver` parallel | Children return drafts only. Parent writes after **sim** using the same contracts |
| `orchestrate-develop` | Child runs this develop contract for exactly one step |
| Direct `/sdd-spec` | No memory-bank gate. Missing specialist folders are a question |

Preflight that blocks O3 (`Invoke-PrdPlanChangePreflight.ps1`) is an O2 check on top of `validate-prd`, `validate-plan`, and `validate-change`. It is not a fourth skill.
