# Repository policy

**agent-dev-toolkit** is a **public, read-only** toolkit: anyone may **clone** or **fork** and use it locally. **Upstream contributions are not accepted** — do not open pull requests to this repository.

License: [MIT](LICENSE) © 2026 Raphael Campos.

## Issues (bugs only)

GitHub Issues are for **bug reports only**.

- Use Issues to report defects (broken sync, validation failures, incorrect docs, runtime errors).
- Do **not** use Issues as a contribution or product channel: no feature requests, RFCs, or “please merge my change” threads.
- There is **no** community contribution flow via Issues or pull requests. Keep local changes in your **fork** (or private copy).

This matches the no-upstream-PR policy below. Security reporting: [SECURITY.md](SECURITY.md). OSS audiences and policy map: [docs/REPO_GOVERNANCE.md](docs/REPO_GOVERNANCE.md).

## For everyone (clone / fork)

You may:

- Clone or fork this repo for personal or team use
- Sync skills to your agent homes (`~/.cursor`, `~/.claude`, `~/.copilot`, …) via `scripts/sync-agent.ps1`
- Customize skills, policy, adapters, and docs **in your fork** (or a private copy)

You may **not**:

- Open pull requests expecting review or merge into this repo
- Request write access for community contributions

Changes you want to keep belong in **your fork** (or your own toolkit copy), not here.

### Install and validate (your copy)

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action ListAgents
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent cursor
pwsh -NoProfile -File .\scripts\validation\validate-core.ps1
```

Live home (opt-in):

```powershell
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent cursor -InstallRoot "$env:USERPROFILE\.cursor" -AllowUserHome
```

See [docs/INSTALL.md](docs/INSTALL.md), [docs/VALIDATION.md](docs/VALIDATION.md), and [docs/SKILLS.md](docs/SKILLS.md).

## Maintainers only (repository owner)

Internal development uses the normal Git flow on branches with write access:

| Branch | Role |
|--------|------|
| `feature/<slug>` or `feat/<id>` | Work branches |
| `develop` | Integration |
| `master` / `main` | Stable release |

Pull requests are **collaborators only**. Use [`.github/PULL_REQUEST_TEMPLATE.md`](.github/PULL_REQUEST_TEMPLATE.md). Feature/fix work targets **`develop`**; release PRs are **`develop` → `master` or `main`** (enforced by [`.github/workflows/enforce-release-source.yml`](.github/workflows/enforce-release-source.yml)). Required CI check: **`validate`** (`.github/workflows/validate-toolkit.yml`).
