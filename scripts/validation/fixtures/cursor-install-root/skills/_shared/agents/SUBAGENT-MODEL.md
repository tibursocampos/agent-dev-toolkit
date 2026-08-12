# Task subagent model policy (Forma C)

Contract for **LLM model** on Cursor `Task` spawns from `orchestrate-analyze`, `orchestrate-deliver`, `orchestrate-develop`, and other parent spawns under `SPAWN.md`. Orthogonal to **when** to spawn (`ROSTER.md`), **native vs fallback** (`SPAWN.md` + `orchestrator-session` policy), and to Memory Bank Gate policy `auto` (bank health — not the Cursor Auto model).

Install path after sync: `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/skills/_shared/agents/SUBAGENT-MODEL.md`

## Default (almost every spawn)

1. Call `Task` **without** the `model` parameter.
2. Child uses the **same model as the parent session** (whatever the user selected for this chat).
3. Do **not** ask the user about model choice for routine work.
4. Do **not** pick composer / gpt / grok / premium / alternate slugs on your own.
5. If Caveman is ON: require end-of-pass **receipt** per `RECEIPT.md`; inherit parent intensity; keep gates/drafts clear (Auto-Clarity). Child I/O remains Caveman-scoped per `SPAWN.md`.

## Different model — only when extremely necessary

Ask about a **different** model **only** when the upcoming Task is clearly very hard **and** an alternate slug is extremely necessary. Prefer **not** asking — keep the parent session model.

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

**Must** get explicit user approval before passing any non-default `model`. Offer all three options:

```text
Antes de abrir o subagente `{role}` nesta tarefa difícil:
motivo: {1-2 frases}
Sugiro modelo `{slug}` (diferente do modelo desta sessão).

1) sim - usar `{slug}`
2) manter o modelo da sessão pai (omitir `model`)
3) cancelar spawn
```

Suggest **exactly one** alternate slug. Keep the reason to 1–2 sentences.

| Answer | Action |
|--------|--------|
| **1** / **sim** (approve alternate) | Pass `model` **only** for that approved slug on this Task |
| **2** / keep parent / “auto” / “pai” | Spawn **without** `model` (same as parent session) |
| **3** / **cancelar** | Do not spawn |
| **silence** | Spawn **without** `model` — silence ≠ approval for an alternate model |

User may also name a different allowed slug; only then use that slug (still requires an explicit choice, not silence).

## Must not

- Pass `model` without this gate **and** explicit user approval of that alternate slug
- Ask the model question on every spawn
- Ask for more than one premium/alternate suggestion at once without a single recommended default
- Treat silence as approval to use an alternate / premium model
- Confuse Memory Bank policy `auto` with Cursor Auto model
- Rely on hooks to enforce model choice (hooks never select models)

## Parallel batches

If several Tasks spawn together and only one is hard: ask the gate **only** for that Task; others omit `model`. If several are hard: one combined ask listing roles, or ask per hard Task before its wave — still never silent alternate-model approval.
