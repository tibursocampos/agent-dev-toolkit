## Present static catalog

### Caveman Mode
**NEVER** — This skill ignores `caveman_mode`. Present the catalog in clear prose (pt-BR for the user). Do not load `CAVEMAN.md` for chat compression.

### 0. No mutating gates

This skill is **read-only**. Do **not** require guardrails/SESSION/`sim` to show the catalog. Do not invent skill names.

### 1. Read static files (required)

1. **Read** `CATALOG.md` at `{{TOOLKIT_ROOT}}/skills/_shared/skills-catalog/CATALOG.md` (fallback: `_shared/skills-catalog/CATALOG.md`).
2. **Read** `OPERATOR.md` when the user asks about confirmations, options, quirks, Caveman, or “what will I be asked?” — or when presenting a full help response that should include operator expectations. For a bare “list skills”, CATALOG alone is enough; still mention that `OPERATOR.md` exists for nuances.
3. If either required file for the answer is missing, **STOP** and tell the user (pt-BR) the catalog is not installed — suggest re-running agent sync. Do **not** invent a skill list from memory.

### 2. Present (do not rewrite)

- Show groupings, skill ids, invoke phrases, and short purposes **from the file text**.
- Prefer tables or short grouped lists already in the static files.
- Point the user to invoke a specific skill next by **id** (host prefix from OPERATOR invoke matrix); do not load that skill body unless they ask to run it.
- Do **not** summarize by inventing new wording that replaces the static guide.
