---
title: Início
hide:
  - navigation
  - toc
---

<div class="home-hero">

<p class="home-brand reveal reveal--brand">agent-dev-toolkit</p>

<h1 class="home-headline">Um núcleo compartilhado de skills. Adaptadores em cada pasta de agente (10 agentes).</h1>

<p class="home-lead">Sincronize skills compartilhadas via adaptadores — escolha o agente, copie o comando interativo do toolkit e execute.</p>

<figure class="home-diagram reveal reveal--diagram">
  <!-- PT pages live under /pt/; assets stay at site root — use ../assets. -->
  <img src="../assets/core-adapters-diagram.pt.svg" width="960" height="368" alt="Skills do núcleo fluem pelos adaptadores até a pasta de instalação de cada agente" />
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
    <label class="agent-switcher__option">
      <input type="radio" name="home-agent" value="hermes" data-agent-id="hermes" data-install-root="~/.hermes" data-install-hint="Pasta de instalação real típica: ~/.hermes (Windows: %USERPROFILE%\.hermes)" />
      <span>Hermes</span>
    </label>
    <label class="agent-switcher__option">
      <input type="radio" name="home-agent" value="openhands" data-agent-id="openhands" data-install-root="~/.agents" data-install-hint="Instalação típica: projeto .agents/skills; usuário live ~/.agents/skills (Windows: %USERPROFILE%\.agents\skills)" />
      <span>OpenHands</span>
    </label>
  </div>
  <p id="agent-install-hint" class="agent-switcher__hint" role="status" aria-live="polite" data-agent-install-hint>
    Pasta de instalação real típica: ~/.cursor (Windows: %USERPROFILE%\.cursor)
  </p>
</div>

<div class="home-cta">
  <div class="home-cta__copy">
    <code id="sync-command" data-sync-command>pwsh -NoProfile -File .\scripts\toolkit.ps1</code>
    <button type="button" class="home-cta__primary" id="copy-sync-command" data-copy-target="#sync-command" aria-describedby="copy-sync-status">
      Copiar comando do toolkit
    </button>
    <span id="copy-sync-status" class="home-cta__status" role="status" aria-live="polite" data-copy-status></span>
  </div>
  <a class="home-cta__secondary md-button" href="get-started/">Começar</a>
  <p class="home-cta__script">
    Script (opcional): <code id="sync-script-command" data-sync-script-command>pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent cursor</code>
  </p>
  <p class="home-cta__note">O <code>toolkit.ps1</code> interativo é a entrada de instalação. O sync não interativo usa uma fixture (pasta de teste no repo) por padrão—omitir <code>-InstallRoot</code>. Uma instalação real exige <code>-AllowUserHome</code>.</p>
</div>

</div>

## Sem o seletor de agentes

Funciona com JavaScript desativado.

1. **Clone** o repositório e entre nele com `cd`.
2. **Abra o menu interativo do toolkit (Smart Manager)** (assistentes de agente/destino):

   ```powershell
   pwsh -NoProfile -File .\scripts\toolkit.ps1
   ```

3. **Opcional — sync sem interação** (fixture primeiro; adicione `-InstallRoot` e `-AllowUserHome` para uma pasta de instalação real). Avançado: `scripts/sync-agent.ps1`.

   ```powershell
   pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent cursor
   ```

## Agentes suportados

| Id do agente | Nome de exibição | Pasta de instalação típica | Notas |
|--------------|------------------|----------------------------|-------|
| `cursor` | Cursor | `~/.cursor` | Hooks path/secrets; roster agents |
| `antigravity` | Antigravity | `~/.gemini` | PreToolUse em `config/hooks` |
| `claude` | Claude Code | `~/.claude` | PreToolUse path/secrets |
| `codex` | Codex | `~/.codex` (plugin; USER opcional `~/.agents/skills` via `-UserScope`) | PreToolUse; `agents/*.toml` |
| `copilot` | GitHub Copilot | `~/.copilot` | hooks `version:1` preToolUse |
| `opencode` | OpenCode | `~/.config/opencode` | JS path/secrets; publica agents |
| `grok` | Grok Build | `~/.grok` | PreToolUse; publica agents |
| `zcode` | ZCode | `~/.zcode` | PreToolUse |
| `hermes` | Hermes | `~/.hermes` | Plugin + shell path/secrets |
| `openhands` | OpenHands | Projeto `.agents/skills`; usuário live `~/.agents/skills` | `guard_pre_tool.sh` fail-closed |

<nav class="home-secondary-links" aria-label="Secundário">
  <a href="using-skills/">Usando skills</a>
  <a href="caveman/">Caveman</a>
  <a href="adapters/">Adaptadores</a>
  <a href="credits/">Créditos</a>
</nav>
