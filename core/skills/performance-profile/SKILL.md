---
name: performance-profile
description: Find performance bottlenecks, set up micro-benchmarks, and optimize hot paths. Use when optimizing performance or invoking /performance-profile.
---


## STOP - Read before ANY tool call

1. Read `{{GUARDRAILS_PATH}}`
2. Read `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/SESSION.md`; load session-state for `$Cwd`
3. If the relevant gate is not approved: **STOP** - ask user **(pt-BR)** - do **NOT** Write/Shell
4. SDD/develop skills: after **ONE** step/task, **STOP** session - handoff only
5. This skill body is **English**; user-facing prompts may be **(pt-BR)**

### Step -1 - Gate check (report in chat before continuing)

```
Gate check:
[ ] guardrails.mdc read
[ ] SESSION.md read; session-state loaded
[ ] PIPELINE.md read (SDD skills only)
[ ] User confirmed current action (sim)
-> If any unchecked: STOP
```

---

# Skill: performance-profile

## Trigger

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

| When | Path (after `scripts/sync-cursor.ps1`) |
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

Confirm `guardrails.mdc` and `SESSION.md` are loaded. If missing, ask (pt-BR) before continuing.

### 0–1. Target and audit
Follow `references/target-audit.md`. Wait for workflow choice.

### 2–6. Benchmark, optimize, handoff
Follow `references/benchmark-optimize.md`.

## Must not

Enforce the full list in `references/must-not.md`. Critical: no optimization without benchmark; no domain-rule bypass for speed.
