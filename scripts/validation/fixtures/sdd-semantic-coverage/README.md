# Corpus de cobertura semântica SDD — Feature 018

Este corpus registra controles documentais para CT1–CT13 da Feature 018. Ele reúne quatro grupos de comportamento do PLAN e não simula uma chamada de modelo, não produz PRD/PLAN por skill e não cria estado operacional.

## Uso

Da raiz do repositório:

```powershell
pwsh -NoProfile -File scripts/validation/Assert-SddSemanticCoverage.ps1
```

O assert valida somente integridade do corpus: schema, IDs CT1–CT13, grupos G1–G4, sintaxe portátil dos caminhos, existência das fontes versionadas, controles positivo/negativo e os ramos CT12/CT13. Referências sob `features/` são locais ao workspace porque esse diretório é ignorado; quando presentes, o assert confirma que são arquivos, e quando ausentes em um checkout limpo, registra-as como indisponíveis sem falhar a integridade estrutural. A saída informa as contagens e não afirma que todas as fontes ou evidências estejam presentes ou tenham sido semanticamente revalidadas. `ObjectiveCorpusRecord: PASS` não significa que o texto avaliado seja semanticamente correto. Cada veredito semântico é mantido como dado de revisão manual e comparado às fontes indicadas; o controle contraditório CT3 deve continuar com veredito `FAIL`, embora IDs e links sejam válidos.

## Grupos e fontes

| Grupo | Cenários | Fronteira avaliada | Fonte principal |
|-------|----------|-------------------|-----------------|
| G1 | CT1–4 e CT6 | Fonte/decisão → FEATURE/STORY/PRD; CT2 inclui regra/falha no split | PRD §10; `EVD/s2-o1-decomposition.md`; `EVD/s3-prd-semantic-review.md` |
| G2 | CT5, CT10 e CT11 | Saída/artefato atual → decisão de avanço O2 | PRD §10; `EVD/s5-o2-reconciliation-review.md` |
| G3 | CT7–9 | Pesquisa no repositório → PLAN | PRD §10; `EVD/s4-plan-evidence-review.md` |
| G4 | CT12–13 | Contexto e gates por modo | PRD §10; `EVD/s3-prd-semantic-review.md`, `EVD/s4-plan-evidence-review.md`, `EVD/s5-o2-reconciliation-review.md` |

O corpus mantém separadas a decisão esperada, a checagem objetiva do registro e a revisão semântica. Fontes S2–S5 são evidências de inspeção estática e controles sintéticos registrados; nenhuma saída live foi gerada. Este trecho registra o snapshot de S6: CT12/CT13 tinham revisão por ramo, enquanto a composição integrada estava `PENDING` naquele checkpoint. O registro da avaliação integrada final de S8 é local ao workspace em `features/018-deepen-sdd-discovery-planning/US01/EVD/s8-integrated-review.md`; como `features/` é ignorado, ele pode estar indisponível em um checkout limpo. CT14/CT15 ficam fora deste escopo S6 e seguem para S7/S8.

## Limites

- V5 demonstra fixtures executadas de identidade/storage/contexto, não suficiência semântica do conteúdo.
- V6 reusa os casos relevante/decoy/ausência/conflito do seletivo; seus três casos não cobrem a Feature 018.
- O novo assert detecta corpus incompleto ou malformado; não decide semântica e não converte exemplos estáticos em runtime.
- Classes de evidência e limites por CT estão em `cases.json` e em `features/018-deepen-sdd-discovery-planning/US01/EVD/s6-adversarial-corpus-review.md`.
