# Skills operator notes (agent SoT)

Static operator-facing nuances for installed skills. **Read this file** (with `CATALOG.md`) via skill `help-skills` — do **not** re-analyze every `SKILL.md` to answer catalog or “what will I be asked?” questions.

Installed path: `{{TOOLKIT_ROOT}}/skills/_shared/skills-catalog/OPERATOR.md`

Human mirrors: `docs/SKILLS.md`, docs-site Using skills, deep git dive `docs/domains/git-ops.md`. Credits: `docs/CREDITS.md`.

---

## Platform (all skills)

| Topic | Expectation |
|-------|-------------|
| Invoke | Use **skill ids** (kebab-case). Host prefixes differ — see matrix below. Compat: `use skill <id>` / natural language when the host accepts it. |
| Gates | Most mutating skills require guardrails + SESSION; user **`sim`** before writes. Silence ≠ approval. |
| Parallel specialists | Multi-facet planning / analysis / questions: prefer parallel specialist children; this session stays **parent**. Caps and fallback: `_shared/agents/SPAWN.md`. Trivial work stays in-parent. |
| Caveman | Default **OFF**. Commands: `caveman on\|off\|status\|lite\|full\|ultra`. See `_shared/caveman/CAVEMAN.md` and `docs/guides/07-caveman-mode.md`. |
| Caveman **NEVER** | `help-skills`, `commit`, `push`, `open-github-pr` — clear prose always; do not load CAVEMAN for compression. |

### Invoke matrix (host prefixes)

| Host | Explicit form | Example |
|------|---------------|---------|
| Cursor / Claude / Copilot / Grok | `/id` | `/help-skills` |
| Codex / ZCode | `$id` | `$help-skills` |
| Antigravity | `use skill id` or `/id` | `use skill sdd-plan` |
| OpenCode | `skill` tool | `skill({ name: "help-skills" })` |

Codex: plugin packaging alone does not feed `$`; `$` uses InstallRoot `skills/` (`~/.codex/skills`) + optional UserScope. `/hooks` and `/hooks-trust` are trust UI, not skill invoke. There is no `$skill --menu` product flag.

---

## Catalog discovery

| Skill | Operator notes |
|-------|----------------|
| `help-skills` | Read-only. Present `CATALOG.md` + this file. No `sim` gate. Do not paraphrase into a new essay — structure from the files. Do not invent skills. |

---

## Git ops

Deep dive: `docs/domains/git-ops.md` (and `_shared/developer-common/step-4-commits-pr.md` after sync).

| Skill | Confirmations / options | Handoffs |
|-------|-------------------------|----------|
| `commit` | Feature branch only (`feature/<slug>` or `feat/<id>`). Confirm Conventional Commit **message** before commit. No AI co-author trailers. Does **not** open PRs. | Optional skill `push`; PR only via `open-github-pr`. |
| `push` | Confirm before push. No force on protected branches. | After success: hand off to `open-github-pr` immediately when PR intent was clear, else ask. |
| `open-github-pr` | Modes: **feature** (head → `develop`) or **release** (`develop` → `master`/`main`). Confirm **title/body** every time. Ask **auto-merge** every time (`sim`/`não`) — do not infer from “fluxo completo”. Needs `gh` auth. | Owns all `gh pr create`; commit/push must not invent PR shortcuts. |

---

## Forma A / B / C

| Skill | Operator notes |
|-------|----------------|
| `sdd-spec` / `sdd-plan` | Classic SDD. Caveman cap **Lite** when mode ON. |
| `sdd-develop` | **One PLAN step per session**, then stop / handoff. Caveman cap **Full**. |
| `refine-story` / `split-story-checklist` | Forma B prep before A or C. |
| `memory-bank-init` | Forma C Step 0. Bank under repo/global root — **never** under `features/NNN-slug/`. No Spec Kit / uv / specify. |
| `orchestrate-analyze` | Memory Bank Gate first. Conditional parallel specialists per ROSTER. Backlog approval **`sim`** required. Greenfield / `needs_domain`: ARCH draft → **`sim`** before approved style. Parent does not write app code. |
| `orchestrate-deliver` | PRD/PLAN per story via SDD contracts; ask série vs paralelo. Parent does not implement. |
| `orchestrate-develop` | One PLAN step per child via `sdd-develop`; parent does not implement. |

---

## Review and routing

| Skill | Operator notes |
|-------|----------------|
| `code-review` | Must choose **single** vs **multi-angle** (no silent default). Multi-angle: prefer parallel Tasks when `subagents=native`. Report pt-BR. |
| `developer` | Hybrid stack router or ad-hoc scripts; small/medium without full SDD. |
| `*-developer` | Stack-specific small/medium work; medium/complex may spawn ≤2 children. |
| `impeccable` | UI/UX harness → `DESIGN-BRIEF.md` → stack `*-developer`. Partial upstream Impeccable; not a full port. Live hooks need explicit consent. |
| `blip-plugin-developer` | Scaffold Blip plugin → handoff `react-developer`. |

---

## Docs RAG

| Skill | Operator notes |
|-------|----------------|
| `document-plan` | **Ask doc language** (pt-BR or English) before writing the plan. |
| `document-implement` | One documentation-plan step per session. |

---

## Other ops (short)

| Skill | Operator notes |
|-------|----------------|
| `repair-dotnet-build` | Diagnose/fix local (or pasted CI) build/test failures. |
| `test-coverage` | Coverlet report; threshold evaluation. |
| `ef-add-migration` | Discovers startup project / DbContext / migrations folder. |
| `scaffold-message-handler` | Collects requirements first; MassTransit / bus when detected. |
| `refactor` | Incremental safe plan + tests. |
| `api-integrate` | OpenAPI → typed clients/DTOs. |
| `performance-profile` | Hot paths / micro-benchmarks. |
| `containerize` | Multi-stage Docker + compose for local. |
| `i18n-manager` | Extract strings to localization files. |

---

## Must not (catalog answers)

- Invent skill names outside `CATALOG.md`
- Load every `SKILL.md` only to list or explain operator expectations covered here
- Treat `_shared/` packs or architect spawn as invocable skills
