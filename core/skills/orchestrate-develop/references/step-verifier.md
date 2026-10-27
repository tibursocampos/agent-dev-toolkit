## Step 5.5 — Post-implement verifier (opt-in)

**When:** `{{SDD_ROOT}}/preferences.json` has `"verify_mode": true` (default `false`).

**Where in O3 flow:** After Step 5 implementer child returns **success** and **before** parent updates CONTINUITY / asks **sim** for the next spawn.

**Purpose:** Read-only second pass that checks the implementer's receipt against PLAN step **Aceite** (REQ-NNN / CA), applicable test summary, and scoped file list — without writing application code. Build is handled only at US close when applicable.

---

## Process — Verifier spawn

1. Read `preferences.json`; if `verify_mode` is not `true`, **skip** this step entirely.
2. If implementer returned `status: blocked` or a test declared by the PLAN failed, **skip** verifier — keep step pending; do not spawn verifier on known failure. Explicit deferred/skipped tests are not failures when the PLAN defers execution.
3. **SPAWN gate:** load `SPAWN.md`; prefer Task when `subagents=native`. If Task unavailable, parent records verifier skipped in CONTINUITY — do **not** hard-fail O3.
4. Spawn **one read-only verifier child** per completed implementer return (never parallel with the implementer on the same step). Use the verifier result schema below; it is not the canonical implementer relay receipt.

Verifier child must:

1. **Read only** — no `Write`/`Edit` on app sources, tests, or PLAN (read PLAN + changed files + PRD path cited in PLAN header).
2. Load lean context: PLAN path, positive integer step number, canonical implementer relay receipt `{ planPath, step, status, files[], deletedFiles[]?, testsSummary, nextStep?, blockedReason? }`, and PRD portable path (not full PRD body). Build is not a per-step field; US-close build is out of this verifier pass.
3. Verify:
   - Step **Aceite** REQ-NNN / CA claims match implementer scope (no unchecked REQ items marked done).
   - A tests summary is present when files changed; explicit deferred/skipped matches a PLAN step that defers tests.
   - No scope creep into other PLAN steps.
4. Return: `{ planPath, step, verifierStatus: pass|fail|skip, findings[], reqCoverage[] }`, with `step` emitted as a positive JSON integer. The parent validates this verifier schema separately from the implementer relay schema.
5. **STOP** after report — must not implement fixes.

**Parent on verifier `fail`:**

- Do **not** mark step done in CONTINUITY.
- Keep PLAN step **Pendente** (implementer may have prematurely marked Completed — parent must not endorse).
- Report findings (pt-BR); ask user **sim** to re-spawn implementer or adjust.

**Parent on verifier `pass`:**

- Proceed with normal post-child flow: CONTINUITY update → apply the pacing rule: fresh **sim** for `step_by_step`, or the initial queue **sim** plus reconciled checkpoint/ledger and session report for `continuous`.

**Must not:**

- Use verifier as a second implementer (no code fixes in verifier child).
- Spawn verifier when `verify_mode` is `false` (default).
- Treat verifier as evidence gate — `validate-evidence` remains sequential inside `sdd-develop` (**Verifier ≠ O3** for EVD/TRACE too).
- Auto-chain implementer → verifier → next implementer without the pacing rule's required authorization: fresh **sim** for `step_by_step`, or the initial queue **sim** plus reconciliation for `continuous`.

---

## Task verifier prompt skeleton

When `verify_mode` is `true` and implementer succeeded:

1. PLAN path + step number/title
2. Canonical implementer relay receipt (files and testsSummary; no per-step build status)
3. Instruction: **read-only** review — compare step **Aceite** REQ-NNN / CA vs receipt; no Write/Edit on app code or PLAN
4. Return `{ planPath, step, verifierStatus, findings[], reqCoverage[] }` with integer `step`
5. Must stop after report; must not start Step N+1

Parent: merge verifier return → gate CONTINUITY / next spawn on `pass` only.
