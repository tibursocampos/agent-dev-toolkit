---
name: performance-profile
description: Find performance bottlenecks, set up micro-benchmarks, and optimize hot paths. Use when optimizing performance or invoking /performance-profile.
---


## STOP - Read before ANY tool call

1. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/rules/guardrails.md`
2. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/skills/_shared/sdd-artifacts/SESSION.md`; load session-state for `$Cwd`
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

## Lazy-load

| When | Path (after `scripts/sync-cursor.ps1`) |
|------|----------------------------------------|
| C# projects | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/skills/_shared/dotnet-guidelines/csharp-patterns.md`, `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/skills/_shared/dotnet-guidelines/string-manipulation.md` |
| JavaScript / TypeScript | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/skills/_shared/javascript-guidelines/clean-code-js.md` |
| Python projects | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/skills/_shared/python-guidelines/principles.md` |
| Caveman Mode (if active) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/skills/_shared/caveman/CAVEMAN.md` - **Full cap** |

## Process

### Step -1b - Caveman Mode (Full cap)
1. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/sdd/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full" }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/skills/_shared/caveman/CAVEMAN.md`; apply **Full** participation cap + prefs `caveman_level` (Lite skills never escalate); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) during the session.
5. Auto-Clarity + never-compress gates/drafts/paths per `CAVEMAN.md`.

### -1. Re-check guardrails and session

Confirm `guardrails.mdc` and `SESSION.md` are loaded.
If missing, ask user (pt-BR):

```text
Antes do profiling, confirme:
- guardrails.mdc lido
- SESSION.md carregado

Posso seguir? (sim / ajustar / cancelar)
```


### 0. Target Identification

* Locate the target method, database routine, or loop structure.
* Confirm what metrics are critical: Execution Time (ms) or Memory Allocation (MB/GC cycles).

### 1. Static Performance Audit & Workflow Decision

* Analyze the target code for common anti-patterns:
  * Database: N+1 queries (no eager loading), lack of projection (`select new`), missing query limits (`Take`/`limit`), unindexed search fields.
  * Memory: Excessive allocations inside loops, duplicate string concatenations, boxing/unboxing.
* Present the diagnostic report summarizing the bottlenecks.
* Stop and ask the user to choose the workflow execution path for applying and benchmarking these optimizations:
  * **Option A - Direct Developer Skill (`/developer`):** For straightforward local optimization and benchmark setup.
  * **Option B - Classic SDD (`/sdd-spec` -> `sdd-plan` -> `sdd-develop`):** For complex structural refactorings or query tuning requiring formal specifications (PRD) and a detailed plan (PLAN) in Portuguese.
  * **Option D - Plain Chat Plan:** Establish a simple task list directly in the chat, executing steps one by one without extra file creations.
* **Wait for explicit user choice** before writing code or initializing another workflow.

### 2. Configure Benchmark

* Propose the setup for a benchmark suite:
  * C#: Create a BenchmarkDotNet class under the test project.
  * Python: Write a test script utilizing `timeit` or `cProfile`.
  * TS/JS: Write a benchmark script utilizing Node's `perf_hooks` or `benchmark.js`.
* Wait for confirmation, then write the benchmark script/class.

### 3. Collect Baseline (Before)

* Instruct the user/agent to run the benchmark script and capture the execution outputs:
  * Capture Mean Time, Standard Deviation, and Allocated Bytes.
* Document the baseline metrics.

### 4. Implement & Verify Optimization

* Write the optimized implementation in a separate branch or method variant (e.g. `CalculateOptimized`).
* Run the benchmark again to compare:
  * Verify that optimization achieves measurable improvements (e.g. 20% speedup or lower GC allocation) without regression.
* Present a comparison table:

| Variant | Mean Time | Allocated Bytes |
|---------|-----------|-----------------|
| Baseline | ... | ... |
| Optimized | ... | ... |

### 5. Apply Final Changes

* Replace the old code with the validated optimized version.
* Run compiler checks and regular test suites to ensure behavior remains identical.

### 6. Handoff

* Offer committing the optimizations:

```
/commit
```

## Must not

* Perform optimizations without a benchmark validation.
* Introduce breaking changes or bypass domain validation rules to improve speed.
