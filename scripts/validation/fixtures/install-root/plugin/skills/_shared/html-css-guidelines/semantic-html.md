# Semantic HTML

Markup standards for accessible, SEO-friendly pages. Visual styling follows `DESIGN-BRIEF.md`; this file covers structure only.

## Document structure

- Declare `<!DOCTYPE html>` and `lang` on `<html>`.
- Use landmarks: `<header>`, `<nav>`, `<main>`, `<aside>`, `<footer>`.
- One `<main>` per page; skip links for keyboard users when layouts are complex.

## Heading hierarchy

- Single `<h1>` per page (page title or primary topic).
- Do not skip levels (`h1` -> `h3` without `h2`).
- Headings describe content structure, not visual size (use CSS for appearance).

## Forms and labels

- Every input has an associated `<label>` (`for` / `id` or wrapping label).
- Group related fields with `<fieldset>` and `<legend>` when appropriate.
- Use correct `type`, `autocomplete`, and `required` attributes.
- Error messages link to fields via `aria-describedby`.

## Links and buttons

- `<a href>` for navigation; `<button type="button|submit|reset">` for actions.
- Do not use `<div onclick>` for interactive controls.
- Link text must be meaningful out of context (avoid "click here").

## Images and media

- Meaningful images: descriptive `alt` text.
- Decorative images: `alt=""`.
- `<video>` / `<audio>`: provide captions or transcripts when content is informational.

## SEO meta

- Unique `<title>` and `<meta name="description">` per route.
- Open Graph / Twitter cards when the project already uses them.
- Canonical URL when duplicate content exists.

## Lists and tables

- Use `<ul>` / `<ol>` for lists; `<table>` only for tabular data with `<thead>`, `<tbody>`, and `<th scope>`.
