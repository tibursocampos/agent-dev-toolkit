---
title: Início
hide:
  - navigation
  - toc
---

<div class="home-hero">

<p class="home-brand reveal reveal--brand">agent-dev-toolkit</p>

<h1 class="home-headline">Um núcleo compartilhado de skills. Oito ambientes de agente.</h1>

<p class="home-lead">Sincronize skills compartilhadas via adaptadores com um comando PowerShell — escolha o agente, copie o comando de sync e execute.</p>

<figure class="home-diagram reveal reveal--diagram">
  <img src="assets/core-adapters-diagram.svg" width="960" height="320" alt="Skills do núcleo fluem pelos adaptadores até a pasta de instalação de cada agente" />
</figure>

<div
  class="agent-switcher reveal reveal--switcher"
  id="agent-switcher"
  data-agent-switcher
  data-default-agent="cursor"
>
  <p class="agent-switcher__label" id="agent-switcher-label">Escolha um agente</p>
  <div class="agent-switcher__options" role="radiogroup" aria-labelledby="agent-switcher-label">
    <label class="agent-switcher__option">
      <input type="radio" name="home-agent" value="cursor" data-agent-id="cursor" data-install-root="~/.cursor" data-install-hint="Pasta de instalação real típica: ~/.cursor (Windows: %USERPROFILE%\.cursor)" checked />
      <span>Cursor</span>
    </label>
  </div>
  <details class="agent-switcher__others">
    <summary>Outros agentes</summary>
    <div class="agent-switcher__options" role="presentation">
      <label class="agent-switcher__option">
        <input type="radio" name="home-agent" value="claude" data-agent-id="claude" data-install-root="~/.claude" data-install-hint="Pasta de instalação real típica: ~/.claude (Windows: %USERPROFILE%\.claude)" />
        <span>Claude Code</span>
      </label>
      <label class="agent-switcher__option">
        <input type="radio" name="home-agent" value="copilot" data-agent-id="copilot" data-install-root="~/.copilot" data-install-hint="Pasta de instalação real típica (modo usuário): ~/.copilot (Windows: %USERPROFILE%\.copilot)" />
        <span>GitHub Copilot</span>
      </label>
      <label class="agent-switcher__option">
        <input type="radio" name="home-agent" value="codex" data-agent-id="codex" data-install-root="~/.codex" data-install-hint="Pasta de instalação real típica: ~/.codex (skills do plugin em plugin/; skills USER opcionais em ~/.agents/skills com -UserScope)" />
        <span>Codex</span>
      </label>
    </div>
    <details class="agent-switcher__more">
      <summary>Mais agentes</summary>
      <div class="agent-switcher__options" role="presentation">
        <label class="agent-switcher__option">
          <input type="radio" name="home-agent" value="antigravity" data-agent-id="antigravity" data-install-root="~/.gemini" data-install-hint="Pasta de instalação real típica: ~/.gemini (Windows: %USERPROFILE%\.gemini)" />
          <span>Antigravity</span>
        </label>
        <label class="agent-switcher__option">
          <input type="radio" name="home-agent" value="opencode" data-agent-id="opencode" data-install-root="~/.config/opencode" data-install-hint="Pasta de instalação real típica: ~/.config/opencode (Windows: %USERPROFILE%\.config\opencode)" />
          <span>OpenCode</span>
        </label>
        <label class="agent-switcher__option">
          <input type="radio" name="home-agent" value="grok" data-agent-id="grok" data-install-root="~/.grok" data-install-hint="Pasta de instalação real típica: ~/.grok (Windows: %USERPROFILE%\.grok)" />
          <span>Grok Build</span>
        </label>
        <label class="agent-switcher__option">
          <input type="radio" name="home-agent" value="zcode" data-agent-id="zcode" data-install-root="~/.zcode" data-install-hint="Pasta de instalação real típica: ~/.zcode (Windows: %USERPROFILE%\.zcode)" />
          <span>ZCode</span>
        </label>
      </div>
    </details>
  </details>
  <p id="agent-install-hint" class="agent-switcher__hint" role="status" aria-live="polite" data-agent-install-hint>
    Pasta de instalação real típica: ~/.cursor (Windows: %USERPROFILE%\.cursor)
  </p>
</div>

<div class="home-cta">
  <div class="home-cta__copy">
    <code id="sync-command" data-sync-command>pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent cursor</code>
    <button type="button" class="home-cta__primary" id="copy-sync-command" data-copy-target="#sync-command" aria-describedby="copy-sync-status">
      Copiar comando de sync
    </button>
    <span id="copy-sync-status" class="home-cta__status" role="status" aria-live="polite" data-copy-status></span>
  </div>
  <a class="home-cta__secondary md-button" href="get-started/">Começar</a>
  <p class="home-cta__note">O sync padrão usa uma fixture (pasta de teste no repo)—omitir <code>-InstallRoot</code>. Uma instalação real exige <code>-AllowUserHome</code>.</p>
</div>

</div>

## Sem o seletor de agentes

Funciona com JavaScript desativado.

1. **Clone** o repositório e entre nele com `cd`.
2. **Abra o menu interativo do toolkit (Smart Manager)** (assistentes de agente/destino):

   ```powershell
   pwsh -NoProfile -File .\scripts\toolkit.ps1
   ```

3. **Ou sincronize sem interação** (fixture primeiro; adicione `-InstallRoot` e `-AllowUserHome` para uma pasta de instalação real):

   ```powershell
   pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent cursor
   ```

## Agentes suportados

| Id do agente | Nome de exibição | Pasta de instalação típica |
|--------------|------------------|----------------------------|
| `cursor` | Cursor | `~/.cursor` |
| `antigravity` | Antigravity | `~/.gemini` |
| `claude` | Claude Code | `~/.claude` |
| `codex` | Codex | `~/.codex` (plugin; USER opcional `~/.agents/skills` via `-UserScope`) |
| `copilot` | GitHub Copilot | `~/.copilot` |
| `opencode` | OpenCode | `~/.config/opencode` |
| `grok` | Grok Build | `~/.grok` |
| `zcode` | ZCode | `~/.zcode` |

<nav class="home-secondary-links" aria-label="Secundário">
  <a href="using-skills/">Usando skills</a>
  <a href="caveman/">Caveman</a>
  <a href="adapters/">Adaptadores</a>
  <a href="credits/">Créditos</a>
</nav>
