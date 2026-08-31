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
| **Handoff tipado** | Portable path `/…` (`STORAGE.md` § Portable path) |
| **What not to write** | Full code diffs, guideline dumps, memory-bank body |

---

## Example - serial two steps then review

Feature: `features/004-nuget-extract/`  
PLAN: `features/004-nuget-extract/TS01/PLAN/PLAN_004_nuget_package.md`

```text
## O3 run

1) sim -> Task(sdd-develop Step 1) -> CONTINUITY update
2) new chat or sim -> Task(sdd-develop Step 2) -> …
3) TS01 complete -> handoff:

/code-review
/code-review - single
/code-review - multi-angle

# Manual alternative anytime:
/sdd-develop - features/004-nuget-extract/TS01/PLAN/PLAN_004_nuget_package.md - Step 3
```

---

## Handoff copy (pt-BR / strings)

```text
## Handoff O3 -> review

/code-review
/code-review - single
/code-review - multi-angle

## Continuar develop manual (alternativa a O3)
/sdd-develop - <portable-plan-path> - Step {N}

## Continuar O3
/orchestrate-develop - <portable-feature-path>
```

Handoff `/code-review` (user may pass `- single` / `- multi-angle`; if omitted, skill asks). Never required; does not auto-block pipeline.

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

Do not paste full diffs, guideline bodies, or memory-bank body into CONTINUITY. CONTINUITY owns phase/handoff; bank does not replace it.

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
