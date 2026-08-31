## Step selection rules

1. Sort steps in plan order (STEP 1, PASSO 1, etc.).
2. Skip steps marked Completed / Concluído.
3. Respect **Deps:** - dependent steps stay blocked until deps are done.
4. One step per `document-implement` session unless the user explicitly requests batching and context is low.

---
