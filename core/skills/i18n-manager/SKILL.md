---
name: i18n-manager
description: Extract hardcoded strings into .resx or .json localization files and replace with translation keys. Use when localizing code or invoking /i18n-manager.
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

# Skill: i18n-manager

## Trigger

Invoke when the user requests: `/i18n-manager`, `localize code`, or asks to internationalize a component.

**Arguments (optional):**

| Input | Meaning |
|-------|---------|
| Target directory | Scopes the scan for string literals to a specific subfolder |

## Outcome

1. Refactored code files where raw strings are replaced by framework-native translation variables or helpers (e.g. `_localizer["Key"]`, `t('Key')`).
2. Updated localization resource files (`.resx` for C#, `.json` translation dictionaries for JavaScript/TypeScript).

## Lazy-load (only when needed)

| When | Path (after `scripts/sync-cursor.ps1`) |
|------|----------------------------------------|
| C# projects | `{{TOOLKIT_ROOT}}/skills/_shared/dotnet-guidelines/string-manipulation.md` |
| React / Angular | `{{TOOLKIT_ROOT}}/skills/_shared/frontend-guidelines/frontend-practices.md` |
| Caveman Mode (if active) | `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md` - **Full cap** |
| Reference index (routing only) | `{{TOOLKIT_ROOT}}/skills/i18n-manager/reference.md` |
| Process step detail (lazy) | `{{TOOLKIT_ROOT}}/skills/i18n-manager/references/<section>.md` |

**Never by default:** do not preload all `references/*.md`, unrelated stack guideline packs, or `memory-bank`/PRD dumps. Load **one** section per Process step (`SKILL-REFERENCE-RETRIEVAL.md`).

## Reference routing

| Situation | Path |
|-----------|------|
| Frame context / gates | `references/frame-context.md` |
| Scan literals + workflow choice | `references/scan-and-workflow.md` |
| Resource bundles + code refactor | `references/localize-apply.md` |
| Build, verify, handoff | `references/build-verify-handoff.md` |
| Must not (full) | `references/must-not.md` |

## Process

Read `references/<section>.md` for procedural detail — **not** full `reference.md`.

### Step -1b / -1. Caveman + gates
Follow `references/frame-context.md`.

### 0–1. Frame context and scan
Follow `references/frame-context.md` then `references/scan-and-workflow.md`. Wait for explicit workflow choice before writing.

### 2–3. Apply localization
Follow `references/localize-apply.md`.

### 4–5. Build, verify, handoff
Follow `references/build-verify-handoff.md`.

## Must not

Enforce the full list in `references/must-not.md`. Critical: no generic keys (`Text1`); no mutating logger/config strings; no write before workflow choice.

## Handoff

| Situation | Next |
|-----------|------|
| Commit refactors | `/commit` |
| Large app-wide i18n via SDD | `/sdd-spec` then plan/develop |
| Stack-specific coding help | `/developer` or matching `*-developer` |
