# O3 progress-table contract fixture

This fixture validates the one-row-per-step projection shape. It does not prove live host rendering.

## PLAN implementation progress

| Step ID | Step | Dependencies | Status | Evidence |
|---------|------|--------------|--------|----------|
| S1 | Inspect input | none | PENDING | — |
| S2 | Parse input | S1 | PENDING | — |
| S3 | Validate input | S2 | PENDING | — |
| S4 | Transform data | S3 | PENDING | — |
| S5 | Persist output | S4 | PENDING | — |
| S6 | Re-read output | S5 | PENDING | — |
| S7 | Report result | S6 | PENDING | — |

## O3 progress table

| Step ID | Step | Dependencies | Status | Checkpoint / evidence | Next action / owner |
|---------|------|--------------|--------|----------------------|---------------------|
| S1 | Inspect input | none | PENDING | — | Dispatch S1 |
| S2 | Parse input | S1 | PENDING | — | Wait for S1 |
| S3 | Validate input | S2 | PENDING | — | Wait for S2 |
| S4 | Transform data | S3 | PENDING | — | Wait for S3 |
| S5 | Persist output | S4 | PENDING | — | Wait for S4 |
| S6 | Re-read output | S5 | PENDING | — | Wait for S5 |
| S7 | Report result | S6 | PENDING | — | Wait for S6 |
