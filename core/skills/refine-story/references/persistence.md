## Optional save: feature STORY (preferred)

```markdown
# STORY: US01 - [title]
...
```

Use `skills/_shared/templates/features/story/STORY.md`. Place under `features/NNN-slug/USnn/STORY.md`. Optional raw refine dump: `features/NNN-slug/USnn/REFINE/refine.md`.

**Q&A history (REQ-005):** when clarifications ran, also write `features/NNN-slug/USnn/REFINE/qa-history.md` (or `TSnn`) per `references/qa-history.md`. Point the interaction envelope `qa_history_ref` at that **portable** path.

Do **not** create `REFINE/` at repo root.

---

## Optional save: `docs/backlog/<slug>.md` (shortcut)

Prefix file with metadata:

```markdown
# Backlog: [title]

| Field | Value |
|-------|--------|
| **Type** | Bug \| User Story \| Technical Story |
| **Doc language** | content-language (infer from chat; do not hard-code locale) |
| **Refined** | YYYY-MM-DD |
| **Repository** | [folder or remote name] |
| **Preferred promote** | features/NNN-slug/USnn/STORY.md |
| **Q&A history** | docs/backlog/<slug>-qa-history.md |

[generated body]
```

Pair with `docs/backlog/<slug>-qa-history.md` when clarifications exist (same rules as `qa-history.md`).

Do not create `docs/backlog/` in **this toolkit repo** during toolkit porting - only in consumer repos at runtime.

**Paths in metadata / envelopes / handoffs:** portable only (`STORAGE.md` § Portable path / REQ-006 / RNF-002).

---
