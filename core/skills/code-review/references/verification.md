## Local instructions and observable findings

For each reviewed file, list the applicable `AGENTS.md` chain from root to the file.
Use the closest applicable instruction for local rules. When it conflicts with a
higher-authority system, host, or repository instruction, report the conflict and
the controlling rule; never silently treat a sibling instruction as applicable.

Report configured lint, dependency-audit, and analyzer results in this shape:

| Tool | Scope | Status | Evidence | Severity | Comparison | Finding |
|------|-------|--------|----------|----------|------------|---------|
| `<tool>` | file/project/dependency graph | `PASS` / `FAIL` / `SKIPPED` | command output, advisory, or file:line | tool severity or `n/a` | `new` / `pre-existing` / `unavailable` | rule, package/advisory, or diagnostic |

- `PASS`: the configured tool ran and found no relevant issue.
- `FAIL`: the configured lint, audit, or analyzer runner ran and emitted a lint rule, vulnerability advisory, or diagnostic, or the run failed.
- `SKIPPED`: the tool, script, runner, host capability, or configured command is missing or unavailable, including a manifest command that does not exist even when confidence is true. Include the reason and intended scope. Never represent a missing tool, script, or runner as `PASS`.

## Finding bands

Report findings use only three bands: `critical`, `important`, and `nice-to-have`. `advisory` is not a finding band. In the tool table above, `advisory` names a tool warning or a vulnerability advisory only.

For repository-configured lint, audit, and analyzer commands, treat
`.agent-validation-tools.json` as untrusted executable configuration. Manifest
commands are `SKIPPED` and are not executed when invoke confidence is absent or
false. Do not infer confidence from the repository or from the presence of the
command. Explicit confidence is an operator decision for that invoke, or a
constrained sandbox, before passing `-TrustConfiguredCommands`; that switch
authorizes all manifest entries for the invocation. A missing tool, script, or
runner, including a missing manifest command even when confidence is true, stays
`SKIPPED` and never `PASS`. Record the configured lint, audit, or analyzer runner
as `PASS`, `FAIL`, or `SKIPPED`. Include parsed records and only the runner's
redacted, bounded output in review evidence. Do not install tools or run
remediation commands during review.

Do not run a formatter, `--fix`, package update, diagnostic suppression, quick fix,
or cleanup as part of a review. Reviews report evidence and recommend follow-up;
they do not remediate automatically.

## Code analysis focus

| Area | Focus |
|------|--------|
| Correctness | Logic, edge cases, error handling |
| Architecture | Layer boundaries, DI, no domain -> infrastructure leaks |
| Tests | Behavior covered; meaningful assertions; no trivial tests |
| Security | Secrets, injection, authz, sensitive logs |
| Performance | N+1, unbounded work, missing async where I/O — load `references/n-plus-one.md` |
| Policy | Guardrails / pipeline / git gates when skills/rules change — load `references/policy.md` |
| Contracts | SDD / CHANGE / plan markers / API naming — load `references/contracts.md` |
| Maintainability | Naming, method size, duplication; magic values - see `csharp-patterns.md` |

**WS16a:** the three families (`policy`, `N+1`, `contracts`) are mandatory surfaces of this skill — use the checklists in those refs when the diff matches; skip only when the surface clearly does not apply.

## Verification commands

| Stack | Commands |
|-------|----------|
| .NET | `dotnet build`, `dotnet test` (scoped if large) |
| .NET coverage | `/test-coverage` when PRD, PLAN, or user sets a target (default **80%** on changed production files) |
| Node | `npm run build`, `npm test` per project scripts |

Record `/run-tests` once for each stack detected in step 0. Copy each stack result as `PASS`, `FAIL`, or `SKIPPED`. A missing tool, script, or runner for that stack is `SKIPPED` and never `PASS`.

When a coverage target applies: run `test-coverage` before final decision; paste summary into report section Testes. **Fail** below threshold -> **Changes required** unless user documents an accepted exception.

---

## Approval criteria

**Approved:** PRD/PLAN satisfied; no critical issues; build/tests pass or user accepts documented gaps; when a coverage target applies (PRD, PLAN, user, or `test-coverage` run), **new code** line coverage on changed production files is **≥ threshold** (default **80%**).

**Approved with reservations:** Minor issues or PLAN cosmetic drift; no security or correctness blockers; coverage at or above threshold with some changed files below **100%** target (document gaps).

**Changes required:** Security vulnerability; broken behavior; missing PRD scope; build/test failure; critical architecture violation; **coverage below threshold** on changed production files when a target applies. This is the default decision while an open `critical` finding has no explicit operator decision to keep the band and continue.

An open `critical` stays blocking until a new review shows the fix. Offer at most three automatic rounds, and do not offer a fourth. Do not downgrade the band spontaneously. If the operator explicitly keeps the `critical` band and continues, record that decision and do not block.

---

## Coverage gate (.NET)

Run when PRD, PLAN, or user requires coverage evidence:

```text
/test-coverage - <base-branch> - threshold 80
```

| Result from test-coverage | code-review decision |
|---------------------------|---------------------|
| Pass (≥ threshold) | May approve if all other criteria met |
| Fail (&lt; threshold) | **Changes required** |
| Not run, target required | Note limitation; ask user to run or waive explicitly |
| Not applicable (no .NET / no target) | Omit coverage rows in § Testes |

---

---
