## Step queue algorithm

```text
1. Collect PLANs under feature (or single PLAN from invoke).
2. For each PLAN, list steps with status + deps.
3. Ready set = pending steps whose deps are all completed.
4. Default pick = first ready in PLAN order within current story.
5. Present pick; wait for sim; spawn one child.
6. On success: refresh queue; update CONTINUITY; ask sim for next OR hand off new chat.
7. On failure: keep step pending; report blockedReason; do not advance.
```

Story preference: finish one story’s PLAN before starting another unless user explicitly reorders and deps allow.

---

## Process — Build step queue

For each PLAN:

1. Parse pending steps (`⏳` / Status Pendente / unchecked).
2. Respect **Deps:** only enqueue a step when dependency steps are **Concluídos** / **Completed**.
3. Default order: one story at a time (finish story A before story B) unless user asks otherwise **and** stories are independent.

Present queue summary (pt-BR): story, PLAN path, next step id/title, deps. Confirm:

```text
Fila O3: próximo = `{plan-path}` Step {N} - {title}.

Posso spawnar o subagente (contrato sdd-develop)?
(sim / ajustar / cancelar)
```

Silence ≠ approval (RN01). See also § Step queue algorithm.

---

## Process — Spawn one step child (CA5)

**SPAWN first:** load `SPAWN.md`; consult capability `subagents`. Prefer Task when `native`. If `subagents=none` or Task unavailable → **fallback** handoff to `/sdd-develop - <portable-plan-path> - Step N` (note in CONTINUITY / chat) — never hard-fail; parent still must not write app code.

**Hard rule (native path):** one Task = one PLAN step = full `sdd-develop` contract.

**Model (`SUBAGENT-MODEL.md`):** omit Task `model` by default — child uses the **same model as the parent session**. Do **not** conflate with Cursor Auto model or Memory Bank policy `auto`. Ask about a premium slug **only** for very hard PLAN steps per that contract; on **não** / silence, spawn without `model`. Never pick a costlier model alone.

### Canonical Shell boundary (REQ-012 / CA4 / CT6)

After operator **sim** and before implement/spawn boundary, **MUST** call both canonical scripts via `-File` (cwd = repo root). **MUST NOT** paste multi-line inline PowerShell that mutates develop session JSON under `sessions/` (`ConvertFrom-Json` / `ConvertTo-Json` / `Set-Content` gate blobs).

Prefer **one** Shell approve per step when the host can chain both `-File` calls:

```powershell
pwsh -NoProfile -File .\scripts\session\Invoke-DevelopSessionGate.ps1 -PlanPath <plan> -RepoPath . -SddRoot <sdd-root> [-Step N]; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }; pwsh -NoProfile -File .\scripts\ledger\Invoke-PlanLedgerClaim.ps1 -Action claim -PlanPath <plan> -Step N -Holder <holder> -RepoPath . -SddRoot <sdd-root>
```

| Script | Role |
|--------|------|
| `scripts/session/Invoke-DevelopSessionGate.ps1` | Idempotent `step_confirmed` (skip rewrite if already true) |
| `scripts/ledger/Invoke-PlanLedgerClaim.ps1` | Claim SoT — still **MUST** run when claim is absent |

**CT6:** session helper idempotent skip **MUST NOT** waive a missing ledger claim — always run `Invoke-PlanLedgerClaim` when claim is required and absent. No second claim SoT.

### Shell allowlist tip (REQ-013 / RNF-004)

Operators may **opt-in** allowlist the two portable script paths above (cwd = repo root) to reduce repeated Shell approves. Detail: `adapters/cursor/README.md` § Shell allowlist and `docs/domains/cli-scripts.md` § Shell allowlist tip.

- **MUST NOT** enable host-wide “auto-approve all Shell” or ship hooks that silently mutate Shell approve policy.
- Path/secrets guards (`guard-rules.md` / `GuardCommon.ps1`) stay intact — allowlist ≠ weaken workspace binding or secret scan.

Child must:

1. Load and follow `sdd-develop/SKILL.md` (gates, validate step, git branch, implement, tests, update PLAN, report)
2. Receive **only** that PLAN path + step number + lean Prior context paths (PRD, STORY, CONTINUITY, FEATURE, **`ARCH|SEC|ANALYSIS` when present**, **`memory-bank/` path**) - not full guideline dumps or full bank body
3. Use **PLAN-scoped SESSION** per `SESSION.md` (`plan-{planHash}.json`, or `plan-{planHash}-step-{N}.json` when this spawn is parallel on the same PLAN)
4. Honor the canonical Shell boundary above after **sim** (session helper + ledger claim via `-File`)
5. Return: `{ planPath, step, status, files[], testsSummary, nextStep?, blockedReason? }`
6. **STOP** after that step - must not start Step N+1 in the same child

**Parent must not:**

- Edit `*.cs` / app sources / tests itself
- “Help finish” the child’s implementation
- Spawn a child with instructions to do Steps N and N+1
- Mark PLAN checkboxes for steps the child did not complete
- Skip `tests_run` / treat silence as step approval inside the child
- Share one flat `{repo-hash}.json` develop gate across parallel children
- Inline-mutate develop session JSON instead of `Invoke-DevelopSessionGate.ps1`
- Skip `Invoke-PlanLedgerClaim.ps1` because session helper already exited 0 (CT6)

After child returns: parent updates `CONTINUITY.md` only (synthesis + paths; keep Memory-bank fields). Then either hand off to a **new chat** for the next step, or ask **sim** again before the next spawn in this conversation - never auto-chain without a gate.

See also § Task child prompt skeleton + § Anti-bypass checklist.

---

## Task child prompt skeleton

**SPAWN gate:** spawn Task only when `subagents=native`. Else **fallback** handoff — skip this skeleton.

Give each child:

1. Exact PLAN path + step number/title
2. Instruction: execute `/sdd-develop` contract for **this step only** - load `sdd-develop/SKILL.md`
3. Instruction: load develop SESSION scoped per `SESSION.md` - `plan-{planHash}.json`, or `plan-{planHash}-step-{N}.json` if this is a same-PLAN parallel spawn
4. Prior-context paths only (PRD, STORY, CONTINUITY, FEATURE, **`ARCH|SEC|ANALYSIS` when present**, **`memoryBankPath`**) - do not paste bodies; selective bank read only
5. Must stop after updating PLAN for this step; must run targeted tests before complete
5a. After **sim**: **MUST** call `Invoke-DevelopSessionGate.ps1` + `Invoke-PlanLedgerClaim.ps1` via `-File` (REQ-012 / CT6); **MUST NOT** inline session JSON mutators
5b. When level ≥ `cheap`: update `features/NNN-slug/EVD/` + `STATE.md` and run `validate-evidence` before Completed (**Verifier ≠ O3** — sequential only; do not spawn nested Task children for verification)
5c. When closing the feature wave: append `features/NNN-slug/TRACE.jsonl` living loop (**converge → sync_current → archive**) and run `validate-trace -RequireArchiveComplete` (**Verifier ≠ O3**; `TRACE-ARCHIVE-CONTRACT.md`)
5d. When touching C#: honor `csharp-patterns.md` signatures/invocations on Write (≤6 params **and** ≤160 chars inline; else one param per line; re-inline if CSharpier wraps without need)
6. Return: `{ planPath, step, status: done|blocked, files[], testsSummary, nextStep?, blockedReason? }`
7. Must not: other PLAN steps; weaken gates; skip tests; auto-commit unless user asked inside that child session; write develop gates to the flat repo session when PLAN path is known; write under `memory-bank/` unless this child is explicitly running memory-bank-init (normal develop children: read-only); skip ledger claim when session gate already true (CT6)

Parent: merge return -> CONTINUITY -> gate for next spawn.
