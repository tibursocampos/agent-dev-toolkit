## Generate Dockerfile, .dockerignore, and compose

### Dockerfile

* Write `Dockerfile` using multi-stage build patterns:
  * **Build stage:** Copy package manifests (`.csproj`, `package.json`, `requirements.txt`) and restore first to leverage layer caching. Then copy code and compile.
  * **Runtime stage:** Copy only build artifacts from the build stage.
  * Enforce security: create and switch to a non-root system user inside the runtime image.
  * Define `EXPOSE` and a stable `ENTRYPOINT` or `CMD`.

### .dockerignore

* Write `.dockerignore`. Standard exclusions:
  * Dotnet: `**/bin`, `**/obj`, `**/.vs`, `**/.git`, `*.user`.
  * Node: `node_modules`, `npm-debug.log`, `dist`, `build`.
  * Python: `__pycache__`, `*.pyc`, `*.pyo`, `*.pyd`, `.venv`, `.env`.

### docker-compose.yml

* Write `docker-compose.yml` for local development:
  * Declare the application service built from the local `Dockerfile`.
  * Declare secondary database or cache services identified in workspace inspect.
  * Configure persistent volumes for database data.
  * Setup environment variables to link the application with the companion services — use placeholders / env files, never paste live secrets.
