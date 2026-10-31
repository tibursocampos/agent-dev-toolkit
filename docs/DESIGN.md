# DESIGN — agent-dev-toolkit docs site

Captured from `docs-site/stylesheets/extra.css` as it ships today. This describes the site as built, not a target. Where the design brief (`docs/DESIGN-BRIEF.md`) asks for something different, the gap is listed under Known drift.

Register: brand (docs site). Mode: Read (structure for comprehension, then a readable article).

## Colors

Dark only. Tokens live on `:root`; Material's palette variables are bridged to them.

| Token | Value | Role |
|-------|-------|------|
| `--bg` | `oklch(0.16 0.02 250)` | Page and header background |
| `--surface` | `oklch(0.22 0.025 250)` | Code blocks, search field, skip link, admonitions |
| `--text` | `oklch(0.93 0.01 250)` | Body and headings |
| `--muted` | `oklch(0.70 0.02 250)` | Secondary text, nav inactive, table lines |
| `--accent` | `oklch(0.78 0.14 195)` | Links, active nav, primary fill |
| `--accent-dim` | `oklch(0.45 0.08 195)` | Borders, focus ring halo, dividers |
| `--on-accent` | `oklch(0.18 0.035 250)` | Text on the accent fill (dark ink, AA) |
| `--danger` | `oklch(0.65 0.18 25)` | Error state, warning admonition |

Derived states use `color-mix(in oklch, …)`: hover lightens the accent 12% toward white, pressed darkens it 18% toward black, and tinted fills use the accent at 10–22% over `--surface`.

Focus is a two-ring halo: `0 0 0 2px var(--bg), 0 0 0 4px var(--accent)`.

## Typography

| Role | Family | Size as shipped | Weight |
|------|--------|-----------------|--------|
| Body (`.md-typeset`) | Atkinson Hyperlegible | 0.9375rem (15px), line-height 1.55 | 400 |
| Headings h1 / h2 / h3 | Sora | 2.25rem / 1.6rem / 1.3rem, tracking −0.03em | 600 |
| Code, `pre`, `kbd` | JetBrains Mono | 0.78125rem (12.5px), line-height 1.45 | 400 |
| Left nav, right TOC | Atkinson Hyperlegible | 0.8125rem (13px), line-height 1.35 | 400; active 600 |
| Table cells | Atkinson Hyperlegible | 0.9375rem (15px) | 400 |
| Download links | Atkinson Hyperlegible | 0.875rem | 600 |

Root font size is 100%, so `1rem` is 16px.

## Spacing and shape

Spacing scale: `--space-1` 0.25rem through `--space-8` 4rem (steps 0.25, 0.5, 0.75, 1, 1.5, 2, 3, 4rem).

Radius: `--radius-sm` 0.25rem (controls, code), `--radius-md` 0.375rem (skip link). Article measure: `--measure` 72ch. Content width: `.md-grid` max 96rem.

## Components

- **Header and tabs:** flat, `--bg` background, 1px accent-dim bottom border, no shadow.
- **Search:** 1.75rem tall field on `--surface`; 11rem wide from 60em.
- **Tables:** full width, no card chrome, 1px muted bottom rule per row, cells wrap, scroll inside `md-typeset__scrollwrap`.
- **Download link** (`a.file-download`): accent fill, `--on-accent` text, 2.75rem min height, nowrap.
- **Skip link** (`.adt-skip-link`): hidden until focused, then slides in from the top.
- **Admonitions and code:** `--surface` background; warning admonitions use `--danger`.
- **Footer:** 1px accent-dim top rule.

No motion. The load reveal was removed because no page used it. Nothing animates.

## Layout

- Home: prose, a single SVG figure (`assets/core-adapters-diagram.svg`, `.home-diagram`, max 36rem), then a four-row "I want to / Go to" table and a line of secondary links.
- Get started: prerequisites table, bootstrap download table (one `a.file-download` per file), then sections.
- Reading pages: left nav, article, right TOC, Material's three-column grid.

## Type sizes vs brief

Fixed to match the brief and checked in the browser: body 15px, code 12.5px, nav and TOC 13px, table cells 15px.

## Removed

The unused home and launcher rules were removed from `extra.css`: the hero, CTA, agent switcher, command table, launcher and reveal selectors. No page used them.

`docs-site/javascripts/agent-switcher.js` was removed, along with its entry in `mkdocs.yml`.

## Diagram

The SVG is a 560 × 300 stack: core, adapters, agent install roots. The ten agent names are plain text under it, so they stay legible on a phone. Labels are 22px and 18px in the drawing, which reads about 12–14px at 375px. The Portuguese page uses its own SVG.

## Focus

The focus ring uses `--accent` for its outer halo, so it stays visible on the dark background.

## Do

- Keep the dark teal scheme and the single accent.
- Use mono only in code and file names.
- Let the SVG carry the visual weight on the home.
- Keep table cells readable at 15–16px, not 18px.

## Don't

- Default Material purple or indigo.
- Gradient text, glow, metric cards, pill clusters on the home.
- A copy button beside a command that is already on screen.
- Mono on body or navigation text.
