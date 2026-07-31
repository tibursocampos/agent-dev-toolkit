# Skill template - gate-first header

Copy the block below immediately after YAML frontmatter in every `SKILL.md`.

Skill body (process, guardrails, handoff) must be **English**. User-facing prompts: **Ask user (pt-BR):** …

---

## YAML frontmatter (required)

```yaml
---
name: your-skill-name
description: >-
  <WHAT in one sentence>. <WHEN / natural phrases>. Use when invoking /your-skill-name.
---
```

| Field | Rules |
|-------|--------|
| `name` | kebab-case; max 64 chars; equals folder name |
| `description` | English, third person; **WHAT + WHEN**; soft target **~180-280** chars; hard max **1024** (Cursor). Always include `"/<name>"` matching `name`. Prefer slash-menu readability over listing every stack detail. |

**Invoke (canonical in docs / handoffs / Trigger):** `` `/<name> - <args>` ``  
**Compat:** `use skill <name>` still works (hooks / muscle memory); do not make it the primary example.

---

## STOP - Read before ANY tool call

1. Read `{{GUARDRAILS_PATH}}`
2. Read `_shared/sdd-artifacts/SESSION.md`; load session-state for `$Cwd`
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

For **`orchestrate-analyze` / `orchestrate-deliver` / `orchestrate-develop`**, change the PIPELINE line to: `PIPELINE.md read (required for orchestrate-*)`.

### Caveman (participating skills)

Add under **Process** (after gate check). Cap = `Lite` | `Full` | `Never` per `_shared/caveman/CAVEMAN.md` participation table. Always-on rule `caveman-mode.mdc` also reads prefs; skills still run Step -1b for cap.

**Lite / Full:**

```
### Step -1b - Caveman Mode ({Lite|Full} cap)
1. Read {{SDD_ROOT}}/preferences.json (create { "caveman_mode": false, "caveman_level": "full" } if missing).
2. If caveman_mode is false: continue without compression.
3. If true: load _shared/caveman/CAVEMAN.md; apply skill cap + caveman_level; show [Caveman] activation notice once.
4. Honor caveman on|off|status|lite|full|ultra during the session.
5. Auto-Clarity + never-compress gates/drafts/paths.
```

**NEVER** (`commit`, `push`):

```
### Caveman Mode
**NEVER** - Ignore caveman_mode. Clear prose only. Do not compress commit/PR text.
```

Lazy-load row when applicable: `| Caveman Mode (if active) | {{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md - **{Lite|Full} cap** |`

---

## Skill-specific sections (below the header)

The STOP block above is ~27 lines and does not count toward editorial budget.

**Size:** hard limit **500 lines** total per `SKILL.md` (Cursor / Agent Skills). Soft targets: workflow skills 150-300 lines after the gate; atomic skills (`push`) may be shorter. Put long templates in `reference.md` but keep decision tables and must-not inline.

- **Trigger** - lead with `/<name>`; optional one-line note that `use skill <name>` still works
- **Outcome**
- **Lazy-load**
- **Process** (include Caveman Step -1b or NEVER block)
- **Must not**
- **Handoff** - exact next string: `` `/next-skill - <full-paths>` ``

### New `*-developer` skills — subagent-first (mandatory)

Align with US02: do **not** redefine spawn policy in the skill body. Point + short Process echo only.

**Lazy-load row (required):**

```
| Subagent-first / SPAWN.md | {{TOOLKIT_ROOT}}/skills/_shared/developer-common/subagent-first.md, {{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md |
```

**Process block (after Caveman Step -1b, before workspace):**

```
### Subagent-first (before implement)

Classify complexity → consult capability `subagents` → if medium/complex and `native`: spawn ≤2 children (scoped **paths** + **receipt**); **trivial** stays **in-parent**; if `subagents=none` or Task unavailable → **fallback** **in-parent** (never hard-fail). Load `SPAWN.md` + `subagent-first.md`; do not paste guidelines into child prompts.
```

**Must not (echo markers):** paste guideline packs into child prompts; spawn for **trivial**; hard-fail when `subagents` is `none` or Task unavailable (use **fallback** **in-parent**).

Stable assert markers (exact substrings): `SPAWN.md`, `subagents`, `in-parent`, `fallback`, `receipt`, `paths` — see `subagent-first.md`.

Gold-bar reference: `dotnet-developer/SKILL.md` (gate, SDD table, developer-common steps, SPAWN).

### Develop skills - mandatory session end

```
### STOP - Session end (mandatory)
- Show git diff summary
- Show test results (if applicable)
- Update PLAN/tasks/plan.md
- Reset session-state gates to false
- Ask user (pt-BR): "Passo concluído. Inicie nova conversa para o próximo passo."
- DO NOT proceed to next step
```
