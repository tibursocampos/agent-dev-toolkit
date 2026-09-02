## Validate and handoff

### Local syntax validation

* Validate file formats (ensure correct YAML spacing in compose).
* Recommend the user run a local test build:

```bash
docker compose build
docker compose up -d
```

### Handoff

Offer committing the configurations via `/commit`.
