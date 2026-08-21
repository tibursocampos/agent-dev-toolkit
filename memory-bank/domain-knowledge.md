# Domain knowledge

## Terms

| Term | Meaning |
|------|---------|
| Core | Catálogo canônico de skills/policy/router (kebab-case) |
| Adapter | Camada que mapeia core → filesystem/config de um agent |
| Fixture root | Diretório temp/repo usado pelos smokes no lugar do home do usuário |
| Supported agents | Cursor, Antigravity, Claude, Codex, Copilot, OpenCode, Grok, ZCode, Hermes, OpenHands |
| Agent Skills | Padrão aberto `dir/SKILL.md` com frontmatter `name`/`description` |

## Work tracks (process)

| Track | Alias (this release only) | Flow |
|-------|---------------------------|------|
| **Classic SDD** | *(formerly Forma A)* | `sdd-spec` → `sdd-plan` → `sdd-develop` |
| **Backlog Refine** | *(formerly Forma B)* | `refine-story` → `split-story-checklist` |
| **Orchestrated Delivery** | *(formerly Forma C)* | `memory-bank-init` → `orchestrate-analyze` → `orchestrate-deliver` → `orchestrate-develop` \| `sdd-develop` |

Skill ids unchanged. Alias removed in the **following** release (RN07).

## Internal SDD contracts (same call flow)

| Contract | Role |
|----------|------|
| REQ-IDs + AC | Stable requirements in PRD/PLAN templates |
| `validate-prd` / `validate-plan` | Structural scripts (not LLM-as-validator) |
| `CHANGE.md` | Brownfield delta vs current (`features/NNN-slug/CHANGE.md`) |
| `EVD/` + `STATE.md` | Evidence-or-zero matrix (`features/NNN-slug/`) |
| `TRACE.jsonl` | Living-loop events; archive/sync |
| Selective retrieval | No full dump of memory-bank/PRD (`SR-NO-FULL-DUMP`) |

Markdown in git remains SoT. SQLite/FTS is **not** a deliverable (OOS / possible later P4+).

## Evidence

- Plano Cursor: unified agent toolkit (pesquisa docs oficiais Jul 2026)
- Feature 005 P-DOC: tracks + contracts in public docs / docs-site / README
- Twins vivos (não modificar): `../cursor-dev-toolkit`, `../antigravity-dev-toolkit`
