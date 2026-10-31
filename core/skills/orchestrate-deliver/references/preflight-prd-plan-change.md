## Preflight PRD → PLAN → CHANGE

Before emitting O3 / `orchestrate-develop` handoff, run structural preflight so inconsistent artifacts **block** with an explicit reason — never silently ignore.

Canonical script:

```text
pwsh -NoProfile -File "{{TOOLKIT_ROOT}}/scripts/validation/Invoke-PrdPlanChangePreflight.ps1" -FeatureRoot <features/NNN-slug> -PlanPath <portable-plan-path>
```

Exit codes: `0` allow · `2` block · `1` usage.

### What it checks (deterministic)

| Check | Reason code | Notes |
|-------|-------------|-------|
| `validate-prd` | `validate_prd_failed` | Invokes existing script — does **not** replace it |
| `validate-plan` (+ PRD) | `validate_plan_failed` | Invokes existing script — does **not** replace it |
| PLAN REQ not in PRD | `orphan_req` | Extra consistency beyond validate-plan coverage |
| PRD vs PLAN filename NNN | `nnn_mismatch` | Also feature-folder NNN when `NNN-slug` leaf |
| Brownfield CHANGE missing/invalid | `change_missing_brownfield` / `change_brownfield_invalid` | Uses `validate-change` + `CHANGE-CONTRACT.md`; orchestrated mode remains strict |

Messages use **portable paths** only (`STORAGE.md` § Portable path). Preflight is **read-only** — zero app-code mutation.

### Invocation context and direct-risk registration

The script defaults to `-InvocationContext orchestrated`; a missing brownfield
`CHANGE.md` blocks with `change_missing_brownfield`. Direct Classic SDD may choose
an explicit risk continuation:

```text
pwsh -NoProfile -File "{{TOOLKIT_ROOT}}/scripts/validation/Invoke-PrdPlanChangePreflight.ps1" \
  -FeatureRoot <features/NNN-slug> -PlanPath <portable-plan-path> \
  -InvocationContext direct -AllowDirectRisk \
  -DirectRiskOwner <owner> \
  -DirectRiskBaseline <portable-current-baseline> \
  -DirectRiskPath CHANGE.md
```

All three direct-risk fields are required. `DirectRiskPath` and
`DirectRiskBaseline` must be portable paths without absolute or parent
segments. A durable registration must also be present in the PLAN or its
cited `ANALYSIS/ARCH` note, using this machine-readable form:

```text
<!-- direct-risk: owner=<owner>; baseline=<portable-baseline>; path=<portable-path> -->
```

Without that matching registration, direct mode blocks with
`direct_change_confirmation_required`. The waiver never applies to
orchestrated mode, and it does not skip validation when `CHANGE.md` exists.

### Operator / O2 wire

1. After PRD/PLAN approval and cross-artifact analyze (`references/continuity-handoff.md`).
2. Run preflight per story PLAN (or batch stories).
3. On block: inspect the reason and the matching validator/preflight condition, then reconcile the affected artifact through its existing owner contract: `sdd-spec` owns PRD and CHANGE; `sdd-plan` owns PLAN. For a structural or cross-artifact defect whose approved meaning is unchanged and supported by available evidence, the O2 parent makes the bounded correction (or starts a fresh scoped specialist draft when the current invocation uses parallel drafts), reruns the failing validator and this preflight, and continues the same O2 run when it returns `ALLOW`. Do not ask the operator to relay routine diagnostics or perform these corrections manually. Preserve existing approval and write gates; if a correction changes material approved behavior, invoke the existing content/write approval gates again. A missing decision, unavailable evidence/access, conflicting source, or repeated failure with no new evidence remains a blocker: ask only for the specific missing input and do **not** start O3. Never weaken a validator to clear the block.
4. Smoke: `scripts/validation/Assert-PrdPlanChangePreflight.ps1`.

Selective retrieval: cite paths; never dump full PRD or `memory-bank/`.
