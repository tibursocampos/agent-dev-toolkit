## Validate and handoff

### Local syntax validation

* Validate file formats (ensure correct YAML spacing in compose).
* Prefer named constants / env templates over magic values when composing app config (`structure-and-quality.md` §4 where applicable).
* Recommend the user run a local test build:

```bash
docker compose build
docker compose up -d
```

### Handoff

Offer committing the configurations via `/commit`.
