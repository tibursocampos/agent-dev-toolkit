# Frontend Core Guidelines

Engineering standards for web frontends. **Visual decisions** (palette, typography, layout, motion) come from `docs/DESIGN-BRIEF.md` and `/impeccable` - not from this file.

## Visual decisions vs engineering

| Source | Covers |
|--------|--------|
| `DESIGN-BRIEF.md` / Impeccable | Colors (OKLCH), typography scale, spacing rhythm, component states, anti-patterns |
| This file | Semantic HTML, SEO, tooling, accessibility basics, stack matching |

For **net-new UI** without a brief, recommend `/impeccable shape` in a new session before implementing.

## Technology stack

1. **Match the project stack** - use the framework, bundler, and styling approach already in the repo.
2. **Core**: HTML for structure; JavaScript/TypeScript for logic.
3. **Styling**: Follow project conventions (vanilla CSS, SCSS, CSS modules, or framework-specific styling). Do not introduce a new styling system unless the task requires it.
4. **Color without a design system**: Prefer OKLCH custom properties; verify contrast (4.5:1 body text, 3:1 large text).

## SEO and semantic HTML

Always implement SEO best practices on every page:

- **Semantic HTML**: Use appropriate HTML5 elements (`<header>`, `<main>`, `<article>`, `<section>`, `<footer>`, `<nav>`).
- **Title tags and meta descriptions**: Each page has accurate, descriptive tags.
- **Heading hierarchy**: One `<h1>` per page; logical `<h2>` / `<h3>` order.
- **Accessibility**: Interactive elements have accessible names; use ARIA only when native semantics are insufficient.

See `html-css-guidelines/semantic-html.md` for markup detail.

## Code formatting

- **Prettier** for JavaScript, TypeScript, CSS, HTML, and JSON.
- **ESLint** (or project linter) for static analysis.
- **Pre-commit hooks** (e.g. Husky) when the project already uses them.

## Lazy-load map

| Task type | Guideline path |
|-----------|----------------|
| Markup / structure | `html-css-guidelines/semantic-html.md` |
| CSS / layout | `html-css-guidelines/css-foundations.md` |
| SCSS projects | `html-css-guidelines/scss-guidelines.md` |
| Tests | `frontend-guidelines/frontend-testing.md` |
| Stack-specific | `react-guidelines/`, `angular-guidelines/`, `vue-guidelines/`, etc. |

---

## AI Stealth Policy

- **Comments:** Minimal and only when strictly necessary. No AI references in HTML, CSS, or JavaScript/TypeScript comments.
- **Identifiers:** No AI-derived names (`aiResult`, `llmOutput`, `generatedContent`, etc.).
- **No AI traces** in any code, markup, or comments. Output must be indistinguishable from work produced without AI assistance.
- See `guardrails.mdc` § 9.
