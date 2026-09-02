## CONTINUITY update checklist

Update `CONTINUITY.md` when:

- [ ] Mode série|paralelo chosen
- [ ] Each story PRD+PLAN landed (or batch milestone)
- [ ] Before / after human approval gate
- [ ] Final multi-path handoff emitted
- [ ] Context ≥40% pause (TE02)

| Field | Rule |
|-------|------|
| **Phase** | `deliver` during/after O2 |
| **Last agent** | `orchestrate-deliver` |
| **Memory-bank** | Path + `fresh`\|`refreshed`\|`created` from Step 0; **not** `fresh` if style changed / ARCH approved this feature |
| **Estado atual** | ≤10 lines; which stories done/pending |
| **Decisões** | Append mode + approval scope |
| **Pendências** | Stories still missing PRD/PLAN or approval |
| **Handoff tipado** | Full `/…` lines with **portable paths** (`STORAGE.md` § Portable path) |
| **What not to write** | Full PRD/PLAN bodies, guideline dumps, app code, memory-bank body |

---

## Example handoff - 2 stories (CA4 / RF04)

Feature: `features/004-nuget-extract/`  
Stories approved in O1: `TS01` (package extract), `TS02` (App A consumer).  
Mode: paralelo. After approval:

```text
## Handoff O2 -> develop

Feature: features/004-nuget-extract/

| Story | PRD | PLAN |
|-------|-----|------|
| TS01 | features/004-nuget-extract/TS01/PRD/004_nuget_package.md | features/004-nuget-extract/TS01/PLAN/PLAN_004_nuget_package.md |
| TS02 | features/004-nuget-extract/TS02/PRD/004_app_a_consumer.md | features/004-nuget-extract/TS02/PLAN/PLAN_004_app_a_consumer.md |

### Manual (one PLAN step per session)
/sdd-develop - features/004-nuget-extract/TS01/PLAN/PLAN_004_nuget_package.md - Step 1
/sdd-develop - features/004-nuget-extract/TS02/PLAN/PLAN_004_app_a_consumer.md - Step 1

### Orchestrated (O3)
/orchestrate-develop - features/004-nuget-extract/
```

Global storage: same pattern with InstallRoot-relative portable paths (`sdd/<repo-id>/features/...`) — never OS absolute embeds in CONTINUITY / PRD / PLAN.

---

## Process — CONTINUITY + multi-path handoff (RF04)

On approval:

1. Update `CONTINUITY.md`: **Phase** = `deliver`; **Last agent** = `orchestrate-deliver`; keep **Memory-bank** path + status from Step 0 (`refreshed` if this run refreshed, or if style changed / ARCH was approved this feature — do **not** exit `fresh` in that case); estado atual short per CONTINUITY template; append decisão (série|paralelo); typed handoff with **portable paths** (`STORAGE.md` § Portable path).
2. Optionally update `FEATURE.md` / story statuses to reflect deliver done.
3. Run **cross-artifact analyze** (§ Cross-artifact analyze) — brownfield must have `CHANGE.md`; greenfield must not force an empty CHANGE stub.
4. Run **preflight PRD→PLAN→CHANGE** (`references/preflight-prd-plan-change.md` / `Invoke-PrdPlanChangePreflight.ps1`) per story PLAN. On exit `2` (**block**): fix artifacts; do **not** emit O3 handoff.
5. Emit handoff block listing every PLAN (and PRD) path — § Example handoff + § Canonical invoke strings. Include CHANGE path when present.

Remind (pt-BR): O3 is optional; `sdd-develop` one-step contract unchanged. Classic SDD (`sdd-spec` -> `sdd-plan` -> `sdd-develop`) does **not** require memory-bank (CA7). User picks one path per story/session.

See also § CONTINUITY update checklist.

---

## Cross-artifact analyze (O2 handoff / REQ-004)

Before develop handoff, verify against `CHANGE-CONTRACT.md`:

| Check | Pass |
|-------|------|
| Nature ↔ CHANGE | `brownfield` → `features/NNN-slug/CHANGE.md` exists; `greenfield` → do **not** invent empty CHANGE |
| CHANGE structure | When present: ADDED \| MODIFIED \| REMOVED; `validate-change.ps1` exit 0 |
| Current baselines | CHANGE cites `memory-bank/` (or other living docs) — never `openspec/` / `.specs/` / `.specify/` |
| Complexity ↔ TASKS | `medium` / `complex` → TASKS (`REFINE/tasks.md` or `TASKS.md`); `trivial` (small) → TASKS **not** required |
| Selective retrieval | No full memory-bank / PRD dump in CHANGE or CONTINUITY handoff |

**Mental map (ids unchanged):** O1 `orchestrate-analyze` ≈ explore · O2 `orchestrate-deliver` ≈ FEATURE+PRD+CHANGE · O3 `orchestrate-develop` ≈ apply.

---

## Canonical invoke strings

```text
/orchestrate-deliver - <portable-feature-path>
```

```text
/orchestrate-analyze - <portable-feature-path>
```

```text
/sdd-develop - <portable-plan-path> - Step 1
```

```text
/orchestrate-develop - <portable-feature-path>
```

```text
/sdd-spec
/sdd-plan - <portable-prd-path>
```
