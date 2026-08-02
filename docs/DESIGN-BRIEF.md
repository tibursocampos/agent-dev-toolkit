# DESIGN-BRIEF — Public docs site (GitHub Pages)

Generated from `/impeccable` shape (2026-08-01) + **critique deltas confirmed** (2026-08-02).  
Critique baseline: **26/40** (Acceptable) — dual-agent home + agent switcher.  
Visual direction probes: **skipped** (no native image-generation step in this harness).

**Confirmed decisions (critique Ask the User):**

| # | Decision |
|---|----------|
| Priority | All feasible issues from the critique (P1 + P2) |
| Switcher | **Default agent + “Other agents”** progressive disclosure (not 8 equal chips) |
| Scope | Full remediation of home + switcher findings |

## 1. Register and product context

- **Register:** `brand`
- **PRODUCT.md:** [../PRODUCT.md](../PRODUCT.md)
- **DESIGN.md:** not yet (optional later via `/impeccable document`)

## 2. Feature summary

Public documentation and marketing site for **agent-dev-toolkit**, deployed with MkDocs Material + custom overrides to GitHub Pages. Serves explorers and operators equally: first viewport sells the toolkit and a **correct** sync CTA after agent intent is clear; secondary navigation reaches skills, adapters, and architecture. **i18n:** English (default) + Brazilian Portuguese for priority pages; workflow via `/developer` + `/i18n-manager` (Option A).

## 3. Component tree / information architecture

```text
Home (landing)                 [en + pt]
 ├─ Get started                [en + pt]  ← INSTALL + guides/01
 ├─ Using skills               [en + pt]  ← SKILLS + guides/02 + decision tree
 ├─ Adapters                   [en + pt]  ← SITE-HARDEN trilha A
 ├─ Architecture               [en + pt]  ← site summary + GitHub deep links
 └─ Maintainers                [en + pt]  ← VALIDATION, governance, CONTRIBUTING
```

**Home regions (one composition, not a dashboard) — revised order:**

1. Brand mark / name (hero-level) — `.home-brand`
2. One headline + one supporting sentence — `.home-headline` / `.home-lead`
3. Dominant visual: core → adapters → agents diagram (SVG) — `.home-diagram`
4. Agent switcher — **recommended default visible** + disclosure **“Other agents”** (remaining Tier-1) → live-root hint
5. CTA group — **Copy sync command primary**; Get started secondary (text/outline)
6. Optional one-line safe-default note (fixture-first / live home + `-AllowUserHome` is explicit) near copy
7. Secondary link row into Skills / Adapters (below first viewport)

**Agent switcher UX (confirmed):**

- Default selection: `cursor` (or last explicit choice in-session if already chosen).
- Collapsed: show **one** selected control + short “Change agent” / “Other agents” control (≤4 visible choices at once when expanded grouping is used).
- Expanded “Other agents”: remaining Tier-1 ids as radiogroup options (still all 8 reachable; not all equal in the first paint).
- On change: update `#sync-command` to `… -Agent <id>` **and** `#agent-install-hint` (live region).
- No-JS fallback: server-rendered command **must** include `-Agent` for the default agent (never ship bare `toolkit.ps1` as the only copy target).

**Chrome:** Material top nav + search + language switcher; footer with license + repo link.

**Out of site build:** `docs/documentation-plan/` (gitignored local plan).

## 4. Design tokens

**Color strategy:** Committed (dark).  
**Scene sentence:** An operator at a quiet night desk, dark UI, cool ambient light, calm confidence — terminal nearby, not a neon cyberpunk stage.

| Role | OKLCH (target) | Notes |
|------|----------------|--------|
| `--bg` | `oklch(0.16 0.02 250)` | Page background |
| `--surface` | `oklch(0.22 0.025 250)` | Panels / code wells |
| `--text` | `oklch(0.93 0.01 250)` | Body |
| `--muted` | `oklch(0.70 0.02 250)` | Secondary |
| `--accent` | `oklch(0.78 0.14 195)` | Teal commit — links, switcher active, outline CTA |
| `--accent-dim` | `oklch(0.45 0.08 195)` | Borders / focus rings |
| `--on-accent` | **new** — dark ink on filled primary (AA ≥4.5:1 vs `--accent`) | Primary button text/icon — fix detector `low-contrast` on filled CTA |
| `--danger` | `oklch(0.65 0.18 25)` | Rare warnings only |

**Typography**

| Role | Family | Notes |
|------|--------|--------|
| Display | **Sora** | Brand + home headline; prefer in SVG labels when feasible |
| Body | **Atkinson Hyperlegible** | Docs readability / a11y |
| Code | **JetBrains Mono** | Fenced blocks / commands / install hint |

Modular scale ~1.25; fluid display via `clamp()`; display letter-spacing ≥ `-0.04em`. Body measure ≤65–75ch.

**Spacing:** generous section gaps on home; tighter rhythm inside doc articles (Material content width).

**Motion:** 2–3 intentional load reveals (brand, diagram, switcher); ease-out-quart/expo; **no** bounce/elastic; all gated by `prefers-reduced-motion`. **EN/PT parity:** same `.reveal` / `.reveal--*` classes on both homes.

## 5. State map

| Control | States |
|---------|--------|
| Primary CTA (Copy) | default, hover, focus, active, disabled, success (“Copied”), error (“Clipboard denied” + recovery hint) |
| Secondary CTA (Get started) | default, hover, focus, active, disabled |
| Agent default chip | default, hover, focus, active (selected) |
| Other agents disclosure | collapsed, expanded, focus |
| Other-agent options | default, hover, focus, active (selected) |
| Language switcher | default, hover, focus, active (current locale) |
| Nav / search | Material defaults; ensure visible focus |
| Decision tree (skills) | default, hover, focus; empty N/A |

## 6. Accessibility checklist

- [x] Skip link to main content (verify still present after chrome tweaks)
- [ ] Focus order: skip → lang → nav → main → **diagram → switcher → copy CTA → Get started** → secondary links
- [ ] Contrast AA: body 4.5:1; large 3:1; **filled primary uses `--on-accent` on `--accent`** (no light-on-teal fail)
- [ ] Agent switcher remains a radiogroup (or equivalent) with accessible name; disclosure button has `aria-expanded`
- [ ] Copy success/error announced via live region; error offers select-all / manual copy path
- [ ] `prefers-reduced-motion: reduce` disables entrance motion (EN + PT)
- [ ] Language switcher: clear current language; `hreflang` / alternate links where plugin supports
- [ ] PT draft notice uses real Material admonition HTML (never raw `!!! warning` in published Pages)

## 7. Anti-patterns explicitly avoided

- Material default purple/pink palette without override
- Glassmorphism, gradient text, glow stacks as default
- Hero metric / identical card grids / eyebrow-on-every-section
- Numbered 01/02/03 section scaffolding
- Cream/sand body backgrounds; light “AI SaaS” cliché
- Inter / Space Grotesk / IBM Plex / Fraunces / etc. (Impeccable reflex-reject)
- Cards as lazy containers on the home hero
- Per-agent “SDD runtime” footnotes or phantom capability flags in copy
- Shipping untranslated PT pages that silently fall back without a stub notice
- **Wall of 8 equal agent chips in first paint** (use default + Others)
- **CSS/markup class contract drift** (`.home-cta__primary` unused; `__hint` vs `__note`)
- Peer-weight dual CTAs that compete before agent intent is clear
- SVG hardcoded hex / system-ui labels that ignore brand tokens when avoidable
- Raw MkDocs admonition syntax leaking to the published PT home

## 8. Target stack

`html-css` (MkDocs Material + custom overrides; light JS for switcher/copy if needed)

Also: Python/`mkdocs` build, Material i18n plugin (`docs_structure: suffix`), GitHub Actions → Pages.

## 9. Implementation notes

| Area | Note |
|------|------|
| Content root | `docs-site/` via `mkdocs.yml` `docs_dir`; do **not** publish `documentation-plan/` |
| Class contract | Markup **must** use the CSS API: `.home-cta__primary` (or map Material classes explicitly in CSS — pick one system, no orphans). Prefer: `.agent-switcher__hint` **styled** (alias or rename `__note` → `__hint`). Style `.home-cta__status` and `.agent-switcher__label`. |
| Switcher JS | Keep `agent-switcher.js`; extend for disclosure + ensure initial HTML command includes default `-Agent`. Copy recovery on clipboard deny. |
| Diagram | Align stroke/label color to tokens (`currentColor` / CSS vars); name parity with chips (“Grok Build”, “GitHub Copilot”). Prefer display/body fonts in SVG text when practical. |
| i18n (Option A) | EN canonical; PT for Home, Get started, Using skills; fix PT home admonition rendering; match reveal classes |
| Locale codes | `en`, `pt` (pt-BR copy) |
| CI | `.github/workflows/docs.yml` |
| Live URL | https://tibursocampos.github.io/agent-dev-toolkit/ |
| Critique archive | Skill `critique-storage.mjs` / `detect.mjs` not bundled in this harness; re-run `/impeccable critique` after polish |

**Named anchors:** Linear documentation clarity; Fly.io docs energy; night ops desk mood (not Liquid Death / not Stripe purple).

## 10. Implementation scope (one session)

**Next session deliverable — home + switcher polish (critique remediation):**

1. **Align class contract** — wire markup ↔ `extra.css` (primary/copy/hint/status/label); stop styling wrappers as buttons accidentally.
2. **Reorder home** — diagram → switcher → CTA; Copy primary, Get started secondary.
3. **Switcher: default + Other agents** — collapse Tier-1 inventory; all 8 still selectable; update command + hint; no-JS default includes `-Agent`.
4. **Contrast + SVG** — introduce `--on-accent`; fix filled CTA; token-align diagram; name parity.
5. **PT parity** — real admonition (or styled notice), reveal classes, same IA/order as EN.
6. **Copy error recovery** — live region + select/manual hint; optional fixture-first one-liner near CTA.
7. **Re-critique optional** — `/impeccable critique` on home after ship to lift score from 26/40.

**Acceptance**

- [ ] First paint shows ≤1 recommended agent + disclosure (not 8 equal chips)
- [ ] Focus/visual order: brand → copy path after agent intent; Copy is the primary home action
- [ ] Static HTML default sync command includes `-Agent <default>`
- [ ] Selecting any Tier-1 agent updates command + install hint (EN + PT)
- [ ] `.home-cta__*` / `.agent-switcher__hint` (or single renamed API) apply as designed; no dead classes for live controls
- [ ] Filled primary CTA meets WCAG AA for text-on-accent
- [ ] PT home: no raw `!!! warning`; reveal parity with EN
- [ ] Clipboard deny offers a recoverable next step
- [ ] `mkdocs build` green; Pages reflects changes; no secrets / no `documentation-plan`

**Handoff:** new conversation → `/javascript-developer` (switcher + copy) and/or `/developer` for MkDocs/CSS/i18n. Use `/i18n-manager` when extracting new UI strings (Other agents, recovery copy, safe-default note).
)
