# ARCH: Architecture decision (draft → approved)

| Campo | Valor |
|-------|--------|
| **Story** | USnn / TSnn |
| **Status** | `draft` \| `approved` |
| **Nature** | greenfield \| brownfield \| operational |
| **Style id** | *(fill after confirm — e.g. concentric-dependency \| vertical-slice \| ddd-tactical \| event-driven)* |
| **Updated** | YYYY-MM-DD |

> **Gate:** On greenfield / `needs_domain` without an established style, keep **Status=`draft`** and do **not** treat style as selected until the operator answers **sim**. Until then: `needs-confirm.` Brownfield: mirror the repo; do not re-pick.

## 1. Proposed boundaries

<!-- Layers / modules / ownership edges (names only). -->

-

## 2. Recommendation

<!-- One primary style id + short rationale. Point to principles B + stack overlay C after approve. -->

- **Style:**
- **Why:**
- **B (WHAT):** `code-guidelines/principles/architecture/<style>.md` (load **one** only)
- **C (HOW):** matching thin overlay under `*-guidelines/` (lazy-load at implement; no architecture glob)

## 3. Alternatives considered

<!-- Max 2. -->

1.
2.

## 4. Open questions

<!-- Max 5. -->

1.
2.
3.
4.
5.

## Confirm log

| When | Answer | Note |
|------|--------|------|
| | sim / ajustar / cancelar | |
