## Architecture confirm gate (greenfield / `needs_domain`)

**When:** nature `greenfield` **or** `needs_domain=true` **and** no established in-repo / approved ARCH style.

**Flow (post-architect, before treating style as selected):**

```text
ARCH draft (4 sections) → operator sim / ajustar / cancelar → ARCH approved
```

| Step | Rule |
|------|------|
| Draft | Architect proposes via `architecture-selection` + `prompts/architect.md`; optional scaffold `templates/features/story/ARCH/architecture-decision.md` |
| Confirm | Parent asks pt-BR (SKILL §7b). Silence ≠ approval. Receipt stays `needs-confirm.` until **sim** |
| Approved | Persist final ARCH with style id; CONTINUITY notes decision; **point-promote** `memory-bank/architecture.md` (if not already) so it is not left draft / `needs-confirm`; Memory-bank status `refreshed`; implementers load **one** `principles/architecture/<style>.md` + matching stack overlay C |
| Brownfield | Skip **style re-pick / style-id confirm gate** only. Still spawn `architect` and `database` (when persistence is in scope) and write mirror ARCH (layers, DDL, EF vs Dapper or equivalent, pipeline). ARCH is **not** optional when `needs_domain` or brownfield. |

**Must not:** silent vertical-slice (or any) default; final ARCH before **sim**; glob all architecture overlays in O1.

Copy (pt-BR) — see SKILL §7b.

---

## Process — Architecture confirm answers

When nature is **`greenfield`** **or** `needs_domain=true` **and** no established in-repo / approved ARCH style:

1. Architect returns an ARCH **draft** only (four sections per `prompts/architect.md`; may use `templates/features/story/ARCH/architecture-decision.md`).
2. Parent presents the draft and asks (pt-BR) — copy in § Approval gate copy.
3. Act on the answer:

| Answer | Action |
|--------|--------|
| **sim** | Persist ARCH **approved**; record style id in CONTINUITY; **point-promote** / update `memory-bank/architecture.md` (if not already) so it is not left draft / `needs-confirm`; set Memory-bank status `refreshed`; continue synthesize |
| **ajustar** | Revise proposal with architect (or in-parent); re-present; ask again |
| **cancelar** | Leave draft; do **not** treat style as selected |
| *(silence / other)* | **not** approval — keep `needs-confirm.`; wait |

4. **Until sim:** do not write final ARCH; do not invent a silent default style (including vertical-slice). Brownfield with an established style: **skip this confirm gate** (style re-pick / style-id only) — still spawn `architect` and `database` (when persistence is in scope) and write a **mirror** ARCH slice (layers, DDL, EF vs Dapper or equivalent, pipeline). Do **not** skip ARCH because a style already exists.

See also § Architecture confirm gate.

---

## Approval gate copy (pt-BR)

### Backlog (RN01)

```text
Backlog O1 pronto em `{feature-path}`.

Posso marcar como aprovado e seguir para O2?
(sim / ajustar / cancelar)
```

RN01: silence / emoji / “ok” without **sim** is **not** approval.

### Architecture confirm (greenfield / `needs_domain`)

```text
Rascunho ARCH (estilo proposto) em `{story-arch-path}`.

Posso gravar o ARCH aprovado com este estilo?
(sim / ajustar / cancelar)
```

Same rule: silence is **not** approval; keep `needs-confirm.` until **sim**.
