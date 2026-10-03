## Approval gates (RN01)

### Mode selection

```text
O2 em `{feature-path}` - {N} histórias.

Modo de execução?

1) série - uma história por vez (spec -> plan -> aprovação)
2) paralelo - Task por história (filho só rascunha PRD/PLAN; Write só no pai após sim); agregação e aprovação no pai
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

Parallel Task cap: **≤4** concurrent story drafts per `SPAWN.md`; wave or prefer série when N>4. If `subagents=none` or Task unavailable → **fallback** série **in-parent** (never hard-fail).

Silence / emoji / “ok” without **sim** is **not** approval.

**sim** does not close an open question and does not replace stop code `open_question`. Render these prompts in the user chat language (`LANGUAGE.md`).

### Observable question and answer lifecycle (REQ-003 / CA3)

Use these states for every blocking operator question:

| State | Observable condition | May dependent work continue? |
|-------|----------------------|------------------------------|
| `presented` | The exact question, choices, and affected scope are in the current conversation. | No |
| `pending` | The prompt was emitted, but no supported answer has been processed. Silence, a queued message, a notification, or an unrelated reply remains pending. | No |
| `answered` | The agent has received and parsed an allowed answer for this question and can name the selected outcome. | Only the branch authorized by that answer |
| `resumed` | After an interruption or new turn, the agent has reloaded the pending gate and confirmed which question is still active before acting. | No, until that gate becomes `answered` |

Record the question id/scope, accepted answer form, and resulting transition in the current turn or persistent workflow artifact where one exists. A host displaying, queuing, retrying, or redelivering a message is not proof that the agent processed it. If the surface cannot expose delivery/processing events, report that boundary and retain `pending` until an answer is actually available to the agent. On resume, repeat the active question or present its current status; never infer approval from prior unrelated text.

Adapters may provide a native prompt, visible approval control, or textual choices. The shared contract requires an explicit response path; it does not claim that toolkit instructions can force a host UI to display, retain, or retract a prompt. Per-surface evidence and retry/redelivery limits are recorded in `adapters/README.md` and the linked adapter README matrices.

---

## Process — Approval answers (RN01)

After drafts exist (or after each story in série), present summary table (id, PRD path, PLAN path, 3 bullets). Ask (pt-BR) — copy in § Approval gates.

Offer **por história** vs **lote** when N > 1.

| Answer | Action |
|--------|--------|
| **sim** (por história) | Set `write_confirmed` as needed per artifact write; write that story's PRD/PLAN; clear `write_confirmed` after; mark story deliver status; continue |
| **sim** (lote) | **One** batch `sim` authorizes Write for **only** the PRD/PLAN paths listed in the approval table. Parent writes that set (serie within parent); set/clear `write_confirmed` around the batch (or per artifact if contracts require). Do **not** reuse a stale `write_confirmed=true` from an earlier story for unlisted paths |
| **ajustar** | Revise named story via sdd-spec/sdd-plan contract; re-ask |
| **cancelar** | Leave drafts; do not emit O3 / develop handoff as approved |
| *(silence)* | **not** approval - wait |
