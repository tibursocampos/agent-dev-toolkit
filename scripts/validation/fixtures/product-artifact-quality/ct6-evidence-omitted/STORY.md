# STORY: US01 - Honest Evidence omission accepted (synthetic CT6)

| Campo | Valor |
|-------|--------|
| **Id** | US01 |
| **Tipo** | US |
| **Feature** | `scripts/validation/fixtures/product-artifact-quality/ct6-evidence-omitted/` |
| **Path** | `scripts/validation/fixtures/product-artifact-quality/ct6-evidence-omitted/` |
| **Status** | draft |

## Objective

Scorecard accepts honest Evidence omission on a synthetic STORY without forcing fabricated signals.

## Who / Job / Outcome (US)

| Campo | Valor |
|-------|--------|
| **Who** | Toolkit operator (synthetic) |
| **Job** | Score product depth without inventing Evidence |
| **Outcome** | Omission is accepted; fabrication is not required |

## Descrição

Synthetic CT6 — Evidence marked omitted. No real client data (RNF-001).

## Fora de escopo (OOS)

| Item | Motivo |
|------|--------|
| Fabricated persona quotes | product-evidence-lite omit > fabricate |

## Critérios de aceite (AC budget)

### Happy

```gherkin
Given a STORY with Evidence omitted — none yet
When the Assert evaluates evidence-lite
Then honest omission is accepted without a Product depth failure
```

### Rule / edge

```gherkin
Given a complete AC budget (happy/rule/failure)
When the Assert evaluates Product depth
Then the minimum band is met even without fabricated Evidence
```

### Failure

```gherkin
Given pressure to invent client metrics
When the Assert and scorecard apply evidence-lite
Then fabrication is not required and the fixture stays free of PII
```

## Scorecard (resumo)

| Critério | Nota (1-5) | Nota |
|----------|------------|------|
| Clareza | 4 | Clear omit rule |
| Testabilidade | 4 | Three scenarios |
| Dependências | 4 | None |
| Product depth | 4 | Valuable + AC; Evidence omit OK |

## Evidence

| Campo | Valor |
|-------|--------|
| **Evidence** | omitted — none yet |
