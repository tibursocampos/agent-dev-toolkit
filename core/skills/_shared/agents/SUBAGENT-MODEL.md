# Subagent model policy (Orchestrated Delivery)

Contract for **LLM model** on native subagent spawns (`Agent` calls) from `orchestrate-analyze`, `orchestrate-deliver`, `orchestrate-develop`, and other parent spawns under `SPAWN.md`. Orthogonal to **when** to spawn (`ROSTER.md`), **native vs fallback** (`SPAWN.md` + `orchestrator-session` policy), and to Memory Bank Gate policy `auto` (bank health — not a host auto model).

Install path after sync: `{{TOOLKIT_ROOT}}/skills/_shared/agents/SUBAGENT-MODEL.md`

## Invocation axes (A ≠ B ≠ C)

Normative split — do **not** conflate axes. Marker: `A≠B≠C`.

| Axis | Owns | Rule |
|------|------|------|
| **A** | `SPAWN.md` | Spawn vs in-parent (thin-trivial in-parent preserved). **This file does not decide spawn.** |
| **B** | This file | Default: **omit `model`** → child **inherits** the parent session model (RN02). |
| **C** | This file | No alternate-slug escape without the gate below **and** explicit user approval. Silence ≠ approval. |

Cross-PLAN: every spawn omits `model` by default (Axis B). Pinning child model ≠ parent by default is forbidden (FEATURE non-goal / RN02).

## Default (almost every spawn)

1. Call `Agent` **without** the `model` parameter.
2. Child uses the **same model as the parent session** (whatever the user selected for this chat).
3. Do **not** ask the user about model choice for routine work.
4. Do **not** pick composer / gpt / grok / premium / alternate slugs on your own.
5. If Caveman is ON: require end-of-pass **receipt** per `RECEIPT.md`; inherit parent intensity; keep gates/drafts clear (Auto-Clarity). Child I/O remains Caveman-scoped per `SPAWN.md`.

## Different model — only when extremely necessary

Ask about a **different** model **only** when the upcoming Agent call is clearly very hard **and** an alternate slug is extremely necessary. Prefer **not** asking — keep the parent session model.

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

### Prompt (user chat language) — only when the gate fires

**Must** get explicit user approval before passing any non-default `model`. Ask in the user's chat language with the three choices below. Ids and render rule (host question component or numbered text): `core/skills/_shared/agents/QUESTIONS.md`.

- `confirm` - use the one suggested alternate slug `{slug}` for `{role}` on this Agent call.
- `decline` - keep the parent session model (omit `model`).
- `cancel` - do not spawn.

Show the role, a reason of 1–2 sentences, and the one suggested slug (different from the session model). Suggest **exactly one** alternate slug.

| Answer | Action |
|--------|--------|
| `confirm` (approve alternate) | Pass `model` **only** for that approved slug on this Agent call |
| `decline` (keep parent; words such as “pai” / “omitir” map here) | Spawn **without** `model` (same as parent session). User saying **Auto** (host model picker) is **not** an alternate-slug choice — still omit `model`. |
| `cancel` | Do not spawn |
| Silence, an ambiguous or unrelated reply, or a lone emoji | Not approval. The question stays `pending` and the Agent call waits (QUESTIONS.md States). No alternate `model` is passed. |

A different allowed slug the user names counts as `confirm` for that slug only, and only after an explicit choice, never silence.

## Host UI limit (RNF-003)

Toolkit enforces Axis B/C in **skills**, **publish honesty**, and **CI**. If the **host UI** rewrites the child model after spawn, that rewrite is **outside** toolkit control — document the limit; do **not** claim a hard runtime guarantee against UI override.

## Must not

- Pass `model` without this gate **and** explicit user approval of that alternate slug
- Ask the model question on every spawn
- Ask for more than one premium/alternate suggestion at once without a single recommended default
- Treat silence as approval to use an alternate / premium model
- Confuse Memory Bank policy `auto` with a host auto model, or use ambiguous inherit-parent + Auto spawn wording
- Rely on hooks to enforce model choice (hooks never select models)
- Overclaim that CI/skills prevent host-UI model rewrite after spawn

## Parallel batches

If several Agent calls spawn together and only one is hard: ask the gate **only** for that Agent call; others omit `model`. If several are hard: one combined ask listing roles, or ask per hard Agent call before its wave — still never silent alternate-model approval.
