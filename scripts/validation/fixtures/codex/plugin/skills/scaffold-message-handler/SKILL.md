---
name: scaffold-message-handler
description: Scaffold a message consumer in a .NET workspace (MassTransit, RabbitMQ, Azure Service Bus when detected, or similar). Collects requirements first. Use when creating a consumer or invoking /scaffold-message-handler.
---

## STOP - Read before ANY tool call

1. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/rules/guardrails.md`
2. Read `_shared/sdd-artifacts/SESSION.md`; load session-state for `$Cwd`
3. If the relevant gate is not approved: **STOP** - ask user **(pt-BR)** - do **NOT** Write/Shell
4. SDD/develop skills: after **ONE** step/task, **STOP** session - handoff only
5. This skill body is **English**; user-facing prompts may be **(pt-BR)**

### Step -1 - Gate check (report in chat before continuing)

```
Gate check:
[ ] guardrails.mdc read
[ ] SESSION.md read; session-state loaded
[ ] PIPELINE.md read (SDD skills only)
[ ] User confirmed current action (sim)
-> If any unchecked: STOP
```

---

# Skill: scaffold-message-handler

## Status

**Scaffold** - guides discovery, requirements, and implementation in the **target repository**. This toolkit ships **no** embedded corporate consumer templates or org-specific wiring.

## Trigger

Invoke when the user asks for: `/scaffold-message-handler`, `create message consumer`, `/scaffold-message-handler`, or when a PLAN step adds a new queue/topic handler.

Optional arguments: message or event name, queue/topic name, or path to an existing consumer to mirror.

## Outcome

In the **target workspace** (not this toolkit repo unless it is the .NET repo under work):

1. Detected messaging stack and reference consumer(s)
2. Confirmed requirements (payload, errors, idempotency, retry, DLQ)
3. Proposed file layout aligned with the repo
4. Scaffold code and tests **only after** user confirmation - following **existing** project patterns, not copied templates from this repo

## Lazy-load

| When | Path |
|------|------|
| Detection, checklist, scaffold notes | `skills/scaffold-message-handler/reference.md` or `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/scaffold-message-handler/reference.md` after sync |
| Generating or reviewing .NET code | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/dotnet-guidelines/clean-architecture.md` |
| C# / test naming | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/dotnet-guidelines/csharp-patterns.md` |
| Small follow-up without SDD | `/dotnet-developer` |

## Process

### 0. Workspace

Confirm **target .NET repository** (`.sln` or worker/API with messaging). If the workspace is the toolkit only, stop and ask which repo to open.

### 1. Detect messaging stack

Grep/Glob per `reference.md` section Stack detection. Report:

| Signal | Likely stack |
|--------|----------------|
| `MassTransit`, `IConsumer<T>` | MassTransit (transport varies) |
| `RabbitMQ.Client`, `ConnectionFactory` | RabbitMQ direct |
| `Azure.Messaging.ServiceBus` (or similar ASB packages) | Azure Service Bus SDK |
| Other | Describe generically; read one existing consumer |

**Default when none detected:** MassTransit with RabbitMQ transport (implicit). Still collect requirements before scaffolding. Use Azure Service Bus only when ASB packages or existing ASB wiring are already in the repo.

Do **not** require corporate `docs/consumidores/` paths.

### 2. Find conventions

Glob existing consumers/handlers in the repo. Note: namespace layout, registration (`AddMassTransit`, hosted service, etc.), message contract location, test project pattern.

If **no** consumer exists, say so and propose a layout consistent with Clean Architecture after reading `clean-architecture.md`.

### 3. Collect requirements (blocker before code)

Ask using `reference.md` section Requirements checklist. Minimum:

- Queue or topic name (and subscription if applicable)
- Message contract (type name, key fields, schema source)
- Processing responsibility (what changes in the system)
- Error handling: retry count/backoff, DLQ or error queue
- Idempotency strategy (natural key, outbox, dedup store)
- Test expectations (unit vs integration)

Wait for answers. Do not invent queue names or payloads.

### 4. Propose scaffold plan

Present:

- Files to add or extend (paths from repo conventions)
- Registration point (DI / MassTransit config)
- Test files and how to run them

Ask explicit confirmation before writing code.

### 5. Implement (target repo only)

After confirmation:

1. Load `clean-architecture.md` and `csharp-patterns.md`
2. Mirror naming and folder structure from step 2
3. Add consumer/handler, contract if missing, registration, and tests
4. Run `dotnet build` and targeted `dotnet test` for affected projects

### 6. Summarize handoff

Report: stack detected, paths touched, how to run locally, open risks (idempotency, poison messages).

| Situation | Next |
|-----------|------|
| Commit | `/commit` |
| Part of SDD PLAN step | Mark PLAN step; continue in new session if another step remains |
| Build failure | `/repair-dotnet-build` |

## Must not

- Ship or copy hardcoded consumer templates from ai-prompts or internal org repos into the toolkit
- Assume a specific organization or proprietary observability tools
- Generate code before requirements are collected and the user confirms the plan
- Preload entire `dotnet-guidelines/` tree beyond clean-architecture and csharp-patterns when coding

## Handoff examples

```
/repair-dotnet-build
```

```
/sdd-develop - <full-plan-path> - Step N
```

SDD `PLAN` paths: resolve per `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/sdd-artifacts/STORAGE.md` (`features/**/PLAN/PLAN_*.md` or global `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/sdd/<repo-id>/features/**/PLAN/` only). Not root/flat `PLAN/` and not `docs/documentation-plan/plan.md`.
