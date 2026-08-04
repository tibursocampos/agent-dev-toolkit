# Modo Caveman

Compressão **opcional** das respostas do agente após o sync. Comprime o estilo, não a substância. Não altera sync nem validação.

Inspirado em [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman) — este toolkit entrega um **contrato/preferências portátil**, não um port completo. Ver [Créditos](../credits/).

## Default

**OFF.** Preferências em `{{SDD_ROOT}}/preferences.json` após o sync (`caveman_mode`, `caveman_level`).

## Ativar / desativar

| Comando | Efeito |
|---------|--------|
| `caveman on` | Liga |
| `caveman off` | Desliga |
| `caveman status` | Mostra on/off + level |
| `caveman lite` \| `full` \| `ultra` | Define level (liga se estava off) |
| `stop caveman` / `normal mode` | Igual a off |

## Níveis e caps

- **lite** — frases completas, sem enrolação  
- **full** — default quando ON; fragmentos OK  
- **ultra** — compressão máxima  

Skills podem limitar a intensidade (planejamento costuma ser Lite; develop Full). **NEVER** comprimir em `help-skills`, `commit`, `push`, `open-github-pr`.

## Auto-Clarity

Suspende a compressão em avisos de segurança, confirmações irreversíveis, sequências multi-passo ambíguas ou quando o usuário pede esclarecimento — depois retoma.

## Quando usar

Prefira ON em review longa / orquestração. Prefira OFF em Q&A curta (carregar o contrato tem custo).

Guia completo: [docs/guides/07-caveman-mode.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/guides/07-caveman-mode.md) · contrato: `core/skills/_shared/caveman/CAVEMAN.md`.

Próximo: [Usando skills](../using-skills/) · [Créditos](../credits/) · [Início](../)
