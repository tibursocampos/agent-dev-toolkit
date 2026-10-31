---
name: performance-profile
description: Find performance bottlenecks, set up micro-benchmarks, and optimize hot paths. Use when optimizing performance or invoking /performance-profile.
---

## STOP - Read before ANY tool call

Read `_shared/skill-boilerplate.md` first. It holds the guardrails read, the session gate rule, the user `sim` rule, the one-step rule, the gate check, and the user chat language rule. The steps below are skill-specific only.

---

# Skill: performance-profile

## Trigger
**Negative signal:** applies as defined in `_shared/skill-boilerplate.md`; the skill-specific signals are listed below.

Invoke when the user requests: `/performance-profile`, `optimize performance`, `/performance-profile`, or asks to fix query bottlenecks.

**Arguments (optional):**

| Input | Meaning |
|-------|---------|
| Target method / query | Target function, method, or LINQ/SQL query block to optimize |

## Outcome

Documented performance improvements verified by local benchmarking:

1. Identified bottlenecks (SQL/LINQ analysis, loop allocations).
2. Optimization proposal (e.g., eager loading, projection, indexes, caching, memory span allocations).
3. Micro-benchmark results comparing execution speed and memory allocations (before vs. after).

## Lazy-load (only when needed)

| When | Path (after syncing the active adapter) |
|------|----------------------------------------|
| C# projects | `{{TOOLKIT_ROOT}}/skills/_shared/dotnet-guidelines/csharp-patterns.md`, `{{TOOLKIT_ROOT}}/skills/_shared/dotnet-guidelines/string-manipulation.md` |
| JavaScript / TypeScript | `{{TOOLKIT_ROOT}}/skills/_shared/javascript-guidelines/clean-code-js.md` |
| Python projects | `{{TOOLKIT_ROOT}}/skills/_shared/python-guidelines/principles.md` |
| Caveman Mode (if active) | `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md` - **Full cap** |
| Reference index (routing only) | `{{TOOLKIT_ROOT}}/skills/performance-profile/reference.md` |
| Process step detail (lazy) | `{{TOOLKIT_ROOT}}/skills/performance-profile/references/<section>.md` |

**Never by default:** do not preload all `references/*.md` or unrelated stack guideline packs. Load **one** section per Process step (`SKILL-REFERENCE-RETRIEVAL.md`).

## Reference routing

| Situation | Path |
|-----------|------|
| Target / audit / workflow | `references/target-audit.md` |
| Benchmark / optimize | `references/benchmark-optimize.md` |
| Must not (full) | `references/must-not.md` |

## Process

Read `references/<section>.md` for procedural detail — **not** full `reference.md`.

### Step -1b - Caveman Mode (Full cap)
1. Read `{{SDD_ROOT}}/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full" }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md`; apply **Full** participation cap + prefs `caveman_level` (Lite skills never escalate); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) during the session.
5. Auto-Clarity + never-compress gates/drafts/paths per `CAVEMAN.md`.

### -1. Re-check guardrails and session

Confirm `guardrails.mdc` and `SESSION.md` are loaded. If missing, ask in the user chat language before continuing.

### 0–1. Target and audit
Follow `references/target-audit.md`. Wait for workflow choice.

### 2–6. Benchmark, optimize, handoff
Follow `references/benchmark-optimize.md`.

## Must not

Enforce the full list in `references/must-not.md`. Critical: no optimization without benchmark; no domain-rule bypass for speed.
