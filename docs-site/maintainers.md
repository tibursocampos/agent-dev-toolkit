---
title: Maintainers
---

# Maintainers

**agent-dev-toolkit** is a public, read-only toolkit. Anyone may clone or fork it and use it locally. Upstream contributions are not accepted. Do not open pull requests expecting review or merge into this repository.

License: MIT © 2026 Raphael Campos.

## Who this is for

| Audience | Intent | Start |
|----------|--------|-------|
| **Visitor** | Understand the toolkit, clone or fork, read policy | [Home](index.md), [Get started](get-started.md), this page |
| **Operator** | Sync skills to an agent home, run validation | [Get started](get-started.md), [Adapters](adapters.md), [Using skills](using-skills.md) |
| **Maintainer** | Change this repository (write access) | The section below. Required check **`ci-ok`** on `pull_request` to `develop`, `master`, and `main` (`.github/workflows/validate-toolkit.yml`). Release source: `.github/workflows/enforce-release-source.yml` |

| Topic | Where |
|-------|--------|
| Clone / fork allowed; no upstream PRs | This page |
| Issues are bugs only | This page |
| Vulnerability reporting | This page |
| License | `LICENSE` (MIT) |
| Install, sync, uninstall | [Get started](get-started.md) |
| Validation and CI | [Architecture](architecture.md) |

## Issues (bugs only)

GitHub Issues are for defect reports: broken sync, validation failures, incorrect docs, runtime errors.

- Do not use Issues for feature requests, RFCs, or contribution proposals.
- There is no community contribution flow via Issues or pull requests.
- Security vulnerabilities follow the reporting section below. They do not go in public Issues.

Keep local changes in your fork or private copy.

## Clone and fork

You may:

- Clone or fork this repo for personal or team use
- Sync skills to your agent homes (`~/.cursor`, `~/.claude`, `~/.copilot`, and the other roots) via `scripts/sync-agent.ps1`
- Customize skills, policy, adapters, and docs in your fork

You may not open pull requests expecting review or merge here, and you may not request write access for community contributions.

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action ListAgents
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent cursor
pwsh -NoProfile -File .\scripts\validation\validate-core.ps1
```

Live home (opt-in):

```powershell
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent cursor -InstallRoot "$env:USERPROFILE\.cursor" -AllowUserHome
```

## Maintainers only

Internal development uses Git on branches with write access.

| Branch | Role |
|--------|------|
| `feature/<slug>` or `feat/<id>` | Work branches |
| `develop` | Integration |
| `master` / `main` | Stable release |

Pull requests are collaborators only. Prefer `/open-github-pr` (after `/commit` / `/push`), or use `.github/PULL_REQUEST_TEMPLATE.md` in the web UI. Feature and fix work targets **`develop`**. Release PRs are **`develop` → `master` or `main`**, enforced by `.github/workflows/enforce-release-source.yml`. `.github/workflows/validate-toolkit.yml` runs on `pull_request` to `develop`, `master`, and `main`. The required CI check is **`ci-ok`**. Jobs `validate` and `validate-ubuntu` feed that check. Branch protection must require `ci-ok`, not the job name `validate` alone.

## Reporting a vulnerability

Do not open a public GitHub Issue for security vulnerabilities.

Use the first channel that is available on this repository:

1. **GitHub private vulnerability reporting** — when enabled, use **Security → Advisories → Report a vulnerability**.
2. **Contact repository owners via GitHub** — if private reporting is not enabled yet, contact an owner through their GitHub profile. Do not invent a security mailbox.

No dedicated security email is published for this repository.

Before treating channel 1 as available, maintainers:

1. Enable **Private vulnerability reporting** (**Settings → Code security and analysis → Private vulnerability reporting**).
2. Confirm the Security tab shows **Report a vulnerability** for people who are not collaborators.
3. Keep this file honest. Add a mailbox here only when a real address exists.

Include:

- A description of the issue and the potential impact
- Steps to reproduce (a proof of concept if it is safe to share privately)
- Affected paths (skills, scripts, adapters, docs) when known
- Your preferred contact for follow-up

Give maintainers reasonable time to assess a report before any public disclosure.
