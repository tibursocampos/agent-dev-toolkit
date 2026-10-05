## Preflight PRD → PLAN → CHANGE (REQ-004 / CA4)

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
3. On block: fix artifacts; do **not** start O3.
4. Smoke: `scripts/validation/Assert-PrdPlanChangePreflight.ps1`.

Selective retrieval: cite paths; never dump full PRD or `memory-bank/` (`SR-NO-FULL-DUMP`).
