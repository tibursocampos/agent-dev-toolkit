---
description: Resolve SDD artifact language from invocation, preferences, manifest, and conversation; identifiers English
alwaysApply: true
---

# SDD artifact language - resolved content language (agent workflow only)

## Scope (read first)

| In scope | Out of scope |
|----------|--------------|
| `features/**/PRD/*.md`, global `.../features/**/PRD/` | Source code, tests, configs |
| `features/**/PLAN/PLAN_*.md`, global `.../features/**/PLAN/` | Project `docs/`, README, ADRs (ask user) |
| Progress, step notes, checkboxes inside those PLAN files | Root/flat `PRD/` / `PLAN/` (not valid Classic SDD paths) |

This rule does **not** change code language. It does **not** default project documentation to pt-BR.

**Host planning output** (the host's plan view or plan files) is **user-facing chat**, not this SDD PLAN path and not `SKILL.md`. It follows `user-language-pt-br.md` / `LANGUAGE.md` chat output. Do not write it in English because guidelines are English.

## SDD artifacts - resolve content language

Content language for SDD artifact bodies (section titles, labels, prose, acceptance criteria, PLAN steps, implementation notes) is resolved by `{{TOOLKIT_ROOT}}/skills/_shared/agents/LANGUAGE.md` (CL-CONTENT-LANGUAGE).

- Use templates in `{{TOOLKIT_ROOT}}/skills/sdd-spec/reference.md` and `{{TOOLKIT_ROOT}}/skills/sdd-plan/reference.md` matching the resolved content language.
- Do **not** hard-code pt-BR when the resolved content language is another language.

**Identifiers in prose:** type names, method names, API routes, file paths, and test names stay in **English** (e.g. `UserService`, `Should_ReturnOk_When_ValidRequest`).

**No implementation code** in PRD/PLAN bodies (existing skill boundaries). If a minimal illustrative snippet is unavoidable, syntax and identifiers remain **English**.

## Code - identifiers English; comments/docs mirror or ask

Any code generated or edited in the repository:

- **Identifiers** (types, members, params, files), commit messages, and test names `Should_<Result>_When_<Condition>`: always **English**
- **Comments / XML docs / narrative docs:** **mirror** the touched area (pt-BR↔pt-BR, EN↔EN); **ask** on greenfield / no clear mirror (user override wins) — `structure-and-quality.md` §2

This rule does not grant an exception for “artifact in English” on identifiers or commit messages.

## Project documentation - ask

When `sdd-spec`, `sdd-plan`, or `sdd-develop` will create or change **product** documentation under `docs/`, README, or similar (not PRD/PLAN agent files), **ask once** before writing, with a question component (`{{TOOLKIT_ROOT}}/skills/_shared/agents/QUESTIONS.md`) that offers these options. If no component is available, ask in numbered text.

- Header, in the user's conversation language. pt-BR example (example only): `Em qual idioma gravar a documentação do sistema (docs/, README)?`
- `pt-BR`, label: `Português (pt-BR)`
- `en`, label: `English`
- `other`, label: `Other (state the language)`; free text, the user states the language.

Record the choice in the PLAN step or PRD notes if relevant. Do not assume pt-BR from this rule.

## Override - SDD artifact in English only

Apply only when the user explicitly requests it in the **same** prompt that invokes the skill (case-insensitive), for example:

- `em inglês`, `no inglês`, `in english`, `english only`
- `PRD em inglês`, `PLAN em inglês`, `write PRD in English`

Then write the **SDD `.md` artifact** in English using the English template sections in `reference.md` (if documented) or equivalent structure. Confirm in one chat line. Code remains English.

Set `artifact_language` to `"en"` in `{{SDD_ROOT}}/<repo-id>/manifest.json` when using global storage.

## Skills and conflicts

| Skill | Behavior |
|-------|----------|
| `sdd-spec` | New PRD -> resolved content language |
| `sdd-plan` | New PLAN -> resolved content language; read existing PRD in any language |
| `sdd-develop` | Code -> English; update PLAN in **existing file language** |

## Install path

After `scripts/sync-agent.ps1`: `{{TOOLKIT_ROOT}}/rules/sdd-artifact-language-pt-br.mdc`
