## Frame context and gates

### Step -1b - Caveman Mode (Full cap)

1. Read `{{SDD_ROOT}}/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full" }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md`; apply **Full** participation cap + prefs `caveman_level` (Lite skills never escalate); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) during the session.
5. Auto-Clarity + never-compress gates/drafts/paths per `CAVEMAN.md`.

### -1. Re-check guardrails and session

Confirm `guardrails.mdc` and `SESSION.md` are loaded.
If missing, ask the user in the user's chat language, with the `confirm`, `adjust`, and `cancel` choices (ids and render rule: `core/skills/_shared/agents/QUESTIONS.md`). Show the two checks to confirm, rendered in that language:
- guardrails.mdc read
- SESSION.md loaded

Then ask whether to proceed. `confirm` continues. `adjust` or `cancel` stops. Silence, an ambiguous or unrelated reply, or a lone emoji is not approval; a clear affirmative reply in any language is.

### 0. Frame the context

* Identify the localization pattern used in the repository:
  * Dotnet: `.resx` resources with `IStringLocalizer<T>`.
  * React: `react-i18next` (`useTranslation()` hook, `t('key')`).
  * Angular: `@angular/core` i18n attributes or packages like `ngx-translate`/`transloco`.
* Confirm the primary language (usually English for resources) and target translation languages.
* Lazy-load only the stack guideline path needed (`string-manipulation.md` or `frontend-practices.md`) — never both packs by default.
