# PLAN-LEDGER contract (atomic step claim)

Install path after sync: `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/PLAN-LEDGER-CONTRACT.md`

**Language:** This guideline is **English**. Identifiers, paths, field names, and event reasons stay **English**. Operator chat mirrors the **user chat language** (`LANGUAGE.md`).

Companion: `SESSION.md` (repo vs develop gates), `SELECTIVE-RETRIEVAL.md`, `PIPELINE.md`. Skill wire: `skills/sdd-plan/references/plan-ledger.md`.

---

## Purpose

Guarantee **at most one active holder** per PLAN step. When two agents race to claim the same step, **one claim prevails** and the other **fails audibly** (structured reason + audit trail).

This contract is **operator governance** for O3 / parallel `sdd-develop` children. For O3, the parent is the sole lifecycle owner: it acquires one claim before dispatch, keeps it active while the child may run, reconciles the returned receipt against SESSION and the durable PLAN checkpoint, then releases it. The child verifies the matching parent claim with `status` and never reacquires or releases it. Direct invocations without a parent-held claim retain their own lifecycle. This contract does **not** replace SESSION gates (`step_confirmed` / `tests_run`).

## Scope

| In scope | Out of scope (this contract) |
|----------|------------------------------|
| Claim / status / release for a PLAN step | Execution modes / queue policy (`orchestrate-develop` PASSO 3) |
| Atomic file create under sessions ledger | Consumer application code |
| Auditable reject on double-claim | Pinning child model ≠ parent |

## Ledger location

Under the SDD **sessions** root (same tree as `SESSION.md`):

```text
{sessionsRoot}/{repo-hash}/ledger/plan-{plan-hash}-step-{N}.claim.json
{sessionsRoot}/{repo-hash}/ledger/plan-{plan-hash}-step-{N}.audit.jsonl
```

| Token | Rule |
|-------|------|
| `{repo-hash}` | First 16 hex of SHA256 of normalized `$Cwd` (forward slashes, no trailing slash) — same as `SESSION.md` |
| `{plan-hash}` | First 16 hex of SHA256 of normalized **absolute** PLAN path (forward slashes, no trailing slash) |
| `{N}` | 1-based PLAN step number |

Prefer portable PLAN paths in claim payloads (`features/.../PLAN/PLAN_*.md`). Confirm UI may show absolute; **written** `plan_path` fields use portable form when under the repo.

## Claim file schema

```json
{
  "schema": "plan-ledger-claim/v1",
  "plan_path": "features/NNN-slug/TSnn/PLAN/PLAN_NNN_slug.md",
  "step": 2,
  "holder": "spawn-or-agent-id",
  "claimed_at": "2026-09-02T17:00:00Z",
  "status": "claimed"
}
```

| Field | Rule |
|-------|------|
| `schema` | Exact `plan-ledger-claim/v1` |
| `plan_path` | Portable when possible |
| `step` | Positive integer |
| `holder` | Non-empty opaque id (O3 parent lifecycle id or direct invocation id); the O3 parent passes it to the child as `claim_holder` |
| `claimed_at` | UTC ISO-8601 |
| `status` | `claimed` \| `released` (active hold = file exists with `claimed`) |

**Active claim:** file exists and `status` is `claimed`. Release deletes the claim file **or** rewrites `status` to `released` then deletes — implementations must not leave a second agent able to treat a stale `claimed` as free without an explicit release path.

## Atomic claim algorithm

1. Resolve ledger directory; create `{sessionsRoot}/{repo-hash}/ledger/` if missing.
2. Target path = `plan-{plan-hash}-step-{N}.claim.json`.
3. Attempt **atomic create-new** (fail if exists). Write UTF-8 JSON body with `status=claimed`.
4. On success: exit **0**; print claim JSON (or a thin success envelope).
5. On exists: do **not** overwrite. Append one audit line; exit **non-zero** with auditable reason including **existing holder**.

Recommended Windows primitive: `FileMode.CreateNew` (or equivalent “create only if absent”). Do not use “read then write” as the sole race control.

## Auditable failure

On double-claim (and other reject paths), append to the sibling `.audit.jsonl` (create if missing), one JSON object per line:

```json
{
  "at": "2026-09-02T17:00:01Z",
  "event": "claim_rejected",
  "reason": "step_already_claimed",
  "plan_path": "features/.../PLAN_....md",
  "step": 2,
  "attempted_holder": "agent-B",
  "existing_holder": "agent-A"
}
```

Stdout/stderr **must** include a human-readable line with `reason`, `existing_holder`, and `attempted_holder` so operators can verify CA2 without opening the audit file.

## Actions

| Action | Behavior |
|--------|----------|
| `claim` | Atomic create; O3 parent calls exactly once; reject if held |
| `status` | Report free / held + holder (exit 0 even when held); O3 child uses it to validate parent ownership |
| `release` | Only the **current holder** may release; O3 parent releases after reconciliation and records the helper confirmation (or the reason for retaining the claim) in its reconciliation summary; strangers/children fail audibly |

## Skill wiring

| Consumer | Load |
|----------|------|
| `sdd-plan` | `references/plan-ledger.md` (cite this contract; do not paste schema into PLAN bodies) |
| `sdd-develop` direct invocation | Optional claim before implement when that invocation requires ledger hold; direct invocation owns its lifecycle |
| O3 child | Verify matching parent-held claim with `status`; never acquire or release |
| `orchestrate-develop` | Honors ledger when execution modes land (separate step) |

PLAN documents stay **magro**: cite this path; do not embed claim JSON in PLAN markdown.

## Structural enforcement

```text
pwsh -NoProfile -File "{{TOOLKIT_ROOT}}/scripts/ledger/Invoke-PlanLedgerClaim.ps1" -Action claim -PlanPath <portable-or-abs> -Step N -Holder <id> -SessionsRoot <temp-or-sdd-sessions> -RepoPath <cwd>
```

The claim helper returns an auditable rejection when another holder already owns the step.

## Must not

- Silently overwrite an existing claim
- Treat SESSION develop gates as a substitute for ledger hold
- Dump full PRD / full `memory-bank/` into claim or audit payloads
- Write OS absolute InstallRoot embeds into PLAN / FEATURE / STORY artifacts when citing this contract — use portable paths
