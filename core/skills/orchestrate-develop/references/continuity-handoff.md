## CONTINUITY checklist

Update when:

- [ ] Queue presented / mode (série default)
- [ ] After each child returns
- [ ] Story complete / feature complete
- [ ] Context ≥40% pause
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
| Context pressure (TE02) | Persist CONTINUITY per `context-management.mdc`; resume invoke |
| Context hard-stop | Hard stop; new chat required |
| Child blocked / tests fail | Do not mark step done; report; wait for user |
| User **cancelar** | Leave CONTINUITY with pending next step |

Each child invocation owns exactly one PLAN step and is closed when its receipt is returned. Never reopen, resume, or reuse a returned child invocation; any remaining or corrective work starts as a fresh invocation with a bounded handoff. If the host retains a closed child in its UI, that retention is not a toolkit lifecycle guarantee.

Resume strings: `references/contract-boundaries.md` § Canonical invoke strings.

---

## Process — CONTINUITY fields

On each meaningful milestone (before/after child, pause, story done):

| Field | Rule |
|-------|------|
| **Phase** | `develop` (or `review` when all done) |
| **Last agent** | `orchestrate-develop` |
| **Memory-bank** | Path + status from Step 0 (`fresh` / `refreshed` / `created`) |
| **Estado atual** | Short per CONTINUITY template: active PLAN, last step done, next step |
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
