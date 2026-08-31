## Report template (pt-BR)

```markdown
# Relatório de cobertura - [nome da feature ou branch]

## Artefatos no disco

- `TestResults/CoverageReport/Summary.txt`
- `TestResults/CoverageReport/index.html`
- `TestResults/.../coverage.cobertura.xml` - [caminho exato encontrado]

## Resumo

| Métrica | Valor | Status |
|---------|-------|--------|
| Cobertura em código novo (arquivos alterados) | [X%] | Passou ≥ [threshold]% / Abaixo do target |
| Cobertura geral (branch) | [Y%] | Informativo |
| Threshold | [80]% (mínimo) |
| Meta | 100% |
| Decisão | **Aprovado** / **Reprovado** |

**Branch:** [feature/...]  
**Base:** [main|develop]  
**Testes:** [projeto(s) executado(s)]  
**Limitações:** [Nenhuma | ex.: filtro de testes, coverlet ausente corrigido, etc.]

---

## Código novo (arquivos alterados)

| Arquivo | Linhas cobertas | Cobertura | vs meta 100% |
|---------|-----------------|-----------|--------------|
| `src/.../Handler.cs` | [n/m] | [X%] | OK / Gap |

**Agregado (new code):** [X%]

---

## Cobertura geral (branch)

[Colar linha relevante de Summary.txt ou resumo ReportGenerator]

---

## Lacunas (quando abaixo do threshold ou &lt; 100%)

### `src/.../Service.cs` - [X%]

- Métodos / linhas sem cobertura: [listar quando identificável]
- Sugestão: testes `Should_<Result>_When_<Condition>` em [TestProject]

---

## Bloco para code-review (colar se Pass)

```text
Cobertura validada via test-coverage:
- New code: [X%] (≥ [threshold]%)
- Branch overall: [Y%]
- Meta 100%: [N] arquivo(s) abaixo - documentado acima
```

---

## Próximos passos

- [ ] `/code-review` (se Pass)
- [ ] `/developer` / `sdd-develop` - adicionar testes (se Fail)
- [ ] Re-executar `/test-coverage` após novos testes
```

---
