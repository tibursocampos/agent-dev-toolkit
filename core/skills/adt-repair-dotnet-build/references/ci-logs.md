## CI logs (paste only)

When the user references a CI failure, ask them to **paste** the failed job/step log. Parse failed steps similarly to local pasted logs.

Do not call remote CI APIs or CLIs. Stay on local `dotnet build` / `dotnet test` when no paste is available.

Do not use this section for non-GitHub hosts unless the user pastes logs.

---
