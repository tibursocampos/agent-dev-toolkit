# 07 — Caveman Mode

Optional **response compression** for agent chat: shorter replies, same technical substance. It does **not** change sync, validation, or application code style.

Canonical contract (after sync): `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md`  
Always-on policy: `caveman-mode` under published rules.  
Credits: [CREDITS.md](../CREDITS.md) — inspired by [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman); portable contract only, not a full port.

## Default

**OFF.** If `preferences.json` is missing, agents create:

```json
{ "caveman_mode": false, "caveman_level": "full" }
```

Location: `{{SDD_ROOT}}/preferences.json` (under the agent’s published SDD root after sync). At runtime, resolve via host-aware `effective_SDD_ROOT` (`STORAGE.md`) so prefs never land under a foreign agent home.

## Commands (in chat)

| Command | Effect |
|---------|--------|
| `caveman on` | Turn mode ON |
| `caveman off` | Turn mode OFF |
| `caveman status` | Report on/off + level |
| `caveman lite` / `full` / `ultra` | Set level; turns ON if it was off |
| `stop caveman` / `normal mode` | Same as `caveman off` |

When ON, agents show once per session:  
`[Caveman] Modo ativo (respostas compactas, level=…). Digite caveman off para desativar.`

## Levels

| Level | Behavior |
|-------|----------|
| **lite** | No filler; keep full sentences |
| **full** (default when ON) | Fragments OK; drop articles where clear |
| **ultra** | Maximum compression; prefer long orchestration/review sessions |

Skills may **cap** intensity (e.g. planning skills stay Lite even if prefs say `ultra`). Effective level = min(skill cap, prefs).

## Auto-Clarity

Temporarily drop compression for: security warnings, irreversible confirmations (`sim` / `ajustar` / `cancelar`), multi-step sequences that become ambiguous when compressed, compression-caused ambiguity, or when the user asks to clarify. Resume after the clear part.

## Never compressed

- Confirmation gates and artifact drafts shown in chat  
- Paths, identifiers, CLI commands, error messages  
- Security / Git blocking notices  
- Code, commit messages, PR bodies (always normal English per toolkit policy)

## NEVER skills

These ignore `caveman_mode` for chat compression: **`help-skills`**, **`commit`**, **`push`**, **`open-github-pr`**.

## When to use

| Prefer ON | Prefer OFF |
|-----------|------------|
| Long review, Forma C orchestration, verbose debug | Short coding Q&A (loading the contract can cost more than you save) |

Optional continuity compaction (`COMPACT.md`) is separate and needs explicit user `sim` — not a port of upstream `caveman-compress`.

## Related

- [02-using-skills.md](02-using-skills.md)  
- [SKILLS.md](../SKILLS.md) / installed `OPERATOR.md`  
- Published site: [docs-site/caveman.md](../../docs-site/caveman.md) (EN) · [caveman.pt.md](../../docs-site/caveman.pt.md) (PT)  
