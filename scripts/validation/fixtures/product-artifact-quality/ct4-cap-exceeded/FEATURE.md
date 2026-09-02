# FEATURE: Synthetic maturity cap exceeded (CT4)

| Campo | Valor |
|-------|--------|
| **Id** | `998-synthetic-paq-ct4` |
| **Path** | `scripts/validation/fixtures/product-artifact-quality/ct4-cap-exceeded/` |
| **Scope** | fullstack |
| **Nature** | greenfield |
| **Complexity** | medium |
| **Status** | draft |

## Problem

Synthetic fixture: backlog proposals sometimes shatter into too many US without split rationale.

## Goals

- Keep Product Initiative backlog within maturity cap unless rationale is explicit

## Non-goals

- Real client portfolios
- Auto-merge of unrelated domains

## Evidence

| Campo | Valor |
|-------|--------|
| **Evidence** | omitted — none yet |

## Resumo

Synthetic CT4 — five US rows without a feature-level exception for the maturity limit.

## Historias

| Id | Tipo | Título | Rationale | Product intent | Status |
|----|------|--------|-----------|----------------|--------|
| US01 | US | Operators see gate A | Slice A | Who: ops / Job: review / Outcome: depth gate runs | draft |
| US02 | US | Operators see gate B | Slice B | Who: ops / Job: review / Outcome: promotion gate runs | draft |
| US03 | US | Operators see gate C | Slice C | Who: ops / Job: review / Outcome: cap gate runs | draft |
| US04 | US | Operators see AC budget | Slice D | Who: ops / Job: review / Outcome: AC budget checked | draft |
| US05 | US | Operators see evidence omit | Slice E | Who: ops / Job: review / Outcome: omit accepted | draft |

## Flags (`needs_*`)

| Flag | Valor |
|------|-------|
| needs_api | false |
| needs_domain | false |
| needs_database | false |
| needs_frontend | false |
| needs_security | false |
| needs_devops | false |
