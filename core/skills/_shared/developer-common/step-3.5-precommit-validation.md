# Step 3.5: Pre-commit validation

**Goal:** Validate staged work before `git commit`.

**Guardrails:** Fail fast - report exact files and rules. Do not auto-fix without user consent. Detected secrets are **always** blocking. This step only observes and reports: never run `--fix`, `format`, package update, suppression, or cleanup commands automatically.

Flow: `Step 3 (branching) -> Step 3.5 -> Step 4 (commits)`.

---

## 3.5.0. Applicable local instructions

Before selecting a validation command or interpreting its output, discover applicable
`AGENTS.md` files from the repository root to each changed path. Apply the closest
applicable instruction as the local rule. A higher-authority instruction (system,
host, or repository root) remains controlling when it conflicts with a nested file;
report that conflict instead of silently choosing a lower rule.

Record the instruction paths used, the changed-path scope, and any conflict in the
validation evidence. Do not infer that an instruction applies to sibling directories.

---

## 3.5.1. Secrets detection (blocking)

Check staged text files (skip binaries, lockfiles unless they contain secrets).

Patterns to flag:

- API keys: `api_key=`, `AKIA[A-Z0-9]{16}` (AWS)
- Tokens: `gh[pousr]_`, long JWT-like `eyJ...`
- Passwords in connection strings: `password=`, `Password=`
- Private keys: `-----BEGIN PRIVATE KEY-----`
- Cloud keys: `AccountKey=` with long base64 payloads

**False positives (ignore):** placeholders (`YOUR_`, `<TOKEN>`, `xxx`, `example`), test fixtures clearly fake, references to `Configuration[`, `Environment.Get`, `process.env` without literal secrets.

If found -> **block commit**; show file, line, pattern type.

---

## 3.5.2. Lint and format (blocking when configured)

| Stack | Verify | Auto-fix (with consent) |
|-------|--------|-------------------------|
| .NET | `csharpier check .` when CSharpier is configured; `dotnet build` | `csharpier format .` |
| Node (ESLint) | `npx eslint . --max-warnings 0` | `npx eslint . --fix` |
| Node (Prettier) | `npx prettier --check .` | `npx prettier --write .` |

When a configured tool is unavailable, record `SKIPPED` with the tool, intended
scope, reproducible availability evidence, and reason. An unavailable tool is never
`PASS`. The commands in the auto-fix column are consent-only examples and must not
run as part of this validation.

For configured diagnostics, use the repository's `.agent-validation-tools.json`
manifest with `scripts/validation/Invoke-ConfiguredDiagnostics.ps1`. The runner
resolves each declared command locally or from `PATH`; it invokes only commands
that resolve and records a missing command as `SKIPPED`. It does not install tools.
Pass changed paths and baseline rule identifiers so parsed findings retain project,
file, rule, severity, and `new` / `pre-existing` comparison. Keep raw command output
as evidence. A manifest entry must name a read-only validation command; never use
this flow for formatter, fix, update, suppression, or cleanup commands.

---

## 3.5.3. Build (blocking)

| Stack | Command |
|-------|---------|
| .NET | `dotnet build --no-restore` (or full `dotnet build`) |
| TypeScript | `npx tsc --noEmit` when `tsconfig.json` exists |
| Node app | `npm run build` when defined in `package.json` |

---

## 3.5.4. Quick tests (blocking)

| Stack | Command |
|-------|---------|
| .NET | `dotnet test --filter "Category!=Integration&Category!=E2E" --no-build` or project-specific filter from PLAN |
| Node | `npm test` with project’s unit-test scope |

Use reasonable timeouts; report slow suites to the user.

---

## 3.5.5. Dependency audit (warning only)

| Stack | Command |
|-------|---------|
| .NET | `dotnet list package --vulnerable --include-transitive` |
| Node | `npm audit --audit-level=high` |

Report findings without changing dependencies. Each available advisory must include
package, version, severity, advisory identifier/link when emitted, scope, evidence,
and whether it is `new`, `pre-existing`, or `unavailable` for comparison. Do not
block unless user policy requires it. If the audit command is unavailable, emit
`SKIPPED`, never `PASS`.

---

## 3.5.6. Execution order

Run in order; stop on first blocker:

1. Secrets  
2. Lint / format  
3. Build  
4. Quick tests  
5. Dependency audit (warning)

Every lint, audit, and configured analyzer entry uses this evidence shape:

| Tool | Scope | Status | Evidence | Severity | Comparison | Notes |
|------|-------|--------|----------|----------|------------|-------|
| `<tool>` | changed paths/project | `PASS` / `FOUND` / `SKIPPED` | command output or file:line | severity or `n/a` | `new` / `pre-existing` / `unavailable` | reason for `SKIPPED` when applicable |

- `PASS` means the configured tool ran and emitted no relevant finding.
- `FOUND` means the tool emitted at least one finding; preserve each finding's rule/advisory/diagnostic, severity, scope, and evidence.
- `SKIPPED` means the tool or required host capability was unavailable or not configured; it is not proof of a clean result.

Example summary:

```markdown
| Check              | Status | Scope | Evidence | Comparison |
|--------------------|--------|-------|----------|------------|
| Secrets            | PASS   | staged text | command output | unavailable |
| Code style         | PASS / FOUND / SKIPPED | changed paths | command output | new / pre-existing / unavailable |
| Diagnostics        | PASS / FOUND / SKIPPED | configured project | command output | new / pre-existing / unavailable |
| Build              | PASS   | configured project | command output | unavailable |
| Quick tests        | PASS   | configured project | command output | unavailable |
| Dependency audit   | PASS / FOUND / SKIPPED | dependency graph | command output | new / pre-existing / unavailable |
```

**Skip full suite when:** user passed `--skip-validation`, or only docs/config with no code (still run secrets scan).

---

## Step 3.5 checklist

- [ ] No secrets in staged files
- [ ] Format/lint clean (if tooling exists)
- [ ] Build succeeds
- [ ] Unit tests pass (scoped)
- [ ] Warnings documented if any
