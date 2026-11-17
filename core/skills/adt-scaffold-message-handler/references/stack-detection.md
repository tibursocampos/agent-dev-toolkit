## Stack detection (Grep / Glob)

Run from the target repository root. Exclude `bin/`, `obj/`, `node_modules/`.

| Signal | Grep / Glob | Notes |
|--------|-------------|-------|
| MassTransit | `MassTransit`, `AddMassTransit`, `IConsumer<`, `ConsumerDefinition` | Transport may be RabbitMQ, Azure Service Bus, Amazon SQS, in-memory - read config |
| RabbitMQ (direct) | `RabbitMQ.Client`, `ConnectionFactory`, `IAsyncBasicConsumer` | May coexist without MassTransit |
| Azure Service Bus | `Azure.Messaging.ServiceBus`, `ServiceBusClient` | Use when already present in the repo |
| AWS | `Amazon.SQS`, `IAmazonSQS` | Generic handling |
| Kafka | `Confluent.Kafka`, `IConsumer<` (check namespace) | Distinguish from MassTransit `IConsumer` |
| Hosted generic | `BackgroundService` + `ReadOnlyMemory<byte>` or channel | Document as custom |

**Default when no messaging stack is detected:** MassTransit + RabbitMQ (implicit). Prefer Azure Service Bus only when `Azure.Messaging.ServiceBus` (or similar) is already referenced.

**Config files:** also Glob `appsettings*.json`, `**/MassTransit*` registration, `Program.cs` / `Startup.cs` for `AddMassTransit` or bus connection strings (describe generically in summary - do not echo secrets).

**Output to user:** one-line stack verdict (detected or default) + 1-3 example file paths of existing consumers when present.

---
