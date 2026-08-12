---
description: Automatically apply response compression rules (Caveman Mode) if enabled in preferences
alwaysApply: true
---

# Caveman Mode (Response Compression)

Toolkit response-compression commands — **not** roleplay. No cave-themed language or emojis. Use ASCII `[Caveman]` in notices.

Full contract: `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/skills/_shared/caveman/CAVEMAN.md` (load only when mode is ON).

## 1. In-session commands

Watch chat for exact commands; update `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/sdd/preferences.json`:

| Command | Action |
|---------|--------|
| `caveman on` | Set `caveman_mode: true` (keep or default `caveman_level` to `full`). Confirm: `[Caveman] Modo ativado (respostas compactas).` |
| `caveman off` | Set `caveman_mode: false`. Confirm: `[Caveman] Modo desativado.` |
| `caveman status` | Report on/off + `caveman_level`. |
| `caveman lite` / `caveman full` / `caveman ultra` | Set `caveman_level`; turn mode on if off; confirm level. |

Also accept `stop caveman` / `normal mode` as off.

## 2. Preference check (every session / task start)

1. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/sdd/preferences.json`.
2. If missing: create `{ "caveman_mode": false, "caveman_level": "full" }`.
3. If `caveman_mode` is `true`:
   - Load `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/skills/_shared/caveman/CAVEMAN.md`.
   - Apply intensity: `lite` | `full` | `ultra` (default `full`), capped by active skill participation table in that file.
   - Show once: `[Caveman] Modo ativo (respostas compactas, level={level}). Digite caveman off para desativar.`
4. Skills `commit` and `push`: **NEVER** compress — clear prose only.

## 3. Compression when enabled

**Always protect (never compress):** code fences; paths; errors/stacks; CLI suggestions; gates `(sim / ajustar / cancelar)`; artifact drafts; security/git-block notices.

**Auto-Clarity — drop caveman temporarily for:** security warnings; irreversible confirms; multi-step order that fragments could scramble; compression causing technical ambiguity; user asks to clarify or repeats the question. Resume after.

**Tokenizer hygiene:** no invented abbrevs (`cfg`/`impl`/`req`/`res`/`fn`); no prose `→`; keep real tech terms exact.

**Lite** (planning skills: `sdd-spec`, `sdd-plan`, orchestrate analyze/deliver, document-plan, refine-story, memory-bank-init): strip framing only; keep questions, drafts, headers.

**Full / Ultra** (develop, review, ops, stack developers, general chat): telegraphic fragments; pattern `[thing] [action] [reason]. [next].`; no preambles/pleasantries/tool narration. Ultra = max terseness when unambiguous.

**Boundaries:** code, commit messages, and PR bodies stay normal prose (English). Chat style only.

**Subagents:** when mode ON, child prompts and returns follow Caveman (inherit parent intensity; end receipt per `RECEIPT.md`). When OFF, still prefer compact receipts for token control. See `orchestrator-session.md` + `SPAWN.md`.
