# Subagent-first policy (`*-developer`)

Shared decision policy for stack `*-developer` skills. Encode RN02–RN04 here once; skills **point** to this file — do not duplicate long bodies.

**Mandatory:** read `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md` and capability `subagents` (`native` | `none` from registry / Get-Capabilities) before spawning.

**Agent `model` (Axis B):** when spawning, follow `{{TOOLKIT_ROOT}}/skills/_shared/agents/SUBAGENT-MODEL.md` — **omit** the Agent `model` parameter by default so the child uses the **same model as the parent session**. Do **not** conflate with a host auto model or Memory Bank policy `auto`. Premium / alternate slug only after that contract’s gate + explicit user **sim**.

Install path after sync: `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/subagent-first.md`

---

## Complexity → action

| Complexity | Action | Notes |
|------------|--------|-------|
| **trivial** | **in-parent** only | Always (RN02). No Agent / children. |
| **medium** / **complex** | Prefer up to **2** children when `subagents=native` | Scoped **paths** + end-of-pass **receipt** (`RECEIPT.md`). No guideline paste (RN03). |
| **medium** / **complex** + `subagents=none` (or Agent unavailable) | Same outcome **in-parent** (or documented handoff) | Safe **fallback** — never hard-fail (RN04). |

Subagent-first = **preference + fallback**, never hard-require Agent (RN01 / SPAWN).

---

## Decision (short)

```text
Classify task complexity
  ├─ trivial              → in-parent
  ├─ medium/complex
  │    ├─ subagents=native and Agent (or host equivalent) available
  │    │    → spawn ≤2 children (paths + receipt); parent synthesizes
  │    └─ else (subagents=none / no Agent)
  │         → fallback: in-parent (or handoff note) — same deliverable
  └─ always               → lazy-load SPAWN.md; do not paste guidelines into child prompts
```

---

## Child payload (when spawning)

1. Pass scoped **paths** only (files/dirs the child may touch).
2. Spawn the `developer-child` role from `ROSTER.md` and require its reduced `{ files[], testsSummary }` receipt as defined in `RECEIPT.md`; do not require `planPath` or `step` from this nested child. Missing, malformed, out-of-scope, or contradictory receipts cannot be treated as success; stop and report the mismatch to the operator.
3. Point to role/skill paths; **do not** paste `_shared/*-guidelines/`, full SKILL bodies, or large policy dumps.
4. Child prompts and agent receipts: **always en-US** (`LANGUAGE.md`). Pass **paths + excerpt** of user-language artifacts — no full PLAN/PRD dump.

Cap: **≤ 2** children per task wave (`*-developer`).

If fallback or in-parent work requires a code edit while the host is in Plan/Ask,
stop before editing and explicitly ask the operator to switch to Agent. Never
change host mode silently or claim an edit was saved from Plan/Ask.

---

## Stable markers (for asserts / skill echo)

Skills and CI asserts should echo these literals (exact substrings preferred):

| Marker | Role |
|--------|------|
| `SPAWN.md` | Mandatory contract pointer |
| `SUBAGENT-MODEL.md` | Axis B omit `model` / Axis C gate |
| `subagents` | Capability name |
| `in-parent` | Trivial path + fallback path |
| `fallback` | Degrade when none / no Agent |
| `receipt` | Child end-of-pass requirement |
| `paths` | Scoped child payload |
| `LANGUAGE.md` | Two surfaces; en-US spawn |

Canonical spawn contract (limits, enum honesty, orchestrate caps): `SPAWN.md` — this file does not replace it. Model param: `SUBAGENT-MODEL.md`. Language surfaces: `LANGUAGE.md`.

---

## Must not

- Hard-fail when `subagents` is `none` or Agent is missing
- Spawn for **trivial** work
- Exceed **2** developer children without user-approved wave
- Paste guideline packs into child prompts
- Wire every `*-developer` SKILL from this file alone — Step 5 adds the pointers

---

## CA2 mapping

| PRD | Covered here |
|-----|----------------|
| CA2 trivial stays in-parent | § Complexity → action / RN02 |
| CA2 ≤2 children + paths + receipt | § medium/complex + Child payload / RN03 |
| CA2 none → in-parent, no hard-fail | § fallback / RN04 |
| CA2 consult SPAWN + `subagents` | Header mandatory pointer |
