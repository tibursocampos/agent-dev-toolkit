---
title: Início
hide:
  - navigation
  - toc
---

!!! warning "Rascunho (pt-BR)"
    Esta página em português é um **rascunho**. O conteúdo completo ainda está em elaboração; a versão em inglês permanece a referência canônica por enquanto.

<div class="home-hero">

<p class="home-brand">agent-dev-toolkit</p>

<h1 class="home-headline">Um núcleo de skills. Oito lares de agentes.</h1>

<p class="home-lead">Sincronize skills compartilhadas pelos adapters com um comando PowerShell—escolha o agente, copie o caminho, invoque.</p>

<div class="home-cta">
  <a class="md-button md-button--primary" href="get-started.md">Começar</a>
  <div class="home-cta__copy">
    <code id="sync-command" data-sync-command>pwsh -NoProfile -File .\scripts\toolkit.ps1</code>
    <button type="button" class="md-button" id="copy-sync-command" data-copy-target="#sync-command" aria-describedby="copy-sync-status">
      Copiar comando de sync
    </button>
    <span id="copy-sync-status" class="home-cta__status" role="status" aria-live="polite" data-copy-status></span>
  </div>
</div>

<figure class="home-diagram">
  <img src="assets/core-adapters-diagram.svg" width="960" height="320" alt="Skills do núcleo fluem pelos adapters até os lares dos agentes" />
</figure>

<div
  class="agent-switcher"
  id="agent-switcher"
  role="radiogroup"
  aria-label="Agente de destino"
  data-agent-switcher
  data-default-agent="cursor"
>
  <p class="agent-switcher__label" id="agent-switcher-label">Escolha um agente</p>
  <div class="agent-switcher__options" role="presentation">
    <label class="agent-switcher__option">
      <input type="radio" name="home-agent" value="cursor" data-agent-id="cursor" data-install-root="~/.cursor" data-install-hint="Raiz típica em uso: ~/.cursor (Windows: %USERPROFILE%\.cursor)" checked />
      <span>Cursor</span>
    </label>
    <label class="agent-switcher__option">
      <input type="radio" name="home-agent" value="antigravity" data-agent-id="antigravity" data-install-root="~/.gemini" data-install-hint="Raiz típica em uso: ~/.gemini (Windows: %USERPROFILE%\.gemini)" />
      <span>Antigravity</span>
    </label>
    <label class="agent-switcher__option">
      <input type="radio" name="home-agent" value="claude" data-agent-id="claude" data-install-root="~/.claude" data-install-hint="Raiz típica em uso: ~/.claude (Windows: %USERPROFILE%\.claude)" />
      <span>Claude Code</span>
    </label>
    <label class="agent-switcher__option">
      <input type="radio" name="home-agent" value="codex" data-agent-id="codex" data-install-root="~/.codex" data-install-hint="Raiz típica em uso: ~/.codex (skills de usuário também em ~/.agents/skills)" />
      <span>Codex</span>
    </label>
    <label class="agent-switcher__option">
      <input type="radio" name="home-agent" value="copilot" data-agent-id="copilot" data-install-root="~/.copilot" data-install-hint="Raiz típica em uso (modo usuário): ~/.copilot (Windows: %USERPROFILE%\.copilot)" />
      <span>GitHub Copilot</span>
    </label>
    <label class="agent-switcher__option">
      <input type="radio" name="home-agent" value="opencode" data-agent-id="opencode" data-install-root="~/.config/opencode" data-install-hint="Raiz típica em uso: ~/.config/opencode (Windows: %USERPROFILE%\.config\opencode)" />
      <span>OpenCode</span>
    </label>
    <label class="agent-switcher__option">
      <input type="radio" name="home-agent" value="grok" data-agent-id="grok" data-install-root="~/.grok" data-install-hint="Raiz típica em uso: ~/.grok (Windows: %USERPROFILE%\.grok)" />
      <span>Grok Build</span>
    </label>
    <label class="agent-switcher__option">
      <input type="radio" name="home-agent" value="zcode" data-agent-id="zcode" data-install-root="~/.zcode" data-install-hint="Raiz típica em uso: ~/.zcode (Windows: %USERPROFILE%\.zcode)" />
      <span>ZCode</span>
    </label>
  </div>
  <p id="agent-install-hint" class="agent-switcher__hint" role="status" aria-live="polite" data-agent-install-hint>
    Raiz típica em uso: ~/.cursor (Windows: %USERPROFILE%\.cursor)
  </p>
</div>

</div>

<nav class="home-secondary-links" aria-label="Secundário">
  <a href="using-skills.md">Skills</a>
  <a href="adapters.md">Adaptadores</a>
</nav>
