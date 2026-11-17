## Workspace inspection

* Identify the programming language/platform (C#, Node.js, Python, static frontend).
* Scan for configuration files (`appsettings.json`, `.env`, `package.json`, `requirements.txt`) to determine:
  * Excluded files and build outputs.
  * Internal network ports.
  * Dependent services (e.g., PostgreSQL, MS SQL, Redis, RabbitMQ).

Do **not** copy secret values from `.env` or credential files into Dockerfiles, compose, or chat. Prefer env templates and named placeholders only.
