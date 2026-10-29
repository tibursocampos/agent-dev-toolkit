## CONTINUITY checklist

Update when:

- [ ] Queue presented / mode (série default)
- [ ] After each child returns
- [ ] Story complete / feature complete
- [ ] Before code-review handoff

| Field | Rule |
|-------|------|
| **Phase** | `develop` until all planned work done -> `review` |
| **Last agent** | `orchestrate-develop` |
| **Memory-bank** | Path + status from Step 0 |
| **Estado atual** | ≤10 lines |
| **Handoff tipado** | Exact next `/…` with **portable paths** (`STORAGE.md` § Portable path) |
| **Related** | Keep/refresh `## Related` with portable paths to on-disk siblings only — **omit-if-absent**. CONTINUITY carries **handoff paths**, not a second navigation SoT (006 REQ-009 / `STORAGE.md` § Navigation block) |
| **What not to write** | Full code diffs, guideline dumps, memory-bank body |

For each PLAN in a feature, keep one machine-checkable `## Estado atual do O3` block in CONTINUITY, derived from the saved and re-read PLAN. The O3 state is one block per PLAN, keyed by the portable PLAN path in its `PLAN` field; a feature with four TS PLANs has four such blocks. Required fields use this exact shape and portable PLAN path:

```text
## Estado atual do O3
- PLAN: `features/NNN-slug/USnn/PLAN/PLAN_NNN_*.md`
- Progresso: 2/5
- Concluídos: S1, S2
- Próximo: S3 — <exact PLAN step title>
```

Each write updates only the block whose `PLAN` field names the PLAN it wrote. It never edits, copies, or fills another PLAN's block. GAP and DEF lines go in the block of the PLAN that owns them. Use `none` for an empty completed list or no next step. Before each session/claim/spawn, the O3 preflight locates the block keyed by the validated PLAN path and compares only that block to the PLAN's saved progress table, step states, order, and dependencies. A missing block for that PLAN, or any block for another PLAN, does not satisfy the check: the preflight fails closed with `continuity_o3_block_missing`. Missing or stale fields block the queue until the parent reconciles CONTINUITY. The PLAN remains the sole queue/dependency source.

---

## Example - serial two steps then review

Feature: `features/004-nuget-extract/`  
PLAN: `features/004-nuget-extract/TS01/PLAN/PLAN_004_nuget_package.md`

```text
## O3 run

1) sim -> one child invocation (sdd-develop Step 1) -> child closes -> CONTINUITY update
2) new chat or sim -> one fresh child invocation (sdd-develop Step 2) -> child closes -> …
3) TS01 complete -> handoff:

/code-review
/code-review - single
/code-review - multi-angle

# Manual alternative anytime:
/sdd-develop - features/004-nuget-extract/TS01/PLAN/PLAN_004_nuget_package.md - Step 3
```

---

## Handoff copy

```text
## Handoff O3

Scope closed. Next, in order:
1) /run-tests
2) /code-review
3) /run-tests after review changes (or record that no changes required a rerun)
4) security role/prompt review of the diff: `{{TOOLKIT_ROOT}}/skills/_shared/agents/prompts/security.md`
5) /commit
6) /push

## Continuar develop manual (alternativa a O3)
/sdd-develop - <portable-plan-path> - Step {N}

## Continuar O3
/orchestrate-develop - <portable-feature-path>
```

At scope close the order is required: `run-tests`, then `code-review`, then `run-tests` after review changes, then the security role/prompt review of the diff, then ask `/commit`, then ask `/push` separately. If the review makes no changes, record that the post-review test rerun was not required before security. The canonical security handoff is the `security` role/prompt at `{{TOOLKIT_ROOT}}/skills/_shared/agents/prompts/security.md`; use only a documented host spawn mechanism or the bounded in-parent fallback. Do not invent or claim a `/security` command. Do not offer code-review versus commit in the middle of the steps. Render the prompt in the user chat language.

For a requested O3 wave close, show the separate chat-only closeout table defined in `LIVE-STAGE-TABLE.md`. Its rows carry the applicable gate status, owner, current evidence, or next action; do not persist that table in `CONTINUITY.md`. If later changes affect a gate's evidence, mark only that gate's result stale/pending, retain unaffected evidence, and resume the required closeout order before advancing.

## Approved decisions in handoffs

Before an implementation or review handoff, include a compact decision envelope when an operator-approved decision applies to that step or review scope:

| Field | Required content |
|-------|------------------|
| **Source** | Portable canonical PRD/PLAN path plus section and REQ/CA when the decision is recorded there; otherwise a concise reference to the operator approval in the active run. |
| **Decision** | Short statement of the approved constraint or direction, without expanding its meaning. |
| **Applies to** | Exact PLAN step, acceptance criterion, or review scope affected. |
| **Required handling** | What the recipient must preserve or verify within the existing acceptance. |

Include only decisions relevant to the recipient. Do not paste full chat, PRD, or PLAN bodies. Omit decisions that do not apply. A `CONTINUITY.md` note may point to the source, but it is not a second authority for requirements or acceptance.

If a decision would materially change scope or acceptance, stop that handoff and return the change to the PLAN owner for an explicitly approved revision. A correction that remains within the approved acceptance can continue in its authorized step. Review handoffs carry the applicable decision and source so the reviewer can assess the current implementation against the agreed constraint.

For a review handoff, also point to the existing PLAN step notes and EVD/STATE rows that carry material operator requests or corrections. The reviewer reconciles each applicable item with the current diff and its result evidence; CONTINUITY carries only the pointer and unresolved dependencies. Do not create a second correction ledger or copy full conversation text.

### Before `/commit` from O3

Step N already asked memory-bank **refresh-light** when app code changed. Still ask project docs when present (**sim** / **pular**), then `/commit`:

```text
Posso atualizar a documentação do projeto? (sim / pular)
```

On **sim**: pending `docs/documentation-plan/plan.md` → `/document-implement`; else → `/document-plan` as needed. On **pular**: continue to `/commit`. If Step N was skipped (no app changes) but `memory-bank/` exists, also ask bank **sim/pular** before commit (same wording as Step N).

---

## Process — Stop conditions

Stop spawning and emit handoff when any of:

| Event | Action |
|-------|--------|
| Story PLAN all steps complete | Offer next story or code-review |
| Feature all PLANs complete | Phase -> review; code-review handoff |
| Context hard-stop | Hard stop; new chat required |
| Child blocked / tests fail | Do not mark step done; report; wait for user |
| User **cancelar** | Leave CONTINUITY with pending next step |

Each child invocation owns exactly one PLAN step and is closed when its receipt is returned. Never reopen, resume, or reuse a returned child invocation; any remaining or corrective work starts as a fresh invocation with a bounded handoff. If the host retains a closed child in its UI, that retention is not a toolkit lifecycle guarantee.

Resume strings: `references/contract-boundaries.md` § Canonical invoke strings.

---

## Write-consistency rules (SDDW)

- **SDDW-05 (CONTINUITY current state):** Every write that changes a story PLAN progress rewrites only the `## Estado atual do O3` block keyed by that PLAN's path in the same write, and never another PLAN's block, so `Progresso` and `Concluídos` equal the saved PLAN counts and completed step ids. Each accepted `GAP-NN` or `DEF-NN` id defined in that story PRD is named in CONTINUITY; an omitted accepted gap is stale state. Reconciliation: re-read the PLAN and compare each block field before reporting done.
## Process — CONTINUITY fields

On each meaningful milestone (before/after child, pause, story done):

| Field | Rule |
|-------|------|
| **Phase** | `develop` (or `review` when all done) |
| **Last agent** | `orchestrate-develop` |
| **Memory-bank** | Path + status from Step 0 (`fresh` / `refreshed` / `created`) |
| **Estado atual** | Short per CONTINUITY template: active PLAN, last step done, next step |
| **O3 Current State** | Persist one `## Estado atual do O3` block per PLAN, keyed by its PLAN path, progress, completed IDs, and exact next PLAN step title; derive from saved/re-read PLAN and pass `Invoke-O3ArtifactPreflight.ps1` before session, claim, or spawn |
| **Handoff tipado** | Exact next `/…` with **portable paths** (`STORAGE.md` § Portable path) |

Do not paste full diffs, guideline bodies, or memory-bank body into CONTINUITY. CONTINUITY owns phase/handoff; bank does not replace it. Do **not** invent a parallel navigation index — Related is path edges only (`STORAGE.md` § Navigation block / 006 REQ-009).

See also § CONTINUITY checklist.

---

## Process — Step N refresh-light

When this O3 run had at least one successful develop child that changed application files, **before** the final review handoff:

1. Resolve `bank_root` (same as Step 0).
2. Ask (pt-BR): `Posso atualizar o memory-bank (refresh-light) em '{bank_root}'? (sim / pular / cancelar)`
3. On **sim**: follow `memory-bank-init` mode **`refresh-light`** (inventory + GENERATED + `tech-stack.json` only).
4. Update CONTINUITY Memory-bank status to `refreshed` (or note skipped).
5. On **pular**: log and continue handoff without bank write.

If no app code changed this run, skip Step N. See also `references/preconditions.md` § Step N - refresh-light.
