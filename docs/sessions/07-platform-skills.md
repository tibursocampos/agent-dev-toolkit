# 07 — Platform skills

These skills sit beside delivery. They do not replace O1–O3 or Classic SDD. When the change is a PLAN step, finish the skill and return to `/sdd-develop` on the next step in a new chat.

## `api-standards`

Trigger: `/api-standards`. Optional focus: `rest`, `versioning`, `errors`, `naming`, `security` (load only that playbook). No focus: ask which areas matter, at most three.

Agnostic HTTP guidance: methods, status codes, resource URLs, versioning, error envelope, pagination, naming, security hygiene. No company contract, no branded error codes, no secrets. A review of an existing surface is a short gap list, not a rewrite of the whole API in one pass.

Typed clients are **not** this skill. Handoff:

```text
api-integrate - <openapi-or-schema-path>
```

After standards are agreed, implementation continues in the stack skill from [04](04-implement-and-guidelines.md).

## `api-integrate`

Trigger: `/api-integrate`. Schema: local OpenAPI/Swagger or a remote metadata URL. Optional client name.

Wait for a workflow choice after the plan, then generate DTOs and a client (Refit or HttpClient on C#, Axios or fetch on JS/TS, HTTPX on Python), with timeouts and error wrappers. No `any` DTOs. No hardcoded secrets. Standards questions go back to `api-standards`.

## `i18n-manager`

Trigger: `/i18n-manager`. Optional directory to scan.

Wait for a workflow choice **before** writing. Replace raw UI strings with the host helper (`_localizer["Key"]`, `t('Key')`, and the matching pattern in the repo). Resources: `.resx` for C#, `.json` dictionaries for JS/TS. Do not use generic keys. Do not extract logger or configuration strings.

App-wide localization that needs a plan goes to `/sdd-spec`. Small follow-up goes to `/developer` or the stack skill. Commit is `/commit`.

## `containerize`

Trigger: `/containerize`. Optional host port.

Inspect the workspace, wait for a workflow choice, then write a multi-stage Dockerfile (non-root, alpine or distroless), `.dockerignore` (no secrets, no local packages, no git metadata), and a `docker-compose.yml` for local dependencies. DevOps notes load `devops-guidelines/deployment-process.md` only when that step needs them.

## `ef-add-migration`

Trigger: `/ef-add-migration`, or a PLAN step that adds an EF Core migration.

Discover the solution, startup project, target project, `DbContext`, and migrations folder from the repo. Do not hardcode paths. Optional PascalCase name; if omitted, infer from the diff and **confirm** before `dotnet ef migrations add`. Missing tool: follow the skill’s tool note; the skill body does not pin a package version. Do not target production unless the operator asks.

This skill does not run against the toolkit repo when the operator meant a consumer app.

Next: continue `/sdd-develop` on the PLAN step, `/repair-dotnet-build` if the build breaks, or `/commit`.

## `scaffold-message-handler`

Trigger: `/scaffold-message-handler`, or a PLAN step that adds a queue or topic handler.

Requirements are a blocker. The skill does not invent queue names or payloads. Detect from the consumer repo:

| Signal | Stack |
|--------|--------|
| `MassTransit`, `IConsumer<T>` | MassTransit |
| `RabbitMQ.Client` | RabbitMQ client |
| `Azure.Messaging.ServiceBus` | Azure Service Bus |
| Nothing detected | Propose MassTransit with RabbitMQ only after requirements. Use Service Bus only when that SDK is already in the repo |

Collect queue or topic, contract, responsibility, retry and dead-letter behavior, idempotency, and test expectations. Propose files and wait for confirmation before writing. Patterns come from the consumer repo, not from templates shipped in this toolkit. There is no org-specific consumer package here.

Build and a targeted test follow. Commit, continue the PLAN, repair the build, or hand a small follow-up to `/dotnet-developer`.
