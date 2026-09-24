## Step selection rules

1. Sort steps in plan order (STEP 1, PASSO 1, etc.).
2. Skip steps marked Completed / Concluído.
3. Respect **Deps:** - dependent steps stay blocked until deps are done.
4. Default: **one plan step** per `document-implement` session.
5. **Kind: update** — one step may refresh **multiple existing** doc paths in the same session (that is the point of coalesced updates).
6. **Kind: new** — one step = one new deliverable file (do not batch unrelated new domains unless the user explicitly requests it and context is low).
7. Batching multiple **new** steps in one session only when the user explicitly asks and context is low.

---
