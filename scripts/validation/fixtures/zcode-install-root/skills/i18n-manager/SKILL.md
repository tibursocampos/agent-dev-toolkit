---
name: i18n-manager
description: Extract hardcoded strings into .resx or .json localization files and replace with translation keys. Use when localizing code or invoking /i18n-manager.
---


## STOP - Read before ANY tool call

1. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/rules/guardrails.mdc`
2. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/sdd-artifacts/SESSION.md`; load session-state for `$Cwd`
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

Invoke when the user requests: `/i18n-manager`, `localize code`, `/i18n-manager`, or asks to internationalize a component.

**Arguments (optional):**

| Input | Meaning |
|-------|---------|
| Target directory | Scopes the scan for string literals to a specific subfolder |

## Outcome

1. Refactored code files where raw strings are replaced by framework-native translation variables or helpers (e.g. `_localizer["Key"]`, `t('Key')`).
2. Updated localization resource files (`.resx` for C#, `.json` translation dictionaries for JavaScript/TypeScript).

## Lazy-load

| When | Path (after `scripts/sync-cursor.ps1`) |
|------|----------------------------------------|
| C# projects | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/dotnet-guidelines/string-manipulation.md` |
| React / Angular | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/frontend-guidelines/frontend-practices.md` |
| Caveman Mode (if active) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/caveman/CAVEMAN.md` - **Full cap** |

## Process

### Step -1b - Caveman Mode (Full cap)
1. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/sdd/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full" }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/caveman/CAVEMAN.md`; apply **Full** participation cap + prefs `caveman_level` (Lite skills never escalate); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) during the session.
5. Auto-Clarity + never-compress gates/drafts/paths per `CAVEMAN.md`.

### -1. Re-check guardrails and session

Confirm `guardrails.mdc` and `SESSION.md` are loaded.
If missing, ask user (pt-BR):

```text
Antes da localizacao, confirme:
- guardrails.mdc lido
- SESSION.md carregado

Posso seguir? (sim / ajustar / cancelar)
```


### 0. Frame the Context

* Identify the localization pattern used in the repository:
  * Dotnet: `.resx` resources with `IStringLocalizer<T>`.
  * React: `react-i18next` (`useTranslation()` hook, `t('key')`).
  * Angular: `@angular/core` i18n attributes or packages like `ngx-translate`/`transloco`.
* Confirm the primary language (usually English for resources) and target translation languages.

### 1. Scan for String Literals & Workflow Decision

* Read target files and identify raw text content in HTML tags or hardcoded string variables.
* **Filter out:**
  * Log templates (like warning logs).
  * System keys (like routing paths, config names, constants, and dictionary keys).
* Present a list of candidate strings with suggested keys (e.g. `WelcomeMessage`, `SubmitButtonLabel`).
* Stop and ask the user to choose the workflow execution path to refactor and localize these strings:
  * **Option A - Direct Developer Skill (`/developer`):** For straightforward local string extraction and key replacements.
  * **Option B - Classic SDD (`/sdd-spec` -> `sdd-plan` -> `sdd-develop`):** For massive application-wide localization tasks requiring formal specifications (PRD) and a detailed plan (PLAN) in Portuguese.
  * **Option D - Plain Chat Plan:** Establish a simple task list directly in the chat, executing steps one by one without extra file creations.
* **Wait for explicit user choice** before writing code or initializing another workflow.

### 2. Update Resource Bundles

* Write or append the translations to the resource files:
  * JSON bundles: add key/value fields in `en.json`, `pt.json`, etc.
  * Dotnet XML: add `<data name="Key"><value>Text</value></data>` nodes in target `.resx` files.
* Ensure keys are sorted alphabetically to prevent duplicate entries and maintain layout.

### 3. Code Refactoring

* Replace the hardcoded string literal in the code file with the dynamic localization call.
* Inject the localizer dependency if it is not already available (e.g. adding `private readonly IStringLocalizer<T> _localizer` to C# constructor, or `const { t } = useTranslation()` in React component).

### 4. Build and Verify

* Run the project build script (`dotnet build`, `npm run build`) to ensure that imports, injections, and variables compile correctly.

### 5. Handoff

* Offer committing the refactored code and resources:

```
/commit
```

## Must not

* Extract string keys with generic names (like `Text1`, `String2`).
* Mutate logger strings or database connection configurations.
