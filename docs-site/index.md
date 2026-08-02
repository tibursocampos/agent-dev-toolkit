---
title: Home
hide:
  - navigation
  - toc
---

<div class="home-hero">

<p class="home-brand reveal reveal--brand">agent-dev-toolkit</p>

<h1 class="home-headline">One skills core. Eight agent homes.</h1>

<p class="home-lead">Sync shared skills through adapters with one PowerShell command—pick your agent, copy the path, invoke.</p>

<figure class="home-diagram reveal reveal--diagram">
  <img src="assets/core-adapters-diagram.svg" width="960" height="320" alt="Core skills flow through adapters into agent homes" />
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
      <input type="radio" name="home-agent" value="cursor" data-agent-id="cursor" data-install-root="~/.cursor" data-install-hint="Typical live root: ~/.cursor (Windows: %USERPROFILE%\.cursor)" checked />
      <span>Cursor</span>
      <span class="agent-switcher__badge">Recommended</span>
    </label>
  </div>
  <details class="agent-switcher__others">
    <summary>Other agents</summary>
    <div class="agent-switcher__options" role="presentation">
      <label class="agent-switcher__option">
        <input type="radio" name="home-agent" value="claude" data-agent-id="claude" data-install-root="~/.claude" data-install-hint="Typical live root: ~/.claude (Windows: %USERPROFILE%\.claude)" />
        <span>Claude Code</span>
      </label>
      <label class="agent-switcher__option">
        <input type="radio" name="home-agent" value="copilot" data-agent-id="copilot" data-install-root="~/.copilot" data-install-hint="Typical live root (user mode): ~/.copilot (Windows: %USERPROFILE%\.copilot)" />
        <span>GitHub Copilot</span>
      </label>
      <label class="agent-switcher__option">
        <input type="radio" name="home-agent" value="codex" data-agent-id="codex" data-install-root="~/.codex" data-install-hint="Typical live root: ~/.codex (USER skills also under ~/.agents/skills)" />
        <span>Codex</span>
      </label>
    </div>
    <details class="agent-switcher__more">
      <summary>More agents</summary>
      <div class="agent-switcher__options" role="presentation">
        <label class="agent-switcher__option">
          <input type="radio" name="home-agent" value="antigravity" data-agent-id="antigravity" data-install-root="~/.gemini" data-install-hint="Typical live root: ~/.gemini (Windows: %USERPROFILE%\.gemini)" />
          <span>Antigravity</span>
        </label>
        <label class="agent-switcher__option">
          <input type="radio" name="home-agent" value="opencode" data-agent-id="opencode" data-install-root="~/.config/opencode" data-install-hint="Typical live root: ~/.config/opencode (Windows: %USERPROFILE%\.config\opencode)" />
          <span>OpenCode</span>
        </label>
        <label class="agent-switcher__option">
          <input type="radio" name="home-agent" value="grok" data-agent-id="grok" data-install-root="~/.grok" data-install-hint="Typical live root: ~/.grok (Windows: %USERPROFILE%\.grok)" />
          <span>Grok Build</span>
        </label>
        <label class="agent-switcher__option">
          <input type="radio" name="home-agent" value="zcode" data-agent-id="zcode" data-install-root="~/.zcode" data-install-hint="Typical live root: ~/.zcode (Windows: %USERPROFILE%\.zcode)" />
          <span>ZCode</span>
        </label>
      </div>
    </details>
  </details>
  <p id="agent-install-hint" class="agent-switcher__hint" role="status" aria-live="polite" data-agent-install-hint>
    Typical live root: ~/.cursor (Windows: %USERPROFILE%\.cursor)
  </p>
</div>

<div class="home-cta">
  <div class="home-cta__copy">
    <code id="sync-command" data-sync-command>pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent cursor</code>
    <button type="button" class="home-cta__primary" id="copy-sync-command" data-copy-target="#sync-command" aria-describedby="copy-sync-status">
      Copy sync command
    </button>
    <span id="copy-sync-status" class="home-cta__status" role="status" aria-live="polite" data-copy-status></span>
  </div>
  <a class="home-cta__secondary md-button" href="get-started/">Get started</a>
  <p class="home-cta__note">Safe default uses a fixture (a safe test folder)—omit <code>-InstallRoot</code>. Writing to a live agent home needs <code>-AllowUserHome</code>.</p>
</div>

</div>

## Get going without the switcher

Works with JavaScript disabled.

1. **Clone** the repo and `cd` into it.
2. **Open the Smart Manager** (interactive menu — agent/target wizards):

   ```powershell
   pwsh -NoProfile -File .\scripts\toolkit.ps1
   ```

3. **Or sync non-interactively** (fixture-first; add `-InstallRoot` and `-AllowUserHome` for a live home):

   ```powershell
   pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent cursor
   ```

## Supported agents

| Agent id | Display name | Typical install root |
|----------|--------------|----------------------|
| `cursor` | Cursor | `~/.cursor` |
| `antigravity` | Antigravity | `~/.gemini` |
| `claude` | Claude Code | `~/.claude` |
| `codex` | Codex | `~/.codex` |
| `copilot` | GitHub Copilot | `~/.copilot` |
| `opencode` | OpenCode | `~/.config/opencode` |
| `grok` | Grok Build | `~/.grok` |
| `zcode` | ZCode | `~/.zcode` |

<nav class="home-secondary-links" aria-label="Secondary">
  <a href="using-skills/">Skills</a>
  <a href="adapters/">Adapters</a>
</nav>
