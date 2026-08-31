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
