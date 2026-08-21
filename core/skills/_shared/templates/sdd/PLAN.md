# PLAN: [Nome da feature]

| Campo | Valor |
|-------|--------|
| **PRD** | [caminho portátil do PRD — `STORAGE.md` § Portable path] |
| **Repositório** | [nome do PRD / raiz git] |
| **Stack** | [.NET / Angular / outro] |
| **Complexidade** | Baixa / Média / Alta |
| **Total de passos** | N |
| **Progresso** | 0/N |
| **Track** | Classic SDD *(formerly Forma A)* / … |
| **Status** | draft / approved |

```
[⚪⚪⚪⚪⚪⚪⚪⚪] 0% (0/N)
```

## Objetivos

- [ ] O1: [Resultado mensurável ligado a REQ/CA do PRD]
- [ ] O2: [Resultado mensurável]
- [ ] O3: [Opcional]

## Árvore alvo (entregáveis)

```
[caminhos principais — só paths, sem código]
```

## Estratégia de validação

- [ ] [Como verificar — unitário, integração, script, checklist]
- [ ] Retrieval seletivo: skills tocadas não prescritem dump integral de `memory-bank/` nem do PRD (CT5 / `SELECTIVE-RETRIEVAL.md`)
- [ ] Build passa local / CI

## Mapa REQ → passo

| REQ | Passo |
|-----|-------|
| REQ-001 | PASSO … |
| REQ-002 | PASSO … |

Todo REQ do PRD deve aparecer. Aceite de cada passo cita REQ e/ou CA.

---

## Passos de implementação

### ⏳ PASSO 1: [Título curto]

**Status:** Pendente | **Concluído:** - | **Deps:** nenhuma

**Entregáveis:**

- [ ] [Artefato concreto 1]
- [ ] [Artefato concreto 2]

**Arquivos (áreas):**

- `path/to/File` (novo ou alterar)

**Aceite:**

- [ ] [CA / REQ do PRD — verificável]
- [ ] Build e testes direcionados passam (quando houver código)

**Notas:** [Riscos; aviso se passo denso]

---

### ⏳ PASSO 2: [Título curto]

**Status:** Pendente | **Concluído:** - | **Deps:** 1

[Repetir estrutura do bloco PASSO.]

---

## Ordem de execução

**Caminho crítico:** 1 -> 2 -> … -> N

**Próximo passo:** PASSO 1 - [título]

## Decisões técnicas

| Tópico | Decisão | Justificativa |
|--------|---------|---------------|
| [tópico] | [escolha] | [por quê] |

## Riscos e mitigações

| Risco | Impacto | Mitigação |
|-------|---------|-----------|
| [Risco] | Baixo/Médio/Alto | [Ação] |

## Referências

- PRD: [caminho portátil]
- Retrieval: `skills/_shared/sdd-artifacts/SELECTIVE-RETRIEVAL.md`

## Checklist final

- [ ] Todos os REQ do PRD mapeados em passos
- [ ] Cada passo cabe em uma sessão `sdd-develop`
- [ ] Dependências explícitas; sem ciclos
- [ ] Aceite por passo cita CA/REQ verificáveis
- [ ] Sem código de implementação embutido no PLAN
- [ ] Handoff: `/sdd-develop - <caminho-portátil-do-plan> - Step 1`
