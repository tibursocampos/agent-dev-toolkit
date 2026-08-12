# Caveman Mode - Response Compression Guideline

Single source of truth for Caveman Mode behavior across all participating skills.
Load on demand from skills at step -1 - do not pre-load.

Install path after sync: `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/caveman/CAVEMAN.md`

Inspired by: https://github.com/juliusbrussee/caveman  
Portable contract only — not a full port of that repository. Acknowledgments: `docs/CREDITS.md`.

---

## What Caveman Mode Does

Forces the agent to respond in telegraphic, concise fragments — eliminating
conversational filler, preambles, and polite wrapper text — while preserving
100% of technical content (code, paths, artifact drafts, confirmation gates).

**Mouth smaller, brain same.** Compress style, not substance. Compress style, not language (chat stays pt-BR when that is the toolkit language policy).

**Expected savings:** often 22–87% of *output prose* tokens on verbose replies.  
**Honest cost:** loading this file adds ~1–1.5k input tokens per turn. Net-negative on short Q&A (~150 output tokens). Prefer ON for long review/debug/orchestration; OFF for terse coding Q&A. See `docs/guides/07-caveman-mode.md` and `docs/CREDITS.md`.

---

## Preferences File

**Location:** `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/sdd/preferences.json`

**Structure:**
```json
{
  "caveman_mode": false,
  "caveman_level": "full"
}
```

- `caveman_mode` — master switch (bool).
- `caveman_level` — `lite` | `full` | `ultra` (default `full` when mode is ON). Skill participation may *cap* intensity (e.g. planning skills use Lite rules even if prefs say `ultra`).

**Resolution algorithm (run by always-on rule `caveman-mode` and at Step -1 of participating skills):**

```
1. If preferences.json missing: create { "caveman_mode": false, "caveman_level": "full" }. Mode = OFF.
2. Read caveman_mode / caveman_level (missing level => "full").
3. If caveman_mode false: Mode = OFF — skip compression rules.
4. If true: Mode = ON — apply intensity (see Levels), show activation notice once per session.
5. In-session commands (not roleplay; no cave-themed language or emojis):
   - "caveman on"              -> caveman_mode true; confirm: "[Caveman] Modo ativado (respostas compactas)."
   - "caveman off"             -> caveman_mode false; confirm: "[Caveman] Modo desativado."
   - "caveman status"          -> report on/off + level.
   - "caveman lite|full|ultra" -> set caveman_level; if mode was off, turn on; confirm level.
```

**Activation notice (when mode is ON):**
> [Caveman] Modo ativo (respostas compactas, level={level}). Digite `caveman off` para desativar.

**Persistence:** Mode stays ON every reply until `caveman off` / `normal mode` / `stop caveman`. Do not silently drift back to filler mid-session.

---

## Intensity Levels

| Level | Behavior |
|-------|----------|
| **lite** | No filler/hedging. Keep articles and full sentences. Professional but tight. |
| **full** (default) | Drop articles where clear. Fragments OK. Short synonyms. No tool-call narration. No decorative emoji. Quote shortest decisive error line unless asked for full log. |
| **ultra** | Strip conjunctions when order stays unambiguous. One word when enough. State each fact once. Prefer for long Forma C / review sessions only. |

**Pattern (full/ultra):** `[thing] [action] [reason]. [next step].`

Example — "Why does this component re-render?"
- lite: "Component re-renders because you create a new object reference each render. Wrap it in `useMemo`."
- full: "New object ref each render. Inline object prop = new ref = re-render. Wrap in `useMemo`."
- ultra: "Inline obj prop, new ref, re-render. `useMemo`."

### Tokenizer hygiene (all levels)

- Standard acronyms OK: DB, API, HTTP, PR, CI.
- **Never invent** abbreviations (`cfg`, `impl`, `req`, `res`, `fn`) — tokenizer often splits them; zero token saved, clarity lost.
- **No causal arrows** (`→`) as prose shorthand — own token, saves nothing.
- Technical terms, API names, CLI commands, commit-type keywords (`feat`/`fix`), error strings: verbatim.

---

## Auto-Clarity

**Drop caveman** (use clear prose) when:

- Security warnings
- Irreversible action confirmations (including `(sim / ajustar / cancelar)` gates)
- Multi-step sequences where fragment order or omitted conjunctions risk misread
- Compression itself creates technical ambiguity
- User asks to clarify or repeats the question

Resume caveman after the clear part is done.

---

## Boundaries

- **Code / commit messages / PR bodies:** write normal (English per toolkit policy). Never caveman-compress artifact text.
- **NEVER skills** (`help-skills`, `commit`, `push`, `open-github-pr`): ignore `caveman_mode` for chat around those flows — clear prose only.
- Do not announce the style in third person ("me caveman think"). Exception: activation/status confirmations and explicit user questions about the mode.

---

## Participation Levels

| Skill / Context | Cap when mode ON |
|---|---|
| `help-skills`, `commit`, `push`, `open-github-pr` | **NEVER** — excluded regardless of setting |
| `sdd-spec`, `sdd-plan` | **LITE** |
| `orchestrate-analyze`, `orchestrate-deliver` | **LITE** |
| `document-plan`, `refine-story`, `memory-bank-init` | **LITE** |
| `sdd-develop`, `orchestrate-develop`, `document-implement` | **FULL** (or prefs level if lower) |
| `split-story-checklist`, `code-review`, `developer`, `repair-dotnet-build`, `test-coverage` | **FULL** |
| `*-developer`, ops (`api-integrate`, `containerize`, `i18n-manager`, `performance-profile`, `refactor`) | **FULL** |
| Forma C specialist passes / agent prompts | **FULL** chat; **ultra receipt** schema when mode ON (see `_shared/agents/ROUTING.md`) |
| Subagent child prompts, execution style, and returns | Same as parent intensity; Caveman-scoped I/O per `SPAWN.md` / `RECEIPT.md` / `orchestrator-session` policy |
| General chat | **FULL** (or prefs `caveman_level`) |

**Skill cap vs prefs:** effective level = min(skill cap, prefs `caveman_level`) with NEVER winning. Lite skills never escalate to full/ultra from prefs.

**Always protected (never compressed under any mode):**
- Confirmation gates: `(sim / ajustar / cancelar)` blocks
- Artifact drafts shown in chat (FEATURE, STORY, PRD, PLAN, CONTINUITY, commit suggestions)
- Technical identifiers: file paths, function/type names, CLI commands, error messages
- Security guardrails and Git blocking notices

---

## Lite Mode Rules

**Strip:** opening preambles/framing before questions; closing wrap-ups after drafts; redundant restatements.

**Preserve intact (plus universal protections):** clarifying questions; draft previews; gates; section headers and structured draft content.

---

## Full / Ultra Mode Rules

**Strip completely:**
- Opening preambles ("Claro! Vou ajudar com isso.", "Ótima pergunta!")
- Closing pleasantries ("Espero ter ajudado!")
- Redundant framing ("Como solicitado…", "Conforme discutimos…")
- Verbose progress narration / tool-call play-by-play

**Replace with:**
- Direct action ("Analisando X.", "Erro em Y:", "Alteração:")
- Bullet-first lists without lead-in
- Single-line status ("Task concluída.", "Falha:")

**Always preserve intact:** code blocks; paths; errors/stack traces (shortest decisive line OK unless full log requested); command suggestions; gates; artifact drafts.

---

## Phrase Reference

### Blocked (Full / Ultra)
| Instead of | Use |
|---|---|
| "Claro! Vou ajudar com isso. Aqui está o que farei:" | *(nothing — go straight to action)* |
| "Analisando o arquivo solicitado, identifiquei que..." | "Identificado:" |
| "Após concluir esta etapa, o próximo passo será..." | "Próximo: Task N+1" |
| "Espero que isso resolva o problema!" | *(omit)* |
| "Com prazer! Antes de prosseguir, preciso verificar..." | "Verificando:" |

### Always Preserved (any mode)
```
Posso gravar em `{path}`? (sim / ajustar / cancelar)
```
```
Nenhum comando mutante do Git sera executado sem autorizacao explicita.
```
```
Task N marcada como concluida em `{path}`.
```

---

## Continuity / memory compact (optional)

When mode ON, agents may propose compacting prose in `CONTINUITY.md` or memory-bank narrative files (`known-risks.md`, notes) per `_shared/caveman/COMPACT.md`. Never compact PRD/PLAN/STORY bodies via that flow. Always backup + user `sim`.

---

## Integration

| Consumer | Load condition |
|---|---|
| Participating skills (see table) | Step -1, if `caveman_mode` true |
| `rules/caveman-mode.md` (alwaysApply) | Global toggle + preference check every session |
| `rules/guardrails.md` / `AGENTS.md` | Never-compress + command UX pointers |
| Forma C agent prompts / subagent I/O | Receipt schema when mode ON; child prompts/returns Caveman-scoped (`SPAWN.md`, `RECEIPT.md`) |

### Canonical Step -1 block (copy into skills)

```
### Step -1b - Caveman Mode
1. Read E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/sdd/preferences.json (create default if missing).
2. If caveman_mode is false: continue without compression.
3. If true: load _shared/caveman/CAVEMAN.md; apply skill participation cap + caveman_level;
   show activation notice once; honor on/off/status/level commands.
4. NEVER skills (commit, push): skip compression regardless of prefs.
```
