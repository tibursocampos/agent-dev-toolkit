## Benchmark, optimize, and handoff

### Configure benchmark

* Propose the setup for a benchmark suite:
  * C#: Create a BenchmarkDotNet class under the test project.
  * Python: Write a test script utilizing `timeit` or `cProfile`.
  * TS/JS: Write a benchmark script utilizing Node's `perf_hooks` or `benchmark.js`.
* Wait for confirmation, then write the benchmark script/class.

### Collect baseline (before)

* Instruct the user/agent to run the benchmark script and capture the execution outputs:
  * Capture Mean Time, Standard Deviation, and Allocated Bytes.
* Document the baseline metrics.

### Implement and verify optimization

* Write the optimized implementation in a separate branch or method variant (e.g. `CalculateOptimized`).
* Run the benchmark again to compare:
  * Verify that optimization achieves measurable improvements (e.g. 20% speedup or lower GC allocation) without regression.
* Present a comparison table:

| Variant | Mean Time | Allocated Bytes |
|---------|-----------|-----------------|
| Baseline | ... | ... |
| Optimized | ... | ... |

### Apply final changes

* Replace the old code with the validated optimized version.
* Run compiler checks and regular test suites to ensure behavior remains identical.

### Handoff

Offer committing the optimizations via `/commit`.
