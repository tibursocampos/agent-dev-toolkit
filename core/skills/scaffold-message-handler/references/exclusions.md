## Explicit exclusions

Do **not** require or generate by default:

- Organization-specific connection templates or proprietary package names from a former monorepo
- Mandatory Datadog/Sonar/manual sign-off checklist tasks
- Python or REST scripts to create remote work items

If the target repo has no messaging libraries, proceed with the **MassTransit / RabbitMQ default** after requirements are collected and the user confirms the plan. Do not block on broker selection unless the user rejects the default.
---
