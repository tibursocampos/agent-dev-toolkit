# Caveman mode

Optional **response compression** for agent chat after sync. Compresses style, not substance. Does not change sync or validation.

Inspired by [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman) — this toolkit ships a **portable preferences/contract**, not a full port. See [Credits](../credits/).

## Default

**OFF.** Prefs live at `{{SDD_ROOT}}/preferences.json` after sync (`caveman_mode`, `caveman_level`).

## Activate / deactivate

| Command | Effect |
|---------|--------|
| `caveman on` | Enable |
| `caveman off` | Disable |
| `caveman status` | Report on/off + level |
| `caveman lite` \| `full` \| `ultra` | Set level (turns ON if off) |
| `stop caveman` / `normal mode` | Same as off |

## Levels and caps

- **lite** — tight full sentences  
- **full** — default when ON; fragments OK  
- **ultra** — maximum compression  

Skills may cap intensity (planning often Lite; develop Full). **NEVER** compress for `help-skills`, `commit`, `push`, `open-github-pr`.

## Never compressed

Product drafts (FEATURE / STORY / PRD) and confirmation gates stay full prose — Caveman never compresses them. Paths, errors, and security notices stay intact too.

## Auto-Clarity

Drop compression for security warnings, irreversible confirms, ambiguous multi-step order, or when the user asks to clarify — then resume.

## When to use

Prefer ON for long review / orchestration. Prefer OFF for short Q&A (loading the contract has a cost).

Full guide: [docs/guides/07-caveman-mode.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/guides/07-caveman-mode.md) · contract: `core/skills/_shared/caveman/CAVEMAN.md`.

Next: [Using skills](../using-skills/) · [Credits](../credits/) · [Home](../)
