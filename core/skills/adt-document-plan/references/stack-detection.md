## Stack detection (step 0)

Use Glob from repo root. Combine signals; report confidence.

| Signal | Glob / read |
|--------|-------------|
| .NET | `**/*.sln`, `**/*.csproj`, `**/Program.cs` |
| Node / frontend | `package.json`, `pnpm-lock.yaml`, `angular.json`, `vite.config.*` |
| Python | `pyproject.toml`, `requirements.txt`, `setup.py` |
| Go | `go.mod` |
| Java | `pom.xml`, `build.gradle*` |
| Rust | `Cargo.toml` |
| Docker / compose | `Dockerfile`, `docker-compose*.yml` |
| CI | `.github/workflows/*.yml`, `azure-pipelines.yml` (describe generically if present) |

Read one representative project file per stack found. Do not invent versions - read from manifests when needed.

**Overview content hints (stack-agnostic):**

- Repository purpose (from README / user)
- Top-level folder map
- How to build and test (commands from repo docs)
- Major deployable units (services, apps, libraries)
- Data stores and messaging (only if evidenced in code/config)

---
