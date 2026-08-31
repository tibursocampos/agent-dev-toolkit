## Preflight - GitHub CLI

1. Resolve `gh` (cross-platform):
   - **Always first:** `gh` on `PATH` (`Get-Command gh` / `command -v gh` / `which gh`)
   - **Windows** (PATH miss only): try `C:\Program Files\GitHub CLI\gh.exe`
   - **macOS** (PATH miss only): try Homebrew locations `/opt/homebrew/bin/gh` (Apple Silicon) and `/usr/local/bin/gh` (Intel)
   - **Linux** (PATH miss only): try `/usr/bin/gh`, `/usr/local/bin/gh`, and `$HOME/.local/bin/gh` (user installs / some package layouts)
   - Do **not** invent other OS-specific paths; if still missing, go to the STOP help below (official install docs cover apt/dnf/brew/etc.)
2. Run `gh auth status` (or equivalent with the resolved absolute path)
3. If `gh` is unavailable or not authenticated:
   - Note (optional): an MCP GitHub server may work as a **fallback** for create/list when configured in the host — prefer `gh` for this skill
   - If neither `gh` (authenticated) nor a working MCP GitHub fallback is available: **STOP** and help the user (pt-BR):

```text
GitHub CLI (gh) não encontrado ou sem login.

Instalar (todas as plataformas): https://cli.github.com/
  - Windows: MSI / winget / scoop (ou PATH + "GitHub CLI")
  - macOS: brew install gh
  - Linux: pacote da distro / instruções em cli.github.com (apt, dnf, etc.)

Login: gh auth login

Depois rode /open-github-pr de novo.
```
