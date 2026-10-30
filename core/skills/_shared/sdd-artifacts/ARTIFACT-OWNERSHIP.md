# Inventário de autoridade e ciclo de vida dos artefatos SDD

Esta página é um índice de navegação e responsabilidade para os artefatos que os fluxos consomem. Ela não substitui nem replica os contratos especializados. Em divergência, prevalece a fonte normativa indicada na linha; o consumidor deve registrar a divergência e não inferir sucesso, autoridade ou migração.

## Como resolver destino e contexto

- Artefatos de feature seguem `STORAGE.md` e `STORAGE-RESOLUTION.md`: `repository` resolve em `$Cwd/features/NNN-slug/`; `global` resolve em `<classic.path>/features/NNN-slug/`, co-localizado com `memory-bank/`. `features_versioned` controla versionamento, não descoberta nem existência. Citações persistidas usam caminhos portáteis.
- Nos exemplos de caminho com `USnn`, use `TSnn` no lugar quando o item for Technical Story.
- Estado operacional de sessão e claims não é colocado na árvore `features/` nem escolhido por `manifest.json`: usa o `sessions` da raiz SDD da instalação ativa, conforme `SESSION.md` e `PLAN-LEDGER-CONTRACT.md`.
- `direct` e `orchestrated` são contextos de invocação explícitos. A presença de FEATURE/STORY/CONTINUITY/checklist não muda o contexto; ver `INVOCATION-CONTEXTS.md`.
- Proprietário indica quem pode criar/atualizar a fonte no fluxo descrito. Consumidores podem ler e validar, mas isso não transfere a propriedade da escrita.

## Matriz

The artifact matrix (type, authority, writer, consumers, lifecycle) lives in `ARTIFACT-OWNERSHIP-MATRIX.md`. Read it when deciding who owns or writes an artifact.

## Lacunas observadas

- O contrato de armazenamento define localização e presença de `ANALYSIS/`, `ARCH/` e `SEC/`, e o roster define papéis de escrita; não foi identificado um contrato comum de retenção, atualização e obsolescência para essas notas.
- O recibo normativo define forma, validação e transporte de handoff, mas não define arquivo/caminho canônico de persistência para todas as classes de receipt. Um retorno de sessão não deve ser tratado automaticamente como artefato durável.
- `STORY.md` pode ser escrito por síntese O1 ou refinamento direto conforme contexto; a autoridade e relação com PRD precisam permanecer explícitas quando os dois coexistem.
- Sessão, claim, receipt e PLAN guardam dimensões distintas, embora repitam referências de passo/resultado. Não há equivalência automática entre gate humano, lock, execução, resultado de validação e handoff.

## Related

| Relação | Path portátil |
|---------|---------------|
| Armazenamento e manifest | `core/skills/_shared/sdd-artifacts/STORAGE.md` |
| Resolução dinâmica de armazenamento | `core/skills/_shared/sdd-artifacts/STORAGE-RESOLUTION.md` |
| Contexto de invocação | `core/skills/_shared/sdd-artifacts/INVOCATION-CONTEXTS.md` |
| Sessões e gates | `core/skills/_shared/sdd-artifacts/SESSION.md` |
| Claim do PLAN | `core/skills/_shared/sdd-artifacts/PLAN-LEDGER-CONTRACT.md` |
| EVD e STATE | `core/skills/_shared/sdd-artifacts/EVD-STATE-CONTRACT.md` |
| TRACE e archive | `core/skills/_shared/sdd-artifacts/TRACE-ARCHIVE-CONTRACT.md` |
| CHANGE | `core/skills/_shared/sdd-artifacts/CHANGE-CONTRACT.md` |
| Recibos | `core/skills/_shared/agents/RECEIPT.md` |
| Pipeline e consumidores | `core/skills/_shared/sdd-artifacts/PIPELINE.md` |
