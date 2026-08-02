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

<div class="home-cta">
  <a class="md-button md-button--primary" href="get-started.md">Get started</a>
  <div class="home-cta__copy">
    <code id="sync-command" data-sync-command>pwsh -NoProfile -File .\scripts\toolkit.ps1</code>
    <button type="button" class="md-button" id="copy-sync-command" data-copy-target="#sync-command" aria-describedby="copy-sync-status">
      Copy sync command
    </button>
    <span id="copy-sync-status" class="home-cta__status" role="status" aria-live="polite" data-copy-status></span>
  </div>
</div>

<figure class="home-diagram reveal reveal--diagram">
  <img src="assets/core-adapters-diagram.svg" width="960" height="320" alt="Core skills flow through adapters into agent homes" />
</figure>

<div
  class="agent-switcher reveal reveal--switcher"
  id="agent-switcher"
  role="radiogroup"
  aria-label="Target agent"
  data-agent-switcher
  data-default-agent="cursor"
>
  <p class="agent-switcher__label" id="agent-switcher-label">Choose an agent</p>
  <div class="agent-switcher__options" role="presentation">
    <label class="agent-switcher__option">
      <input type="radio" name="home-agent" value="cursor" data-agent-id="cursor" data-install-root="~/.cursor" data-install-hint="Typical live root: ~/.cursor (Windows: %USERPROFILE%\.cursor)" checked />
      <span>Cursor</span>
    </label>
    <label class="agent-switcher__option">
      <input type="radio" name="home-agent" value="antigravity" data-agent-id="antigravity" data-install-root="~/.gemini" data-install-hint="Typical live root: ~/.gemini (Windows: %USERPROFILE%\.gemini)" />
      <span>Antigravity</span>
    </label>
    <label class="agent-switcher__option">
      <input type="radio" name="home-agent" value="claude" data-agent-id="claude" data-install-root="~/.claude" data-install-hint="Typical live root: ~/.claude (Windows: %USERPROFILE%\.claude)" />
      <span>Claude Code</span>
    </label>
    <label class="agent-switcher__option">
      <input type="radio" name="home-agent" value="codex" data-agent-id="codex" data-install-root="~/.codex" data-install-hint="Typical live root: ~/.codex (USER skills also under ~/.agents/skills)" />
      <span>Codex</span>
    </label>
    <label class="agent-switcher__option">
      <input type="radio" name="home-agent" value="copilot" data-agent-id="copilot" data-install-root="~/.copilot" data-install-hint="Typical live root (user mode): ~/.copilot (Windows: %USERPROFILE%\.copilot)" />
      <span>GitHub Copilot</span>
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
  <p id="agent-install-hint" class="agent-switcher__hint" role="status" aria-live="polite" data-agent-install-hint>
    Typical live root: ~/.cursor (Windows: %USERPROFILE%\.cursor)
  </p>
</div>

</div>

<nav class="home-secondary-links" aria-label="Secondary">
  <a href="using-skills.md">Skills</a>
  <a href="adapters.md">Adapters</a>
</nav>
