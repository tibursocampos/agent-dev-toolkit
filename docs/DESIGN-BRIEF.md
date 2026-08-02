# DESIGN-BRIEF — Public docs site (GitHub Pages)

Generated from `/impeccable` shape + confirmed discovery (2026-08-01).  
Visual direction probes: **skipped** (no native image-generation step in this harness).

## 1. Register and product context

- **Register:** `brand`
- **PRODUCT.md:** [../PRODUCT.md](../PRODUCT.md)
- **DESIGN.md:** not yet (optional later via `/impeccable document`)

## 2. Feature summary

Public documentation and marketing site for **agent-dev-toolkit**, deployed with MkDocs Material + custom overrides to GitHub Pages. Serves explorers and operators equally: first viewport sells the toolkit and a sync CTA; secondary navigation reaches skills, adapters, and architecture. **i18n:** English (default) + Brazilian Portuguese for priority pages; workflow via `/developer` + `/i18n-manager` (Option A).

## 3. Component tree / information architecture

```text
Home (landing)                 [en + pt]
 ├─ Get started                [en + pt]  ← INSTALL + guides/01
 ├─ Using skills               [en + pt]  ← SKILLS + guides/02 + decision tree
 ├─ Adapters                   [en first; pt stub OK in v1]
 ├─ Architecture               [en first; pt stub OK in v1]
 └─ Maintainers                [en]       ← VALIDATION, governance, CONTRIBUTING
```

**Home regions (one composition, not a dashboard):**

1. Brand mark / name (hero-level)
2. One headline + one supporting sentence
3. CTA group (Get started / copy sync command)
4. Dominant visual: core → adapters → agents diagram (SVG)
5. Agent switcher (8 Tier-1 ids → typical live root + one-line note)
6. Secondary link row into Skills / Adapters (below first viewport)

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
| `--accent` | `oklch(0.78 0.14 195)` | Teal commit — links, CTA, switcher active |
| `--accent-dim` | `oklch(0.45 0.08 195)` | Borders / focus rings |
| `--danger` | `oklch(0.65 0.18 25)` | Rare warnings only |

**Typography**

| Role | Family | Notes |
|------|--------|--------|
| Display | **Sora** | Brand + home headline |
| Body | **Atkinson Hyperlegible** | Docs readability / a11y |
| Code | **JetBrains Mono** | Fenced blocks / commands only |

Modular scale ~1.25; fluid display via `clamp()`; display letter-spacing ≥ `-0.04em`. Body measure ≤65–75ch.

**Spacing:** generous section gaps on home; tighter rhythm inside doc articles (Material content width).

**Motion:** 2–3 intentional load reveals (brand, diagram, switcher); ease-out-quart/expo; **no** bounce/elastic; all gated by `prefers-reduced-motion`.

## 5. State map

| Control | States |
|---------|--------|
| Primary CTA | default, hover, focus, active, disabled |
| Copy command | default, hover, focus, active, success (“Copied”), error (clipboard denied) |
| Agent switcher tabs/chips | default, hover, focus, active (selected), disabled (n/a) |
| Language switcher | default, hover, focus, active (current locale) |
| Nav / search | Material defaults; ensure visible focus |
| Decision tree (skills) | default, hover, focus; empty N/A |

## 6. Accessibility checklist

- [ ] Skip link to main content
- [ ] Focus order: skip → lang → nav → main → switcher → CTA
- [ ] Contrast AA on accent-on-dark and text-on-surface
- [ ] Agent switcher is a tablist or radiogroup with `aria-selected` / accessible name per agent
- [ ] Copy button announces success via live region
- [ ] `prefers-reduced-motion: reduce` disables entrance motion
- [ ] Language switcher: clear current language; `hreflang` / alternate links where plugin supports

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

## 8. Target stack

`html-css` (MkDocs Material + custom overrides; light JS for switcher/copy if needed)

Also: Python/`mkdocs` build, `mkdocs-static-i18n` (or current Material-compatible i18n plugin), GitHub Actions → Pages.

## 9. Implementation notes

| Area | Note |
|------|------|
| Content root | Prefer `docs-site/` **or** a clear MkDocs `docs_dir` that does **not** publish `documentation-plan/` |
| Source reuse | Symlink/copy curated markdown from existing `docs/` + thin home page; avoid duplicating forever without a sync story |
| i18n (Option A) | `/developer` + `/i18n-manager`: EN canonical; PT for Home, Get started, Using skills in v1; theme/nav strings in locale catalogs |
| Locale codes | `en`, `pt` (pt-BR copy) |
| CI | `.github/workflows/docs.yml` — build on push; deploy Pages artifact |
| About URL | After go-live: `https://tibursocampos.github.io/agent-dev-toolkit/` |
| Anchors | Linear docs (clarity), Fly.io docs (energy), ops sync manual (command → result) |
| Imagery | Primary visual = custom SVG diagram (not stock photo hero); optional later OG image |

**Named anchors:** Linear documentation clarity; Fly.io docs energy; night ops desk mood (not Liquid Death / not Stripe purple).

## 10. Implementation scope (one session)

**Next session deliverable (Fases 1–2 skeleton + home):**

1. Add MkDocs Material project config (`mkdocs.yml`, requirements, overrides/CSS tokens).
2. Wire GitHub Actions → Pages (EN site builds green).
3. Ship dark home: brand, headline, CTA, SVG diagram, agent switcher, 2–3 motions + reduced-motion.
4. Nav stubs for Get started / Using skills / Adapters / Architecture / Maintainers (can point at migrated EN markdown).
5. Scaffold i18n plugin + `pt` stubs for the three priority pages (content can be draft).

**Acceptance**

- [ ] `mkdocs build` succeeds locally and in CI
- [ ] Pages URL serves home in dark committed theme (not stock purple)
- [ ] Agent switcher updates install-root hint for all 8 Tier-1 agents
- [ ] Language switcher present; `en` + `pt` routes resolve for home
- [ ] No secrets; no `documentation-plan` in the published site

**Handoff:** new conversation → `/developer` (or `/javascript-developer` for switcher JS) implementing this brief; use `/i18n-manager` when extracting UI/nav/home strings into locale files.
