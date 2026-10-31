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
- **Decision ID:** <stable decision ID or "(pending)">
- **Resolution:** <decision taken, or "(pending)">
- **Impact:** <portable artifact path>#<section>; REQ-...; CA-... (omit requirement/criterion IDs when not applicable)
- **Status:** open \| answered (legacy) \| resolved \| superseded
- **Supersedes:** <prior question/decision ID, or "(none)">
- **Superseded by:** <new question/decision ID, or "(none)">

### 2026-09-24T12:10Z — Q2
- **Severity:** I
- **Question:** …
- **Answer:** …
- **Decision ID:** D-002
- **Resolution:** …
- **Impact:** features/NNN-slug/USnn/STORY.md#Acceptance criteria; REQ-003; CA2
- **Status:** resolved
- **Supersedes:** (none)
- **Superseded by:** (none)
```

`Question ID` is the entry heading. Keep existing IDs unchanged; otherwise allocate the next unused stable `Q-...` and `D-...` IDs. A resolved question links to exactly the decision that resolves it. Record the affected artifact and section using portable paths, plus REQ/CA identifiers when applicable. Keep the operator's answer and the resulting resolution as separate fields. An open question has no decision or impact yet. `answered` is accepted for older entries that predate this traceability shape; when enriching one, preserve its answer and set `resolved` only once a decision and impact are recorded. An answered entry without those links remains open for readiness. When a decision is replaced, retain the old entry as `superseded`, link both entries through `Supersedes` / `Superseded by`, and record the replacement as a new entry; do not rewrite or remove the prior answer, resolution, or impact.

## Flow rules

1. When asking a clarification question, **append** an entry (`Status: open`) before waiting.
2. When the operator answers, update that entry with the answer, stable decision ID, resolution, and impact (`resolved`) — do not delete prior text. If the answer does not resolve the question, retain `open` and leave decision/impact pending.
3. Refresh envelope `status` per `readiness-severity.md` (single source of truth for READY / NEEDS_CLARIFICATION).
4. Envelope `qa_history_ref` / `portable_paths.qa_history` must point at the portable history path once persisted.
5. On handoff to `/sdd-spec`, `/orchestrate-analyze`, or `/split-story-checklist`, cite the history path in the typed handoff — do not paste the full history into the slash command (`SR-NO-FULL-DUMP`).

## Consultability checklist

- [ ] History path is portable and listed in the interaction envelope
- [ ] Unanswered B, I, and MINOR questions in history match envelope `open_questions` and `minor_questions`
- [ ] Resolved entries link question ID → decision ID → affected artifact/section and applicable REQ/CA
- [ ] Resolved and superseded entries retain question, answer, resolution, status, and supersession links (audit trail)
- [ ] No OS absolute paths inside the history file

## Related

| Topic | Path |
|-------|------|
| Envelope | `references/interaction-envelope.md` |
| Persistence | `references/persistence.md` |
| Severity / READY | `readiness-severity.md` |
