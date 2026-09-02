# FEATURE: Synthetic incomplete FEATURE depth (CT1)

| Campo | Valor |
|-------|--------|
| **Id** | `998-synthetic-paq-ct1` |
| **Path** | `scripts/validation/fixtures/product-artifact-quality/ct1-feature-incomplete/` |
| **Scope** | fullstack |
| **Nature** | greenfield |
| **Complexity** | medium |
| **Status** | draft |

## Problem

Synthetic fixture: operators cannot detect thin FEATURE drafts that omit Goals.

## Non-goals

- Real client or production data in fixtures
- Shipping CREDITS in this fixture

## Evidence

| Campo | Valor |
|-------|--------|
| **Evidence** | omitted — none yet |

## Resumo

Synthetic CT1 — Goals intentionally absent so Assert names the missing field.

## Histórias

| Id | Tipo | Título | Rationale | Product intent | Status |
|----|------|--------|-----------|----------------|--------|
| US01 | US | Operators see missing Goals named | Vertical outcome slice | Who: ops / Job: review drafts / Outcome: incomplete FEATURE rejected | draft |

## Flags (`needs_*`)

| Flag | Valor |
|------|-------|
| needs_api | false |
| needs_domain | false |
| needs_database | false |
| needs_frontend | false |
| needs_security | false |
| needs_devops | false |
