# DESIGN-BRIEF — Public docs site reading pass

Confirmed in chat on 2026-09-25. Replaces the earlier home brief that put a copy-command CTA and a ten-agent switcher in the first viewport.

**Register:** brand. **PRODUCT.md:** [../PRODUCT.md](../PRODUCT.md). **DESIGN.md:** not present. Upstream Impeccable `DESIGN.md` is their example product, not this site.

**Locales:** English (`index.md` and unsuffixed pages) is the default. Brazilian Portuguese is the `*.pt.md` translation of the same pages. Same facts, commands, ids, and flags.

## 2. Feature summary

The public MkDocs site explains agent-dev-toolkit and gets a visitor to install. This pass puts the architecture figure back on the home, puts a simple bootstrap download on Get started, and tightens chrome so the site reads as documentation. It does not reorganize the page map.

Explorers need to see what the toolkit is, then where it goes, then how to install. Operators need the same install control without a wall of `curl`.

## 3. Information architecture (this pass)

Home, both locales:

1. The two sentences that already define the toolkit.
2. The architecture figure: `docs-site/assets/core-adapters-diagram.svg` and `docs-site/assets/core-adapters-diagram.pt.svg`.
3. Install stays a short point to Get started. Do not explain each publish script on the home.

Get started, both locales:

- One plain table: operating system, file, download.
- Files: `bootstrap.bat`, `bootstrap.ps1`, `bootstrap.sh`.
- The control is the download. Do not print the long `curl` next to it, and do not add a copy button beside a command that is already on screen. One sentence says what the entrypoint does: it downloads the zip, checks SHA256, and opens the CLI.

Out of this pass: nav rewrite, a site index page, a dedicated CLI page, moving "Ten agents" off the home, moving language off the home, Mermaid for ASCII trees, Credits layout. The architecture image is not replaced by Mermaid.

## 4. Design tokens

**Color strategy:** Committed. Keep the existing dark teal. Scene: a night desk, a manual, not a neon stage.

| Role | OKLCH |
|------|--------|
| `--bg` | `oklch(0.16 0.02 250)` |
| `--surface` | `oklch(0.22 0.025 250)` |
| `--text` | `oklch(0.93 0.01 250)` |
| `--muted` | `oklch(0.70 0.02 250)` |
| `--accent` | `oklch(0.78 0.14 195)` |
| `--accent-dim` | `oklch(0.45 0.08 195)` |
| `--on-accent` | `oklch(0.18 0.035 250)` |
| `--danger` | `oklch(0.65 0.18 25)` |

**Type.** Material's 125% root (20px) goes away. Set `html` to 100% so `1rem` is 16px.

| Role | Family | Size | Weight |
|------|--------|------|--------|
| Body | Atkinson Hyperlegible | 15px | 400 |
| Code, `pre`, `kbd` | JetBrains Mono | 12.5px | 400 |
| Left nav and right TOC | Atkinson Hyperlegible | 13px, both the same | 400; the active item is accent and 600 |
| Headings | Sora | keep the current steps, under the new root | 600 |

Nav and TOC use a line-height around 1.35 and less padding than the article. OpenCode Go's docs are 14px IBM Plex Mono on a 16px root ([opencode.ai/docs/go](https://opencode.ai/docs/go/)). This site takes that size relationship, not the mono body. Mono stays on code.

Tables follow a plain Bootstrap table: readable, no card chrome, horizontal scroll on a narrow viewport that does not clip the cell.

## 4b. Signature motif

The architecture diagram (core, adapters, agent homes). Spend the visual weight there. Do not add a second hero, a metric strip, or a cluster of large buttons.

## 4c. UX voice

Controls name the file they download. One sentence of outcome next to the table. No copy-paste control beside a visible command.

## 5. State map

| Control | States |
|---------|--------|
| Download | default, hover, focus, active |
| Nav item | default, active |
| Code block | the Material copy button may stay on fenced examples that are not a download |

## 6. Accessibility checklist

- [ ] Skip link still reaches main content (one skip link, not two).
- [ ] Download controls are keyboard reachable, named, and at least 44px on touch if they are the primary control.
- [ ] Contrast stays WCAG 2.2 AA: 4.5:1 body, 3:1 large text. Filled accent uses `--on-accent`.
- [ ] The architecture image has alt text that states core, adapters, and agent homes, in the page language.
- [ ] `prefers-reduced-motion: reduce` keeps the existing reveal gate.

## 7. Anti-patterns explicitly avoided

- Default Material purple.
- Large poorly grouped download buttons from the previous home.
- A copy button next to a command that is already visible.
- IBM Plex Mono (or any mono) on body and nav.
- Glass, gradient text, metric cards, eyebrows on every section.
- Restoring a Caveman page or treating Orchestrated Delivery, Classic SDD, and refine-story as three equal products.

## 8. Target stack

`html-css` (MkDocs Material, `docs-site/`, i18n `docs_structure: suffix`).

## 9. Implementation notes

Edit `docs-site/stylesheets/extra.css`, `docs-site/overrides/`, `docs-site/javascripts/agent-switcher.js` only if the download or figure needs it, and the minimum of `index.md`, `index.pt.md`, `get-started.md`, and `get-started.pt.md` so the figure and the download return.

Do not edit `core/`, `adapters/`, `scripts/`, or `memory-bank/` for this pass. Do not reorganize `mkdocs.yml` nav here.

## 10. Implementation scope (one session)

Next session is `/javascript-developer` on the HTML/CSS fallback. Load only `frontend-practices.md`, `semantic-html.md`, `css-foundations.md`, `modern-css.md`, `accessibility-basics.md`, and `checklist.md`.

Acceptance:

- [ ] Home shows the architecture SVG in both locales.
- [ ] Get started offers one download control per bootstrap file, in both locales, without the long `curl` and without a copy button beside it.
- [ ] Body is 15px Atkinson. Code, pre, and kbd are 12.5px JetBrains Mono. Left nav and TOC are both 13px Atkinson.
- [ ] Checked in the browser, desktop and phone width, English and Portuguese: home, get started, one page with a table, one page with a code block. Local server `http://127.0.0.1:8000/agent-dev-toolkit/`.

**Handoff:** new conversation with `/javascript-developer`. Do not implement the CSS in the session that only writes this brief.
