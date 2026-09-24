# Q&A history (persistible + consultable)

**REQ-005 / CA2.** Clarification Q&A during refine is an append-only history the operator (and later O1/O2) can **consult**. Prefer file persistence under the story; chat-only is allowed until first save — then migrate.

## Canonical location (portable)

| Preference | Path |
|------------|------|
| **1 (preferred)** | `features/NNN-slug/USnn/REFINE/qa-history.md` (or `TSnn`) |
| **2** | Section `## Q&A history` inside `STORY.md` when REFINE/ not used |
| **3 (shortcut)** | `docs/backlog/<slug>-qa-history.md` beside shortcut backlog file |

Do **not** create `REFINE/` or `qa-history.md` at repo root. Paths in links/handoffs stay **portable** (REQ-006 / RNF-002).

## File shape

```markdown
# Q&A history — <story title or slug>

| Field | Value |
|-------|--------|
| **Mode** | feature \| tech \| split |
| **Item type** | Bug \| User Story \| Technical Story |
| **Story** | features/NNN-slug/USnn/STORY.md |
| **Updated** | YYYY-MM-DD |

## Entries

### 2026-09-24T12:00Z — Q1
- **Severity:** B
- **Question:** <sharp question>
- **Answer:** <operator answer or "(open)">
- **Status:** open \| answered

### 2026-09-24T12:10Z — Q2
- **Severity:** I
- **Question:** …
- **Answer:** …
- **Status:** answered
```

## Flow rules

1. When asking a clarification question, **append** an entry (`Status: open`) before waiting.
2. When the operator answers, update that entry (`answered`) — do not delete prior text.
3. Recompute envelope `status` from open **B**/**I** only (`readiness-severity.md`).
4. Envelope `qa_history_ref` / `portable_paths.qa_history` must point at the portable history path once persisted.
5. On handoff to `/sdd-spec`, `/orchestrate-analyze`, or `/split-story-checklist`, cite the history path in the typed handoff — do not paste the full history into the slash command (`SR-NO-FULL-DUMP`).

## Consultability checklist

- [ ] History path is portable and listed in the interaction envelope
- [ ] Open B/I in history match envelope `open_questions`
- [ ] Answered entries retain question + answer (audit trail)
- [ ] No OS absolute paths inside the history file

## Related

| Topic | Path |
|-------|------|
| Envelope | `references/interaction-envelope.md` |
| Persistence | `references/persistence.md` |
| Severity / READY | `readiness-severity.md` |
