# Product evidence lite

Rules for **Evidence** fields on FEATURE/STORY/PRD so operators never fabricate facts or paste secrets.

Aligned with SEC verify-if-missing: scorecard must **not** force inventing evidence (RN05).

---

## Core rule

**Omit > fabricate.**

| Situation | Action |
|-----------|--------|
| Real signal available | Path to ticket/doc, redacted quote, or non-PII metric |
| No signal yet | Leave Evidence empty or mark `omitted — none yet` |
| Tempted to invent persona quotes / fake metrics | **Stop** — omit |

---

## Allowed Evidence shapes

- Portable paths to in-repo docs or issue ids (no secrets)
- Redacted snippets (strip tokens, emails, customer names)
- Aggregate metrics without row-level PII

## Forbidden

- Production secrets, connection strings, raw customer data
- Fabricated user quotes or invented incident numbers
- Golden fixtures with real client data (RNF-001)

---

## Scorecard / gate behavior

- Honest omission is **not** a Product-depth failure by itself.
- Missing Problem/Goals is still a hard FEATURE gate failure (separate from Evidence).
- When Evidence is present, prefer path/redacted over narrative dump.

TE04 intent: “Evidence lite: use path/redacted; omit rather than paste secrets.”

---

## Relationship

| Ref | Role |
|-----|------|
| `persona-context.md` | Optional Evidence under Who/Job/Outcome |
| `clarify-depth.md` | Questions that seek real signals without demanding fiction |
| `invest-and-story-quality.md` | Valuable still requires observable progress in AC, not fake Evidence |
| `docs/CREDITS.md` | Curated PM theme links (no corpora dump); Caveman never compresses product drafts |
| `refine-story` scorecard | Honest Evidence omit is OK — do not invent to raise Product depth |
