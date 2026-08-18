# Product

## Register

brand

## Users

Two equal primary audiences for the public docs site:

1. **Explorers** — developers who have not synced the toolkit yet; they need a clear “why this exists” and a one-command path to try it.
2. **Operators** — people who already use a supported agent (Cursor, Claude Code, Copilot, Codex, Hermes, OpenHands, …); they need the right sync/validate commands, agent install roots, and which Forma/skill to invoke.

Secondary: maintainers who need validation/CI and governance (reachable, not on the first viewport).

## Product Purpose

**agent-dev-toolkit** is a multi-agent skills core with per-agent adapters. The GitHub Pages site exists to explain, onboard, and promote that toolkit: one shared SDD/skills/policy surface published into many agent homes via PowerShell sync.

Success: a visitor understands the value in one scroll, picks their agent, runs interactive `toolkit.ps1`, and reaches a working skill invoke (e.g. `/sdd-spec`) without reading the whole repo.

## Brand Personality

**precise · multi-agent · operator-first**

Voice: confident, concrete, command-oriented. Prefer “run this / get that” over abstract AI marketing. Emotional goals: clarity and trust (safe defaults, fixture-first CI), curiosity (one core, many agent homes), competence (not playful gimmicks).

## Anti-references

- Default Material for MkDocs purple/indigo theme with no overrides
- Generic “AI landing” (glow, pill clusters, metric card grids, gradient text)
- Editorial magazine lane (display serif + italic drop caps + broadsheet columns)
- Dashboard-style first viewport
- Monospace costume on all marketing copy (mono belongs in code blocks only)
- Translating or rewriting `core/skills/**` SKILL bodies as part of the docs site

## Design Principles

1. **One job per fold** — home sells sync; deeper pages teach; maintainers stay secondary.
2. **Show the pipe** — core → adapters → agent homes is the visual story, not feature laundry lists.
3. **Operator honesty** — capability and install-root claims match the registry and adapters.
4. **Locale parity for entry paths** — EN default; PT-BR for home + get started + using skills in v1.
5. **Safe by default** — document fixture sync first; live home + `-AllowUserHome` as an explicit choice.

## Accessibility & Inclusion

- Target **WCAG 2.2 AA** for the docs site (contrast 4.5:1 body, 3:1 large text).
- Full keyboard path for nav, language switcher, agent switcher, and copy buttons.
- Honor `prefers-reduced-motion: reduce` for all entrance/interaction motion.
- Language switcher must expose current locale and destination in accessible names (EN / Português).
