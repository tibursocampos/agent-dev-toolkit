## Step 5.5 — Post-implement verifier (opt-in)

**When:** `{{SDD_ROOT}}/preferences.json` has `"verify_mode": true` (default `false`).

**Where in O3 flow:** After Step 5 implementer child returns **success** and **before** parent updates CONTINUITY / asks **sim** for the next spawn.

**Purpose:** Read-only second pass that checks the implementer's receipt against PLAN step **Aceite** (REQ-NNN / CA), build/test summary, and scoped file list — without writing application code.

---

## Process — Verifier spawn

1. Read `preferences.json`; if `verify_mode` is not `true`, **skip** this step entirely.
2. If implementer returned `status: blocked` or build/tests failed, **skip** verifier — keep step pending; do not spawn verifier on known failure.
3. **SPAWN gate:** load `SPAWN.md`; prefer Task when `subagents=native`. If Task unavailable, parent records verifier skipped in CONTINUITY — do **not** hard-fail O3.
4. Spawn **one read-only verifier child** per completed implementer return (never parallel with the implementer on the same step).

Verifier child must:

1. **Read only** — no `Write`/`Edit` on app sources, tests, or PLAN (read PLAN + changed files + PRD path cited in PLAN header).
2. Load lean context: PLAN path, step number, implementer receipt `{ files[], testsSummary, build }`, PRD portable path (not full PRD body).
3. Verify:
   - Step **Aceite** REQ-NNN / CA claims match implementer scope (no unchecked REQ items marked done).
   - Build/tests summary is present when files changed.
   - No scope creep into other PLAN steps.
4. Return: `{ planPath, step, verifierStatus: pass|fail|skip, findings[], reqCoverage[] }`.
5. **STOP** after report — must not implement fixes.

**Parent on verifier `fail`:**

- Do **not** mark step done in CONTINUITY.
- Keep PLAN step **Pendente** (implementer may have prematurely marked Completed — parent must not endorse).
- Report findings (pt-BR); ask user **sim** to re-spawn implementer or adjust.

**Parent on verifier `pass`:**

- Proceed with normal post-child flow: CONTINUITY update → **sim** for next spawn.

**Must not:**

- Use verifier as a second implementer (no code fixes in verifier child).
- Spawn verifier when `verify_mode` is `false` (default).
- Treat verifier as evidence gate — `validate-evidence` remains sequential inside `sdd-develop` (**Verifier ≠ O3** for EVD/TRACE too).
- Auto-chain implementer → verifier → next implementer without **sim** between O3 spawns.

---

## Task verifier prompt skeleton

When `verify_mode` is `true` and implementer succeeded:

1. PLAN path + step number/title
2. Implementer receipt (files, testsSummary, build status)
3. Instruction: **read-only** review — compare step **Aceite** REQ-NNN / CA vs receipt; no Write/Edit on app code or PLAN
4. Return `{ planPath, step, verifierStatus, findings[], reqCoverage[] }`
5. Must stop after report; must not start Step N+1

Parent: merge verifier return → gate CONTINUITY / next spawn on `pass` only.
