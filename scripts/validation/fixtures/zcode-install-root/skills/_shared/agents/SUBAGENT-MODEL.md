# Task subagent model policy (Forma C)

Contract for **LLM model** on Cursor `Task` spawns from `orchestrate-analyze`, `orchestrate-deliver`, and `orchestrate-develop`. Orthogonal to **when** to spawn (`ROSTER.md`), **native vs fallback** (`SPAWN.md`), and to Memory Bank Gate policy `auto` (bank health — not the Cursor Auto model).

Install path after sync: `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/agents/SUBAGENT-MODEL.md`

## Default (almost every spawn)

1. Call `Task` **without** the `model` parameter.
2. Child inherits the parent chat model (user’s Cursor selection — typically Auto / cheapest).
3. Do **not** ask the user about model choice for routine work.
4. Do **not** pick composer / gpt / grok / premium slugs on your own.
5. If Caveman is ON: require end-of-pass **receipt** per `RECEIPT.md`; inherit parent intensity; keep gates/drafts clear (Auto-Clarity).

## Rare premium gate

Ask about a different model **only** when the upcoming Task is clearly very hard. Prefer **not** asking.

### Threshold (narrow)

Ask only if **at least two** signals match, **or** one obvious hard-stop:

| Signal | Examples |
|--------|----------|
| O1 | `complexity=complex` **and** two or more specialists (e.g. `architect` + `security`), or deep brownfield impact |
| O2 | Story with ambiguous contracts/auth/schema and high risk of a wrong PRD |
| O3 | PLAN step = cross-cutting architecture, destructive migration, sensitive security, or a hermetic bug that already failed on default |
| User | User already marked the work **crítico** / asked for maximum quality |

### Do **not** ask for

Simple STORY draft, ordinary PRD/PLAN, CRUD, wiring, mechanical tests, CONTINUITY-only updates, single low-ambiguity specialists.

### Prompt (pt-BR) — only when the gate fires

```text
Antes de abrir o subagente `{role}` nesta tarefa difícil:
motivo: {1-2 frases}
Sugiro modelo `{slug}` (custa mais).

1) sim - usar `{slug}`
2) não - herdar Auto/pai (padrão barato)
3) cancelar spawn
```

Suggest **exactly one** slug. Keep the reason to 1–2 sentences.

| Answer | Action |
|--------|--------|
| **sim** | Pass `model` **only** for that approved slug on this Task |
| **não** / “auto” / silence | Spawn **without** `model` (RN01: silence ≠ premium approval) |
| **cancelar** | Do not spawn |

User may also name a different allowed slug; only then use that slug.

## Must not

- Pass `model` without this gate **and** explicit user **sim** (or an explicit user-named slug for this spawn)
- Ask the model question on every spawn
- Ask for more than one premium suggestion at once without a single recommended default
- Treat silence as approval to use premium
- Confuse Memory Bank policy `auto` with Cursor Auto model
- Rely on hooks to enforce model choice (hooks never select models)

## Parallel batches

If several Tasks spawn together and only one is hard: ask the gate **only** for that Task; others omit `model`. If several are hard: one combined ask listing roles, or ask per hard Task before its wave — still never silent premium.
