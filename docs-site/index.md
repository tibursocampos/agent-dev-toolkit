---
title: Home
hide:
  - navigation
  - toc
---

<div class="home-hero">

<p class="home-brand reveal reveal--brand">agent-dev-toolkit</p>

<h1 class="home-headline">One shared skills core. Adapters into each agent home (10 agents).</h1>

<p class="home-lead">Download the Release bootstrap, run it, then sync into your agent home—no clone required.</p>

<figure class="home-diagram reveal reveal--diagram">
  <img src="assets/core-adapters-diagram.svg" width="960" height="368" alt="Core skills flow through adapters into each agent's install root" />
</figure>

<div
  class="agent-switcher reveal reveal--switcher"
  id="agent-switcher"
  data-agent-switcher
  data-default-agent="cursor"
>
  <p class="agent-switcher__label" id="agent-switcher-label">Choose an agent</p>
  <div class="agent-switcher__options" role="radiogroup" aria-labelledby="agent-switcher-label">
    <label class="agent-switcher__option">
      <input type="radio" name="home-agent" value="cursor" data-agent-id="cursor" data-install-root="~/.cursor" data-install-hint="Typical install path: ~/.cursor (Windows: %USERPROFILE%\.cursor)" checked />
      <span>Cursor</span>
    </label>
    <label class="agent-switcher__option">
      <input type="radio" name="home-agent" value="claude" data-agent-id="claude" data-install-root="~/.claude" data-install-hint="Typical install path: ~/.claude (Windows: %USERPROFILE%\.claude)" />
      <span>Claude Code</span>
    </label>
    <label class="agent-switcher__option">
      <input type="radio" name="home-agent" value="copilot" data-agent-id="copilot" data-install-root="~/.copilot" data-install-hint="Typical install path (user mode): ~/.copilot (Windows: %USERPROFILE%\.copilot)" />
      <span>GitHub Copilot</span>
    </label>
    <label class="agent-switcher__option">
      <input type="radio" name="home-agent" value="codex" data-agent-id="codex" data-install-root="~/.codex" data-install-hint="Typical install path: ~/.codex (plugin skills under plugin/; optional USER skills ~/.agents/skills with -UserScope)" />
      <span>Codex</span>
    </label>
    <label class="agent-switcher__option">
      <input type="radio" name="home-agent" value="antigravity" data-agent-id="antigravity" data-install-root="~/.gemini" data-install-hint="Typical install path: ~/.gemini (Windows: %USERPROFILE%\.gemini)" />
      <span>Antigravity</span>
    </label>
    <label class="agent-switcher__option">
      <input type="radio" name="home-agent" value="opencode" data-agent-id="opencode" data-install-root="~/.config/opencode" data-install-hint="Typical install path: ~/.config/opencode (Windows: %USERPROFILE%\.config\opencode)" />
      <span>OpenCode</span>
    </label>
    <label class="agent-switcher__option">
      <input type="radio" name="home-agent" value="grok" data-agent-id="grok" data-install-root="~/.grok" data-install-hint="Typical install path: ~/.grok (Windows: %USERPROFILE%\.grok)" />
      <span>Grok Build</span>
    </label>
    <label class="agent-switcher__option">
      <input type="radio" name="home-agent" value="zcode" data-agent-id="zcode" data-install-root="~/.zcode" data-install-hint="Typical install path: ~/.zcode (Windows: %USERPROFILE%\.zcode)" />
      <span>ZCode</span>
    </label>
    <label class="agent-switcher__option">
      <input type="radio" name="home-agent" value="hermes" data-agent-id="hermes" data-install-root="~/.hermes" data-install-hint="Typical install path: ~/.hermes (Windows: %USERPROFILE%\.hermes)" />
      <span>Hermes</span>
    </label>
    <label class="agent-switcher__option">
      <input type="radio" name="home-agent" value="openhands" data-agent-id="openhands" data-install-root="~/.agents" data-install-hint="Typical install: project .agents/skills; live user ~/.agents/skills (Windows: %USERPROFILE%\.agents\skills)" />
      <span>OpenHands</span>
    </label>
  </div>
  <p id="agent-install-hint" class="agent-switcher__hint" role="status" aria-live="polite" data-agent-install-hint>
    Typical install path: ~/.cursor (Windows: %USERPROFILE%\.cursor)
  </p>
</div>

<div class="home-cta">
  <div class="home-cta__copy">
    <code id="sync-command" data-sync-command>curl.exe -fsSL -o bootstrap.bat https://github.com/tibursocampos/agent-dev-toolkit/releases/latest/download/bootstrap.bat</code>
    <button type="button" class="home-cta__primary" id="copy-sync-command" data-copy-target="#sync-command" aria-describedby="copy-sync-status">
      Copy bootstrap download
    </button>
    <span id="copy-sync-status" class="home-cta__status" role="status" aria-live="polite" data-copy-status></span>
  </div>
  <a class="home-cta__secondary md-button" href="get-started/">Get started</a>
  <p class="home-cta__script">
    Then run <code>bootstrap.bat</code> (opens Smart Manager). Scripting after extract: <code id="sync-script-command" data-sync-script-command>pwsh -NoProfile -File .\bootstrap.ps1 -DirectSync -Agent cursor</code>
  </p>
  <p class="home-cta__note">Recommended: Release bootstrap (HTTPS zip → SHA256 → extract → <code>toolkit.ps1</code>). No Git / <code>gh</code> / Node / <code>.exe</code>. Requires <strong>pwsh 7+</strong> on Linux/macOS; Windows: PowerShell 5.1+ or pwsh 7+. Linux/macOS: download <code>bootstrap.ps1</code> or <code>bootstrap.sh</code> from the same Release. Clone is optional — see <a href="get-started/">Get started</a>. Live sync needs <code>-AllowUserHome</code>.</p>
</div>

</div>

## Without the agent switcher

Works with JavaScript disabled.

1. **Download and run Release bootstrap** (no clone). Requires **pwsh 7+** on Linux/macOS (Windows: 5.1+ or pwsh 7+) — see [Get started](get-started/).

   ```bat
   curl.exe -fsSL -o bootstrap.bat https://github.com/tibursocampos/agent-dev-toolkit/releases/latest/download/bootstrap.bat
   bootstrap.bat
   ```

   ```powershell
   curl.exe -fsSL -o bootstrap.ps1 https://github.com/tibursocampos/agent-dev-toolkit/releases/latest/download/bootstrap.ps1
   pwsh -NoProfile -File .\bootstrap.ps1
   ```

2. **Alternative — clone** the repo and open Smart Manager:

   ```powershell
   git clone https://github.com/tibursocampos/agent-dev-toolkit.git agent-dev-toolkit
   cd agent-dev-toolkit
   pwsh -NoProfile -File .\scripts\toolkit.ps1
   ```

3. **Optional — non-interactive sync** (fixture first; add `-InstallRoot` and `-AllowUserHome` for a live install path). Advanced: `scripts/sync-agent.ps1`, or bootstrap `-DirectSync`.

   ```powershell
   pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent cursor
   ```

## Supported agents

| Agent id | Display name | Typical install root | Notes |
|----------|--------------|----------------------|-------|
| `cursor` | Cursor | `~/.cursor` | Path/secrets hooks; agents roster |
| `antigravity` | Antigravity | `~/.gemini` | PreToolUse under `config/hooks` |
| `claude` | Claude Code | `~/.claude` | PreToolUse path/secrets |
| `codex` | Codex | `~/.codex` (plugin; optional USER `~/.agents/skills` via `-UserScope`) | PreToolUse; `agents/*.toml` |
| `copilot` | GitHub Copilot | `~/.copilot` | hooks `version:1` preToolUse |
| `opencode` | OpenCode | `~/.config/opencode` | JS path/secrets; agents publish |
| `grok` | Grok Build | `~/.grok` | PreToolUse; agents publish |
| `zcode` | ZCode | `~/.zcode` | PreToolUse |
| `hermes` | Hermes | `~/.hermes` | Plugin + shell path/secrets hooks |
| `openhands` | OpenHands | Project `.agents/skills`; live user `~/.agents/skills` | `guard_pre_tool.sh` fail-closed |

<nav class="home-secondary-links" aria-label="Secondary">
  <a href="using-skills/">Skills</a>
  <a href="caveman/">Caveman</a>
  <a href="adapters/">Adapters</a>
  <a href="credits/">Credits</a>
</nav>
