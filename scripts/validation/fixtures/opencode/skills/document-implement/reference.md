# document-implement - reference

Execution details for `skills/document-implement/SKILL.md`. Plan structure lives in `skills/document-plan/reference.md`.

---

## Prerequisite

| File | Required |
|------|----------|
| `docs/documentation-plan/plan.md` | Yes - created by `document-plan` |
| `docs/overview.md` | Recommended - context for domain steps |

If the plan is missing:

```
/document-plan
```

User may supply an alternate plan path; treat it like `docs/documentation-plan/plan.md` for updates.

**Not SDD:** do not substitute `features/**/PLAN/PLAN_*.md` (Classic SDD) - those follow `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/opencode/skills/_shared/sdd-artifacts/STORAGE.md` and skills `sdd-spec` / `sdd-plan` / `sdd-develop` / `code-review`.

---

## Step selection rules

1. Sort steps in plan order (STEP 1, PASSO 1, etc.).
2. Skip steps marked Completed / Concluído.
3. Respect **Deps:** - dependent steps stay blocked until deps are done.
4. One step per `document-implement` session unless the user explicitly requests batching and context is low.

---

## PLAN update protocol (documentation plan)

Mirror SDD develop (`sdd-develop`) updates on `docs/documentation-plan/plan.md`:

### Completed step block

```markdown
### ✅ STEP 2: External integrations

**Status:** Completed | **Completed:** 2026-05-25 | **Deps:** 1 | **Est.:** 30 min

**Implementation notes:**
- Added docs/integrations.md with HTTP and queue boundaries
- Linked MassTransit consumers under src/... (paths only)
```

### Progress header

```markdown
| **Progress** | 2/8 |
```

```markdown
[🟢🟢⚪⚪⚪⚪⚪⚪] 25% (2/8)
```

### Next step line

```markdown
**Next step:** STEP 3 - Architecture patterns
```

Only check deliverables fully satisfied by **this** step.

---

## Writing guidelines (RAG-oriented)

| Topic | Guidance |
|-------|----------|
| Structure | H2 per concern; short paragraphs; bullet lists for paths and commands |
| Code | Prefer path + symbol references; small snippets only when clarifying |
| Domains | One file per bounded context under `docs/domains/` unless plan says otherwise |
| Integrations | Name external system, direction (in/out), protocol, idempotency if visible |
| Patterns | Name pattern only when folder/naming proves it (e.g. `Handlers/`, `IRepository`) |
| Secrets | Never paste connection strings, keys, or PATs |

---

## Doc language

Read from plan header. If executing first step after manual plan edit without language:

> Documentation language for product `docs/` - **pt-BR** or **English**?

Update plan header after answer.

---

## Context management

After each completed documentation step:

1. Save all touched markdown and `plan.md`.
2. If context ≥ 40%: pause with message including plan path, last step, next step title.
3. Do not start the next pending step in the same session when paused.

Handoff:

```
New chat: /document-implement
```

---

## Validation (manual)

- [ ] New files only under `docs/` in **target** repo
- [ ] Plan progress matches completed work
- [ ] No mandatory org-specific ALM hostnames or product names
- [ ] Prose matches chosen doc language

---

## Optional commit

Offer after one or more steps:

```
/commit
```

Use Conventional Commits scope `docs` when appropriate, e.g. `docs: add domain guide for billing`.
