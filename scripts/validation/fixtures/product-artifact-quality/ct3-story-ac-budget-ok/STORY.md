# STORY: US01 - Operators get complete AC budget feedback (synthetic CT3)

| Campo | Valor |
|-------|--------|
| **Id** | US01 |
| **Tipo** | US |
| **Feature** | `scripts/validation/fixtures/product-artifact-quality/ct3-story-ac-budget-ok/` |
| **Path** | `scripts/validation/fixtures/product-artifact-quality/ct3-story-ac-budget-ok/` |
| **Status** | draft |

## Objective

Operators receive Assert pass when a synthetic STORY meets happy + rule + failure AC budget with observable Then clauses.

## Who / Job / Outcome (US)

| Campo | Valor |
|-------|--------|
| **Who** | Toolkit operator (synthetic) |
| **Job** | Validate product artifact quality fixtures |
| **Outcome** | AC/Product depth band meets Assert minimum |

## Descrição

Synthetic golden STORY for CT3. No real client data.

## Fora de escopo (OOS)

| Item | Motivo |
|------|--------|
| CREDITS bake | Owned by PASSO 8 |
| Real tenant metrics | RNF-001 / evidence-lite |

## Critérios de aceite (AC budget)

### Happy

```gherkin
Given the golden STORY with happy, rule, and failure slots
When the product artifact quality Assert runs
Then the AC budget criterion passes with an observable result in each scenario
```

### Rule / edge

```gherkin
Given Product depth filled in the minimum band (score 3-5)
When the Assert evaluates the scorecard summary
Then the Product depth criterion meets the Assert minimum band
```

### Failure

```gherkin
Given a STORY missing the failure scenario
When the Assert evaluates the AC budget
Then the Assert fails listing the missing failure slot
```

## Scorecard (resumo)

| Critério | Nota (1-5) | Nota |
|----------|------------|------|
| Clareza | 4 | Synthetic clear objective |
| Testabilidade | 4 | Three Gherkin slots |
| Dependências | 4 | None blocking |
| Product depth | 4 | Valuable + AC budget + Who/Job/Outcome |

## Dependências

- none

## Evidence

| Campo | Valor |
|-------|--------|
| **Evidence** | omitted — none yet |
