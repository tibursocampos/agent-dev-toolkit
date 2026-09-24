# Domain knowledge

## Terms

| Term | Meaning |
|------|---------|
| Core | Catálogo canônico de skills/policy/router (kebab-case) |
| Adapter | Camada que mapeia core → filesystem/config de um agent |
| Fixture root | Diretório temp/repo usado pelos smokes no lugar do home do usuário |
| Supported agents | Cursor, Antigravity, Claude, Codex, Copilot, OpenCode, Grok, ZCode, Hermes, OpenHands |
| Agent Skills | Padrão aberto `dir/SKILL.md` com frontmatter `name`/`description` |
| Skills catalog | Agent SoT: `help-skills` → `_shared/skills-catalog/CATALOG.md` + `OPERATOR.md` (**41** ids; não inventar skills) |
| `framework-upgrade` | Orquestrador genérico de upgrade (`audit\|plan\|migrate\|validate`) com packs plugáveis; id sem pin de major |
| Release bootstrap | `scripts/bootstrap/*`: zip HTTPS → SHA256 (TE01) → extract → `sync-agent`; sem `gh`/Node/`.exe` |
| Authorship git-notes | Opt-in (`-Enable`); ref `toolkit-authorship`; **não** substitui `TRACE.jsonl` (REQ-016…018) |

## Work tracks (process)

| Track | Flow |
|-------|------|
| **Classic SDD** | `sdd-spec` → `sdd-plan` → `sdd-develop` |
| **Backlog Refine** | `refine-story` → `split-story-checklist` |
| **Orchestrated Delivery** | `memory-bank-init` → `orchestrate-analyze` → `orchestrate-deliver` → `orchestrate-develop` \| `sdd-develop` |

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
- Feature 008 (remaining): CATALOG/docs **41**; `framework-upgrade` skill + packs; `docs/INSTALL.md` § 0 bootstrap; `docs/guides/09-authorship-git-notes.md` + `Invoke-AuthorshipGitNotes.ps1`
- Twins vivos (não modificar): `../cursor-dev-toolkit`, `../antigravity-dev-toolkit`
