# Classic SDD — escopo de acesso externo

Este contrato governa operações de implementação no fluxo Classic (`sdd-spec` → `sdd-plan` → `sdd-develop`). Ele é separado do contrato de armazenamento dos artefatos e das referências de evidência de O3.

## Referência portátil e escopo pedido

- Um local fora do repositório não é inválido por estar fora da raiz do workspace. Quando o operador pedir esse acesso, registre o destino como referência portátil `external:<alias>/<relative-path>` e identifique as operações solicitadas: `read`, `write` ou ambas.
- Referências internas existentes permanecem aceitas e seguem as regras atuais de path portátil.
- O PRD registra o destino e cada operação autorizada pelo operador, além do resultado e dos limites esperados. Não registre raiz física, drive, UNC, caminho absoluto, home do usuário ou segredo no PRD ou PLAN.
- Se o operador fornecer um caminho físico durante o refinamento, mantenha sua resolução para o contexto confiável da execução e represente o destino no artefato por alias portátil. Não rejeite o pedido somente por apontar para fora do repositório.
- O escopo de operação é explícito: leitura não implica escrita; escrita não implica leitura. Um pedido para ambas deve registrar ambas.

## Propagação pelo fluxo

### `sdd-spec`

Captura o destino externo pedido pelo operador, as operações solicitadas, o efeito esperado e os limites. Não inventa autorização ou mapeamento ausente e não transforma uma referência de evidência em acesso de implementação.

### `sdd-plan`

Preserva em cada passo o destino e somente as operações necessárias que já foram aprovadas no PRD. Se, durante o planejamento, o operador pedir outro destino, ampliar um caminho ou acrescentar uma operação, interrompe a aprovação do PLAN, atualiza o PRD pela `sdd-spec` e obtém nova aprovação do conteúdo do PRD antes de aprovar o PLAN. Não amplia o escopo por inferência técnica.

### `sdd-develop`

Recebe o escopo portátil do passo e, separadamente, o mapeamento explícito `alias → raiz` e a autorização de operações fornecidos pelo operador ou coordenador no contexto confiável da invocação. O mapeamento não entra nos artefatos nem em recibos. O executor não amplia destino nem operações. A execução só pode prosseguir quando o boundary de I/O efetivo puder impor esse escopo; sem enforcement verificável, retorna `BLOCKED` antes de acessar o alvo.

`{{TOOLKIT_ROOT}}/scripts/validation/fixtures/Invoke-ClassicExternalAccessFixture.ps1` é somente um fixture `validation-only`. Ele demonstra operações de leitura/escrita e representação portátil em uma raiz temporária, mas recebe contexto JSON do chamador e não comprova enforcement do provider, a origem confiável de grants, I/O sem corrida (TOCTOU), nem interceptação abrangente. Não use o fixture como autorização de produção ou como substituto para operações diretas do executor. Atualmente o toolkit não oferece um boundary de host que controle todas as operações de filesystem e shell; portanto `sdd-develop` deve bloquear antes de qualquer I/O externo até esse boundary existir e receber grants confiáveis por passo.

## Separação de evidência O3

Uma ocorrência de `external:<alias>/<relative-path>` em `files[]` de recibo O3 é somente uma referência de evidência. Ela não fornece destino autorizado, mapeamento, operação ou grant para implementação Classic. O validador de recibo O3 não substitui o boundary de I/O Classic.

## Identificadores de contrato

| ID | Regra |
|---|---|
| `CLASSIC-EXT-SCOPE` | Destinos externos pedidos são representados por referência portátil e não são recusados apenas por estarem fora do repositório. |
| `CLASSIC-EXT-OPS` | `read` e `write` são operações separadas; cada passo recebe somente as operações aprovadas e necessárias. |
| `CLASSIC-EXT-NO-ROOT` | PRD e PLAN não carregam raiz física, drive, UNC ou caminho absoluto. |
| `CLASSIC-EXT-REAPPROVAL` | Expansão solicitada durante planejamento retorna ao PRD para nova aprovação de conteúdo antes da aprovação do PLAN. |
| `CLASSIC-EXT-TRUSTED-MAP` | O alias exige mapeamento confiável fora dos artefatos; o fixture não é fonte confiável nem boundary de enforcement, e a falta de enforcement real bloqueia o acesso. |
| `CLASSIC-EXT-O3-EVIDENCE` | Referências `files[]` O3 identificam evidência e nunca autorizam leitura ou escrita Classic. |
