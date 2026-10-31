## Approval gates

### Mode selection

```text
O2 em `{feature-path}` - {N} histórias.

Modo de execução?

1) série - uma história por vez (spec -> plan -> aprovação)
2) paralelo - Agent por história (filho só rascunha PRD/PLAN; Write só no pai após sim); agregação e aprovação no pai
3) cancelar
```

### PRD/PLAN approval

```text
PRD/PLAN O2 prontos para aprovação.

Escopo: (por história | lote completo)

Posso marcar como aprovados?
(sim / ajustar / cancelar)
```

| Scope | When |
|-------|------|
| **Por história** | User wants tight control; série default after each story |
| **Lote** | N > 1 and user chose batch after parallel (or after all série drafts). One **sim** authorizes **only** paths listed in the approval table; clear/reset `write_confirmed` after the batch (do not reuse stale gate for unlisted paths) |

Parallel Agent cap: **≤4** concurrent story drafts per `SPAWN.md`; wave or prefer série when N>4. If `subagents=none` or Agent unavailable → **fallback** série **in-parent** (never hard-fail).

Silence / emoji / “ok” without **sim** is **not** approval.

**sim** does not close an open question and does not replace stop code `open_question`. Render these prompts in the user chat language (`LANGUAGE.md`).

In série mode, once this story's named approval scope is satisfied and its checkpoint is reconciled, continue to the next eligible story without a separate “continue?” prompt. This does not pre-approve that story: present and honor its own required write and content-approval gates when due. If the current answer is pending, `ajustar`, or `cancelar`, do not advance dependent work; follow the table above. Batch approval authorizes only the paths explicitly listed in its approval table.

### Observable question and answer lifecycle

The states for every blocking operator question (`presented`, `pending`, `answered`, `resumed`), the order rule, and the answer-to-id mapping are defined once in `{{TOOLKIT_ROOT}}/skills/_shared/agents/QUESTIONS.md`. Per-surface evidence and retry/redelivery limits are recorded in `adapters/README.md`.

---

## Process — Approval answers

After drafts exist (or after each story in série), present summary table (id, PRD path, PLAN path, 3 bullets). Ask in the user chat language — copy in § Approval gates.

The per-story approval table is governed by `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/LIVE-STAGE-TABLE.md` (O2 caller section): columns `gate`, `status`, `owner`, `evidence`, one row per story with the story ID in the gate cell, state keys and ASCII glyphs from that file, labels in the user chat language. You must redraw the full table at each gate and again after each answer (`sim` / `ajustar` / `cancelar`); always show every story row, never a summary or only the changed row.

Offer **por história** vs **lote** when N > 1.

| Answer | Action |
|--------|--------|
| **sim** (por história) | Set `write_confirmed` as needed per artifact write; write that story's PRD/PLAN; clear `write_confirmed` after; mark story deliver status; continue |
| **sim** (lote) | **One** batch `sim` authorizes Write for **only** the PRD/PLAN paths listed in the approval table. Parent writes that set (serie within parent); set/clear `write_confirmed` around the batch (or per artifact if contracts require). Do **not** reuse a stale `write_confirmed=true` from an earlier story for unlisted paths |
| **ajustar** | Revise named story via sdd-spec/sdd-plan contract; re-ask |
| **cancelar** | Leave drafts; do not emit O3 / develop handoff as approved |
| *(silence)* | **not** approval - wait |
