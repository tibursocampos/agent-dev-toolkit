# Language surfaces (chat vs spawn)

Host-agnostic contract for **which language** to use on which surface. Orthogonal to **when** and **how** to spawn (`SPAWN.md`). Not Hermes-only.

Install path after sync: `{{TOOLKIT_ROOT}}/skills/_shared/agents/LANGUAGE.md`

**Path decision:** stay under `_shared/agents/` — not `core/router/` (router is L0 index only).

## Two surfaces

| Surface | Language |
|---------|----------|
| **User chat** and **persisted artifacts** (FEATURE, STORY, PRD, PLAN, ANALYSIS, ARCH, SEC, product `docs/` / README) | **Same as the user's chat** in this session |
| **Internal** thinking, **spawn / Task child prompts**, specialist contexts, **receipts for agents** | **Always en-US** |

Source code, tests, commits, and identifiers stay **English** regardless of chat language.

Do **not** hard-code user-facing prose or SDD artifacts to pt-BR. Match the operator’s current chat language for those files.

## Child prompts (mandatory)

When spawning (native path or documented equivalent):

1. Write the **child prompt**, specialist context, and **agent receipt** in **en-US**.
2. Pass **scoped paths** plus a short **excerpt** (or pointers) of user-language artifacts — **do not** dump a full PLAN / PRD / FEATURE (pt-BR or otherwise) into the child prompt.
3. Parent synthesizes user-facing replies and writes artifacts in the **user chat language**.

## Must not

- Hard-code chat or story artifacts to pt-BR when the user is writing in another language
- Paste a full PLAN / PRD / FEATURE body into a spawn prompt
- Write child prompts, specialist contexts, or agent receipts in the user chat language when that language is not en-US
- Duplicate this policy into every `*-developer` SKILL (they inherit `SPAWN.md` / `subagent-first.md`)

## Cross-refs (lazy-load)

| File | Use |
|------|------|
| `SPAWN.md` | When/how to spawn; Child payload points here |
| `subagent-first.md` | Developer spawn decision; payload language |
| `RECEIPT.md` | Receipt schema (agent-facing = en-US) |
| `docs/SPAWN.md` | Human spawn matrix |
