## Detect tech stack and load guidelines

* Check the current workspace files (look for `.csproj`, `package.json`, `requirements.txt`, etc.).
* Lazy-load **only** the corresponding language guidelines from `{{TOOLKIT_ROOT}}/skills/_shared/` (see SKILL Lazy-load table).
* Do **not** preload every language pack.
