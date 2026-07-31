# Step 3.5: Pre-commit validation

**Goal:** Validate staged work before `git commit`.

**Guardrails:** Fail fast - report exact files and rules. Do not auto-fix without user consent. Detected secrets are **always** blocking.

Flow: `Step 3 (branching) -> Step 3.5 -> Step 4 (commits)`.

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
| .NET | `dotnet format --verify-no-changes`; `dotnet build` | `dotnet format` |
| Node (ESLint) | `npx eslint . --max-warnings 0` | `npx eslint . --fix` |
| Node (Prettier) | `npx prettier --check .` | `npx prettier --write .` |

Skip tools not present in the repo.

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

Report high/critical issues; do not block unless user policy requires it.

---

## 3.5.6. Execution order

Run in order; stop on first blocker:

1. Secrets  
2. Lint / format  
3. Build  
4. Quick tests  
5. Dependency audit (warning)

Example summary:

```markdown
| Check              | Status  |
|--------------------|---------|
| Secrets            | Passed  |
| Code style         | Passed  |
| Build              | Passed  |
| Quick tests        | Passed  |
| Dependency audit   | 1 warn  |
```

**Skip full suite when:** user passed `--skip-validation`, or only docs/config with no code (still run secrets scan).

---

## Step 3.5 checklist

- [ ] No secrets in staged files
- [ ] Format/lint clean (if tooling exists)
- [ ] Build succeeds
- [ ] Unit tests pass (scoped)
- [ ] Warnings documented if any
