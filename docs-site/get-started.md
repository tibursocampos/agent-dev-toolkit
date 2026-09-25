---
title: Get started
---

# Get started

Deploy **agent-dev-toolkit** into one or more coding agents, then open the project you want to change.

| Path | When |
|------|------|
| **Option 0 — Release bootstrap (recommended)** | Download a bootstrap entrypoint from GitHub Releases. It fetches the zip over HTTPS, checks SHA256, extracts, and opens `toolkit.ps1`. No full clone. |
| **Option 1 (after clone)** | Interactive Smart Manager: `pwsh -NoProfile -File .\scripts\toolkit.ps1` |
| **Option 2+** | Non-interactive sync and checks on [CLI](cli.md) |

The repository is public. Clone and fork freely. Upstream contributions are not accepted. See [Maintainers](maintainers.md).

## Prerequisites

Supported OS: **Windows**, **Linux** (Ubuntu, Debian, and derivatives), and **macOS**.

| Requirement | Notes |
|-------------|--------|
| **PowerShell** | **Windows:** PowerShell **5.1+** or **pwsh 7+** (recommended). **Linux / macOS:** **pwsh 7+ only**. |
| **Git** | Needed for option 1 / 2+ (clone). Option 0 does not require Git. |
| **Target agent** | At least one of: Cursor, Claude Code, Codex, GitHub Copilot, Antigravity, OpenCode, Grok Build, ZCode ADE, Hermes, OpenHands |
| **Network (option 0)** | HTTPS to GitHub Releases. Uses `curl` (preferred) or `Invoke-WebRequest`. The bootstrap does not use the `gh` CLI, Node, or a compiled `.exe`. |

## 0. Release bootstrap

The entrypoint downloads the zip, checks the SHA256, and opens the CLI.

| Operating system | File | Download |
| --- | --- | --- |
| Windows | `bootstrap.bat` | <a class="file-download" href="https://github.com/tibursocampos/agent-dev-toolkit/releases/latest/download/bootstrap.bat">bootstrap.bat</a> |
| Windows, Linux, and macOS | `bootstrap.ps1` | <a class="file-download" href="https://github.com/tibursocampos/agent-dev-toolkit/releases/latest/download/bootstrap.ps1">bootstrap.ps1</a> |
| Linux and macOS | `bootstrap.sh` | <a class="file-download" href="https://github.com/tibursocampos/agent-dev-toolkit/releases/latest/download/bootstrap.sh">bootstrap.sh</a> |

On Windows, run `bootstrap.bat`. It clears the browser download mark on `bootstrap.ps1` and starts PowerShell with `-ExecutionPolicy Bypass`, then prefers `pwsh` and falls back to Windows PowerShell. A double-click that fails stays open until you press a key. If `bootstrap.ps1` is missing beside the `.bat`, the `.bat` downloads that script from the same Release URL before running it. On Linux and macOS, place `bootstrap.sh` next to `bootstrap.ps1` and mark the shell file executable before you run it.

A bad checksum exits non-zero. There is no extract and no handoff.

Published by `.github/workflows/publish-release-bootstrap.yml`:

| Artifact | Name |
|----------|------|
| Toolkit zip | `agent-dev-toolkit.zip` |
| SHA256 sidecar | `agent-dev-toolkit.zip.sha256` |
| Entrypoints | `bootstrap.ps1`, `bootstrap.bat`, `bootstrap.sh` |

Override owner/repo with `-Owner` / `-Repo` or `TOOLKIT_RELEASE_OWNER` / `TOOLKIT_RELEASE_REPO`. Override asset names with `-ZipAssetName` / `-ChecksumAssetName` or `TOOLKIT_RELEASE_ZIP_ASSET` / `TOOLKIT_RELEASE_CHECKSUM_ASSET`.

### Bootstrap flags

| Flag / env | Purpose |
|------------|---------|
| *(default)* | After SHA256 OK, extract, then open interactive `toolkit.ps1` |
| `-NoExtract` | Verify checksum only |
| `-SkipSync` | Stop after a successful extract |
| `-DirectSync` | After extract, call `sync-agent.ps1` |
| `-SyncWhatIf` | With `-DirectSync`, forward `-WhatIf` to `sync-agent.ps1` |
| `-Agent` / `TOOLKIT_SYNC_AGENT` | Registry agent id when `-DirectSync` (default `cursor`) |
| `-InstallRoot` / `-AllowUserHome` / `-Mode` / `-UserScope` | Forwarded to `sync-agent.ps1` when `-DirectSync` runs |
| `-ZipAssetName` / `TOOLKIT_RELEASE_ZIP_ASSET` | Override zip asset (default `agent-dev-toolkit.zip`) |
| `-ChecksumAssetName` / `TOOLKIT_RELEASE_CHECKSUM_ASSET` | Override checksum asset (default `agent-dev-toolkit.zip.sha256`) |
| `-ExpectedSha256` | Hex SHA256 override (skips the checksum download) |
| `-LocalZipPath` + `-SkipDownload` | Offline smoke without network |
| `-Extract` | Legacy no-op alias (extract is on unless `-NoExtract`) |

## 1. Clone (alternative)

```powershell
git clone https://github.com/tibursocampos/agent-dev-toolkit.git agent-dev-toolkit
cd agent-dev-toolkit
```

## After the download

The menu, every `-Action`, sync, validate, and uninstall live on [CLI](cli.md).

Open the application repo in the agent, then [First use](first-use.md). A feature path is [Orchestrated Delivery](orchestrated-delivery.md).

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Sync refuses InstallRoot | Path under the user profile without the opt-in | Add `-AllowUserHome`, or confirm in the wizard |
| Copilot TE02 | Missing or invalid `-Mode` | Pass `-Mode user` or `-Mode repo` |
| Skills missing in the IDE | Synced a fixture only, or the agent needs a restart | Sync the **live home**. Trust hooks in the agent UI if it asks |
| A local run fails the way CI would | The command expected a home write | Use fixtures or Validation lab smokes |

Next: [First use](first-use.md).
