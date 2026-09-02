# Language surfaces (chat vs spawn) + content-language

Host-agnostic contract for **which language** to use on which surface. Orthogonal to **when** and **how** to spawn (`SPAWN.md`). Not Hermes-only.

Install path after sync: `{{TOOLKIT_ROOT}}/skills/_shared/agents/LANGUAGE.md`

**Path decision:** stay under `_shared/agents/` — not `core/router/` (router is L0 index only).

**Rule ID:** `CL-CONTENT-LANGUAGE`

Companion: `SPAWN.md`, `SELECTIVE-RETRIEVAL.md` (`SR-NO-FULL-DUMP`), `STORAGE.md` (manifest `artifact_language`), `memory-bank/conventions.md`.

## Surfaces (overview)

| Surface | Language |
|---------|----------|
| **User chat** (operator-facing replies) | **User chat language** for this session |
| **SDD / story artifact bodies** (FEATURE, STORY, PRD, PLAN, ANALYSIS, ARCH, SEC, CONTINUITY, CHANGE prose, product `docs/` / README when authored as SDD) | **Content-language** (resolution below) — often matches chat, but may diverge under override |
| **Internal** thinking, **spawn / Task child prompts**, specialist contexts, **receipts for agents** | **Always en-US** |

Source code, tests, commits, and identifiers stay **English** regardless of chat or content-language.

Do **not** hard-code any locale (including pt-BR) as the only allowed chat or artifact language.

## Content-language (REQ-003)

**Content-language** is the language of **written SDD artifact prose** — distinct from (1) operator chat and (2) spawn/receipt en-US.

### Resolution (deterministic — no hard-coded locale)

Resolve **once** per Write of an SDD artifact (or at skill start when authoring a batch). Prefer earlier steps:

1. **Invocation override** — operator explicitly requested a language for this run (e.g. English PRD / English PLAN).
2. **`preferences.json` `artifact_language`** — when non-null (e.g. `pt-BR`, `en`). File: `{{SDD_ROOT}}/preferences.json`.
3. **Repo / global `manifest.json` `artifact_language`** — when non-null (`STORAGE.md`).
4. **Else** — match the **user chat language** for this session.

`null` / unset preferences and manifest fields mean “no override” — **not** “default to pt-BR”.

Record the resolved value when skills persist manifests (`sdd-spec` / storage steps). Do not invent a locale string that was never chosen.

### What content-language applies to

| In scope | Out of scope (other rules) |
|----------|----------------------------|
| FEATURE / STORY / PRD / PLAN / ANALYSIS / ARCH / SEC body prose | Path segments, REQ-IDs, skill ids, portable paths (English) |
| CONTINUITY / CHANGE narrative when written as feature prose | `SKILL.md` / shared guideline bodies (English SoT) |
| Product `docs/` / README when the skill asks language first | Source, tests, commit messages (always English) |
| Operator-facing confirm drafts that will be persisted as artifacts | Spawn child prompts, specialist contexts, agent receipts (**always en-US**) |

### Alignment with chat vs spawn

| Concern | Rule |
|---------|------|
| Chat replies | User chat language (may differ from content-language only when explaining an override) |
| Artifact Write | Content-language from resolution above |
| Child prompt / receipt | **en-US**; pass **scoped portable paths** + short excerpt — **do not** dump full PLAN / PRD / FEATURE / `memory-bank/` (`SR-NO-FULL-DUMP` / CT6) |
| Parent synthesis | Parent writes user-facing chat and artifacts; children stay en-US internally |

Content-language **must not** flip child prompts to the operator language. Selective retrieval stays path/summary oriented regardless of artifact locale.

## Child prompts (mandatory)

When spawning (native path or documented equivalent):

1. Write the **child prompt**, specialist context, and **agent receipt** in **en-US**.
2. Pass **scoped paths** plus a short **excerpt** (or pointers) of content-language artifacts — **do not** dump a full PLAN / PRD / FEATURE into the child prompt.
3. Parent synthesizes user-facing replies in the **user chat language** and Writes artifacts in **content-language**.

## Must not

- Hard-code chat or story artifacts to a single locale (e.g. always pt-BR) when preferences/manifest/chat say otherwise
- Treat `artifact_language: null` as an implicit hard-coded locale
- Paste a full PLAN / PRD / FEATURE / `memory-bank/` body into a spawn prompt
- Write child prompts, specialist contexts, or agent receipts in the user chat / content-language when that language is not en-US
- Duplicate this policy into every `*-developer` SKILL (they inherit `SPAWN.md` / `subagent-first.md`)

## Cross-refs (lazy-load)

| File | Use |
|------|------|
| `SPAWN.md` | When/how to spawn; Child payload points here |
| `subagent-first.md` | Developer spawn decision; payload language |
| `RECEIPT.md` | Receipt schema (agent-facing = en-US) |
| `docs/SPAWN.md` | Human spawn matrix |
| `SELECTIVE-RETRIEVAL.md` | `SR-NO-FULL-DUMP` — paths/summaries, not full dumps |
| `STORAGE.md` | Manifest `artifact_language` field |
| `memory-bank/conventions.md` | Bank mirror of chat / artifact / spawn language split |
