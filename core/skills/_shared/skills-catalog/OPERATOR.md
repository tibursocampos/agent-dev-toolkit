# Skills operator notes (agent SoT)

Static operator-facing nuances for installed skills. **Read this file** (with `CATALOG.md`) via skill `adt-help-skills` — do **not** re-analyze every `SKILL.md` to answer catalog or “what will I be asked?” questions.

Installed path: `{{TOOLKIT_ROOT}}/skills/_shared/skills-catalog/OPERATOR.md`

Human mirrors: `docs/SKILLS.md`, docs-site Using skills, deep git dive `docs/domains/git-ops.md`. Credits: `docs/CREDITS.md`.

---

## Platform (all skills)

| Topic | Expectation |
|-------|-------------|
| Invoke | Use **skill ids** (kebab-case). Host prefixes differ — see matrix below. Compat: `use skill <id>` / natural language when the host accepts it. |
| Gates | Apply the active skill's contract. Classic SDD and O1/O2/O3 use one complete PLAN approval before implementation; draft writing is preparation. Other skills keep their own confirmations. |
| Parallel specialists | Multi-facet planning / analysis / questions: prefer parallel specialist children; this session stays **parent**. Caps and fallback: `_shared/agents/SPAWN.md`. Trivial work stays in-parent. |
| Orchestrator mode | Default **`adaptive`**. See `orchestrator-session` section "Modes". Commands: `orchestrator always\|adaptive\|status` (aliases: `orchestrate …`, `parent …`). |
| Caveman | Default **OFF**. Commands: `caveman on\|off\|status\|lite\|full\|ultra`. See `_shared/caveman/CAVEMAN.md` and `docs/guides/07-caveman-mode.md`. |
| Caveman **NEVER** | `adt-help-skills`, `adt-read-sdd-artifact`, `adt-commit`, `adt-push`, `adt-open-github-pr` — clear prose always; do not load CAVEMAN for compression. |

### Invoke matrix (host prefixes)

| Host | Explicit form | Example |
|------|---------------|---------|
| Cursor / Claude / Copilot / Grok | `/id` | `/adt-help-skills` |
| Codex / ZCode | `$id` | `$adt-help-skills` |
| Antigravity | `use skill id` or `/id` | `use skill adt-sdd-plan` |
| OpenCode | `skill` tool | `skill({ name: "adt-help-skills" })` |

Codex: plugin packaging alone does not feed `$`; `$` uses InstallRoot `skills/` (`~/.codex/skills`) + optional UserScope. `/hooks` and `/hooks-trust` are trust UI, not skill invoke. There is no `$skill --menu` product flag.

---

## Catalog discovery

| Skill | Operator notes |
|-------|----------------|
| `adt-help-skills` | Read-only. Present `CATALOG.md` + this file. No `sim` gate. Do not paraphrase into a new essay — structure from the files. Do not invent skills. |

---

## Git ops

Deep dive: `docs/domains/git-ops.md` (and `_shared/developer-common/step-4-commits-pr.md` after sync).

| Skill | Confirmations / options | Handoffs |
|-------|-------------------------|----------|
| `adt-commit` | Feature branch only (`feature/<slug>` or `feat/<id>-<slug>`). Confirm Conventional Commit **message** before commit. No AI co-author trailers. Does **not** open PRs. | Optional skill `adt-push`; PR only via `adt-open-github-pr`. |
| `adt-push` | Confirm before push. No force on protected branches. | After success: hand off to `adt-open-github-pr` immediately when PR intent was clear, else ask. |
| `adt-open-github-pr` | Modes: **feature** (head → `develop`) or **release** (`develop` → `master`/`main`). Confirm **title/body** every time. Ask **auto-merge** every time (`sim`/`não`) — do not infer from “fluxo completo”. Needs `gh` auth. | Owns all `gh pr create`; `adt-commit` / `adt-push` must not invent PR shortcuts. |

---

## Classic SDD / Backlog Refine / Orchestrated Delivery

**Track choice:** Classic SDD is standalone — `/adt-sdd-spec` and `/adt-sdd-plan` do **not** require `adt-orchestrate-analyze` first. Offer Orchestrated Delivery as an option for multi-story / brownfield; never as a hard gate.

| Skill | Operator notes |
|-------|----------------|
| `adt-sdd-spec` / `adt-sdd-plan` | Classic SDD — direct invocation is supported. Draft/write preparation has no separate approval; the complete PLAN is approved once before implementation. Caveman cap **Lite** when mode ON. |
| `adt-sdd-develop` | Uses the approved PLAN cadence: step-by-step stops after one step; continuous advances through eligible steps. PLAN is the only progress source; SESSION flags and claims are not prerequisites. Caveman cap **Full**. |
| `adt-read-sdd-artifact` | Read-only. Canonical FEATURE/STORY/PRD/PLAN under `features/` → `source_context`; reject `..` / outside `features/` with precise reason. Caveman **NEVER**. When envelope already present, skip opaque re-read. |
| `adt-refine-story` / `adt-split-story-checklist` | Backlog Refine prep before Classic SDD or Orchestrated Delivery. |
| `adt-requirement-review` | Exactly one mode: `--feature` or `--tech`; asks once when missing (no silent default). Report and Q&A writes only after `sim`. Never edits code. `--tech` searches the repository and does not guess. |
| `adt-memory-bank` | Optional O1 context; initialize only when useful or explicitly requested. Bank under repo/global root — **never** under `features/NNN-slug/`. No Spec Kit / uv / specify. |
| `adt-epic-planner` | Optional initiative discovery for work likely to span multiple features. It writes a navigable `EPIC.md`; it is not a prerequisite for O1 or a delivery tracker. When starting O1 from it, identify the relevant EPIC and select a stable feature ID; O1 reads relevant context without inheriting extra gates. |
| `adt-orchestrate-analyze` | Proportional triage and specialists for concrete questions. Memory Bank and sidecars are optional context; no backlog approval gate. O1 owns one contextual table and does not write app code. |
| `adt-orchestrate-prepare` | Prepares PRD/PLAN per selected story; one approval covers the complete explicitly listed PLAN set before implementation. Independent stories may proceed when another is blocked; parent does not implement. |
| `adt-orchestrate-implement` | Serial queue: one PLAN step per child; reconcile each result before the next dispatch. Step-by-step or continuous cadence; no SESSION/claim prerequisites. Parent does not implement app code. |

---

## Review and routing

| Skill | Operator notes |
|-------|----------------|
| `adt-code-review` | Must choose **single** vs **multi-angle** (no silent default). Multi-angle: prefer parallel Tasks when `subagents=native`. Report in the active user-chat language. |
| `adt-code-explain` | With endpoints, compares changes and asks for any missing endpoint; without endpoints, explains existing code for a topic, file, folder, or symbol. Ambiguous intent prompts first. Report cites opened code and separates observation from inference. |
| `adt-developer` | Hybrid stack router or ad-hoc scripts; small/medium without full SDD. |
| `adt-*-developer` | Stack-specific small/medium work; medium/complex may spawn ≤2 children. |
| `adt-blip-plugin-developer` | Scaffold Blip plugin → handoff `adt-react-developer`. |

---

## Docs RAG

| Skill | Operator notes |
|-------|----------------|
| `adt-document-plan` | **Ask doc language** (pt-BR or English) before writing the plan. |
| `adt-document-implement` | One documentation-plan step per session. |

---

## Other ops (short)

| Skill | Operator notes |
|-------|----------------|
| `adt-repair-dotnet-build` | Diagnose/fix local (or pasted CI) build/test failures. |
| `adt-test-coverage` | Coverlet report; threshold evaluation. |
| `adt-run-tests` | Does not edit code. Asks when the stack is not recognized. Does not replace `adt-test-coverage`. |
| `adt-ef-add-migration` | Discovers startup project / DbContext / migrations folder. |
| `adt-scaffold-message-handler` | Collects requirements first; MassTransit / bus when detected. |
| `adt-refactor` | Incremental safe plan + tests. |
| `adt-api-integrate` | OpenAPI → typed clients/DTOs. |
| `adt-api-standards` | Agnostic HTTP/API standards (REST, versioning, errors). No company contracts; hand off clients to `adt-api-integrate`. |
| `adt-framework-upgrade` | Generic orchestrator (not a pinned pack). Modes: `audit` \| `plan` \| `migrate` \| `validate`; migrate needs **`sim`**. Packs under `packs/` resolve framework+version; point to `_shared/*-guidelines` + official sources (Learn / angular.dev / PEP 8). Skill id stays `adt-framework-upgrade`; do **not** rename `adt-angular-developer` / `adt-dotnet-developer` / `adt-python-developer`. |
| `adt-performance-profile` | Hot paths / micro-benchmarks. |
| `adt-containerize` | Multi-stage Docker + compose for local. |
| `adt-i18n-manager` | Extract strings to localization files. |

---

## Must not (catalog answers)

- Invent skill names outside `CATALOG.md`
- Load every `SKILL.md` only to list or explain operator expectations covered here
- Treat `_shared/` packs or architect spawn as invocable skills
