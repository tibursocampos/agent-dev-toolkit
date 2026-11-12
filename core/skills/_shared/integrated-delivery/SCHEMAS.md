# Integrated delivery block schemas

Status: experimental WP1 contract. Scope: DELIVERY operational blocks in PLAN and REFINEMENT documents. Section 9 covers the separate startup marker file.

Marker names and state semantics are defined in `EXECUTION.md`. This file defines the marker grammar, the error vocabulary, the normative projection rule, and the payload schema of each block type. Reference implementation: `scripts/_lib/DeliveryGrammar.ps1`. The same grammar must be used by every reader and writer.

## 1. Marker grammar

Canonical marker lines:

```markdown
<!-- DELIVERY:PROGRESS:BEGIN -->
<!-- DELIVERY:PROGRESS:END -->
<!-- DELIVERY:CHECKPOINT:BEGIN -->
<!-- DELIVERY:CHECKPOINT:END -->
<!-- DELIVERY:APPROVAL:BEGIN -->
<!-- DELIVERY:APPROVAL:END -->
<!-- DELIVERY:STEP:<id>:BEGIN -->
<!-- DELIVERY:STEP:<id>:END -->
```

Rules:

- `<id>` matches `^[A-Za-z0-9][A-Za-z0-9._-]*$`. Examples: `US01-S1`, `US01.S_1`.
- A line is a marker only when it starts with `<!-- DELIVERY:` at column 0 and lies outside a fenced code block. Fence rules are in section 1.1.
- A fence still open at end of text is an error (`unclosed_fence`), reported at the line of the opening fence. Markers after that fence line remain plain text.
- A recognized marker line must match the canonical pattern exactly. Leading or trailing whitespace makes it an unrecognized marker. Indented text is plain text and is not a marker.
- Lines inside a fenced code block are plain text. They are never markers, and they stay in the normative projection.
- Payload is the raw text between the BEGIN line and the END line, excluding both marker lines, with lines joined by LF. A payload must contain exactly one JSON object. A payload that is empty after trimming is `invalid_json`.
- Blocks do not nest. Each non-STEP type appears at most once. Each STEP id appears at most once. STEP ids compare case-sensitively: `US01-S1` and `us01-s1` are two different ids.
- Legacy `<!-- DELIVERY:STEP-<id>:BEGIN -->` and `<!-- DELIVERY:STEP-<id>:END -->` are rejected with `legacy_step_marker`. They are not an alias.
- Line numbers in errors are 1-based after normalization.

### 1.1 Fenced code blocks

A fence changes how the lines after it are read. The rule is CommonMark-lite:

- Opening fence: a line with 0 to 3 leading spaces, followed by 3 or more backticks or 3 or more tildes.
  - For a backtick fence, the info string after the backtick run must not contain a backtick.
  - For a tilde fence, the info string is not restricted.
- Closing fence: a line with 0 to 3 leading spaces, followed by the same character as the opener, at least as many characters as the opener, and then only spaces or tabs.
- Lines with 4 or more leading spaces are never fences, inside or outside a fence. Only spaces count as leading indentation. A line that starts with a tab is not a fence.
- While a fence is open, every line is plain text. A line that would open or close a different kind of fence does not change the state.

Example: a tilde fence that contains a marker keeps the marker as plain text.

```markdown
~~~
<!-- DELIVERY:PROGRESS:BEGIN -->
~~~
```

### Normalization

Applied before any other step, in this order:

1. Strip one leading U+FEFF (BOM).
2. Replace CRLF with LF, then any lone CR with LF.

No other normalization is applied. Trailing spaces are significant.

## 2. Read result and error codes

`Read-DeliveryBlocks -Text <string>` returns:

```text
{ Ok: bool, Errors: [ { code, message, line } ], Blocks: [ { Type, Id, Payload, Json, StartLine, EndLine } ] }
```

- `Ok` is true only when `Errors` is empty.
- `Type` is `PROGRESS`, `CHECKPOINT`, `APPROVAL`, or `STEP`.
- `Id` is set for `STEP` only and is `null` otherwise.
- `Json` is the parsed object, or `null` when the payload is not a JSON object.
- All errors are collected. Parsing does not stop at the first error.

| Code | Raised when |
|---|---|
| `unknown_marker` | A line starts with `<!-- DELIVERY:` outside a fence and does not match the grammar. |
| `legacy_step_marker` | A line starts with `<!-- DELIVERY:STEP-`. |
| `invalid_step_id` | A line starts with `<!-- DELIVERY:STEP:` and the id part fails the id pattern. |
| `duplicate_block` | A PROGRESS, CHECKPOINT, or APPROVAL block appears more than once. |
| `duplicate_step_id` | A STEP id appears more than once. The comparison is case-sensitive. |
| `nested_block` | A BEGIN marker appears while another block is open. |
| `unbalanced_block` | An END marker has no open block, or a BEGIN marker has no END marker before end of text. |
| `mismatched_end` | An END marker type or id differs from the open block. |
| `invalid_json` | The payload is empty or is not valid JSON. |
| `json_not_object` | The payload is valid JSON but not a single object (array, string, number, or `null`). |
| `missing_schema` | The object has no `schema` property (exact-case key). |
| `wrong_schema` | `schema` is a string that differs from the value for the block type (section 6). |
| `unknown_property` | The payload has a key that is not in the allowlist for its block type (section 5). Keys are matched exactly, so `SCHEMA` or `Cadence` is unknown. |
| `missing_field` | A required property is absent. A conditional property is absent when its condition holds (section 6.3). |
| `invalid_field` | A property has the wrong JSON type, a value outside its enum, or an element of the wrong type inside an array. This includes `schema` when it is present but not a string. |
| `step_id_mismatch` | A STEP block payload has no `id` property, a non-string `id`, or an `id` that differs (case-sensitive) from the marker id. |
| `unclosed_fence` | A fence opened under section 1.1 is not closed before end of text. Line is the opening fence line. |
| `steps_section_missing` | The plan has no level-2 `## Steps` heading (section 10). |
| `duplicate_declared_step` | A step id is declared by more than one step heading (section 10). |
| `step_id_invalid` | A step heading id fails the id pattern in section 1 (section 10). |
| `step_depends_missing` | A declared step has no `Depends on:` line (section 10). |
| `step_validation_missing` | A declared step has no `Validation:` line, or its text is empty (section 10). |
| `evidence_declaration_invalid` | An `Evidence:` or `Needs evidence:` line has a name that fails the slug pattern, a malformed `Needs evidence` token, a duplicate name within one step's `Evidence`, or an empty token between commas (section 10). |
| `plan_dependency_invalid` | A `## Plan dependencies` heading or `Requires plan:` line is malformed (section 10.2). |
| `refinement_item_invalid` | A refinement item ID appears more than once in one REFINEMENT.md (section 10.4). |
| `refinement_reference_invalid` | A `## Refinement references` line is malformed, a `Uses:` line appears outside that heading, or its hash is not 64 uppercase hex (section 10.4). |

Key paths: messages name the block type and the key. Nested keys use a dotted path (for example `operator_choice.choice` or `authorization.kind`). Array entries use an index (for example `repositories[0].path` or `validation_results[1].command`). `unknown_property`, `missing_field`, and `invalid_field` apply at every nesting level with the same meaning as at the top level.

Recovery behavior, which determines what `Blocks` contains:

- `duplicate_block`, `duplicate_step_id`, `missing_schema`, `wrong_schema`, `unknown_property`, `missing_field`, `invalid_field`, and `step_id_mismatch` blocks are still returned, with their parsed `Json`.
- `step_id_mismatch` is raised only when the payload is a JSON object. Otherwise the block reports its own code (`invalid_json` or `json_not_object`) only. A STEP block without an `id` property therefore reports both `missing_field` and `step_id_mismatch`.
- `unclosed_fence` makes `Ok` false. Blocks that close before the fence line are still returned. Blocks after the fence line are not parsed, because the whole text is rejected: every line after an unclosed fence is plain text. Callers must treat `Ok` false as a rejected text.
- `invalid_json` and `json_not_object` blocks are returned with `Json` set to `null`.
- `nested_block`: the outer open block is discarded and not returned. The inner block is parsed normally.
- `mismatched_end`: the open block is discarded and not returned. The END line is consumed.
- `unbalanced_block` for a BEGIN without END: the open block is not returned.
- Unrecognized DELIVERY-prefixed lines inside an open block are reported and kept in that block's payload.

## 3. Required-block rules

`Test-DeliveryRequiredBlocks -Result <Read-DeliveryBlocks output> -Kind PLAN|REFINEMENT -StepIds <string[]>` returns an array of `{ code, message }`. An empty array means the rules pass. It does not check `Ok`; call `Read-DeliveryBlocks` first and check both.

PLAN:

- Exactly one PROGRESS, one CHECKPOINT, and one APPROVAL. Zero gives `missing_block`; more than one gives `unexpected_block`.
- Exactly one STEP block per declared id. Zero gives `missing_step`; more than one gives `unexpected_block`.
- A STEP block whose id is not declared gives `undeclared_step`.

REFINEMENT:

- Exactly one APPROVAL. Zero gives `missing_block`; more than one gives `unexpected_block`.
- Any other block type gives `unexpected_block`. `StepIds` is ignored.

## 4. Normative projection and identity

`Get-DeliveryNormativeProjection -Text <string>`:

1. Normalize (section 1).
2. Read the blocks. If `Ok` is false, the function throws and the message lists the distinct error codes. An unclosed fence therefore makes the projection throw.
3. Remove every line from each block's BEGIN line through its END line, inclusive. Removing the END line also removes its newline.
4. Join the remaining lines with LF, trim trailing LF characters, and append exactly one LF.

Identity:

- `Get-DeliveryNormativeIdentity` is the uppercase SHA-256 hex of the UTF-8 bytes (no BOM) of the projection.
- `Get-DeliveryBlockHash -Payload` is the uppercase SHA-256 hex of the normalized payload with trailing LF characters trimmed.
- `Get-DeliverySha256Hex -Text` is the uppercase SHA-256 hex of UTF-8 bytes (no BOM) of the text as given.

The projection covers document text only. Declared material inputs (portable path or revision, recomputed SHA-256, role, impacted ids) are hashed by the caller. See `core/skills/integrated-delivery-review/references/review-protocol.md`. That composition is not implemented by this library.

Markers inside fenced code blocks are not removed, so they remain in the projection.

## 5. Common payload rules

- The payload is one JSON object.
- Property names are matched exactly, with case-sensitive comparison. A key that differs only by case from an allowed key is an unknown property.
- Every key must appear in the allowlist of its block type (sections 6.1 to 6.4). A key outside the allowlist is `unknown_property`.
- `schema` is required. Its value must be a JSON string equal to the block type's schema value (section 6).
- Each required property that is absent is `missing_field`. Each property with the wrong type, or a value outside its enum, is `invalid_field`. A string-typed property must hold a JSON string: a one-element array or a number in that position is `invalid_field`.
- Enum values are case-sensitive. `"SCHEMA"`, `"done"` for a STEP status, and `["delivery-progress/v1"]` for `schema` are rejected.
- All field errors of a block are collected. Each error message names the block type and the key.
- Properties marked **Required** are read by `scripts/ledger/Resolve-DeliveryExecution.ps1` or are required by this contract. Properties marked **Optional** come from `core/skills/integrated-delivery-implement/references/execution-protocol.md`. The resolver does not read them.
- Unknown keys are errors, not ignored. Operational blocks are excluded from the normative identity (section 4). A key that the library ignored could carry normative text that the identity does not cover. Adding a property therefore requires a change to this contract and to the library allowlist.
- Nested objects and arrays of objects have exact-case inner allowlists (section 6): `operator_choice`, `authorization`, `repositories` entries, `validation_results` entries, and `evidence_refs` entries. Inner keys follow the same rules as top-level keys. An unknown inner key is `unknown_property`, a wrong inner type is `invalid_field`, and an absent inner required key is `missing_field`.
- Windows PowerShell 7 `ConvertFrom-Json` converts ISO 8601 strings into `DateTime` values. The library accepts such values wherever a JSON string is required. Read timestamps from the payload text when the exact form matters.
- Timestamps are ISO 8601 in UTC (`YYYY-MM-DDTHH:MM:SSZ`). The library checks only that they are strings.
- Hashes are uppercase hex SHA-256 (64 characters). The library checks only that they are strings.

## 6. Block schemas

### 6.1 PROGRESS (`delivery-progress/v1`)

| Property | Kind | Type | Notes |
|---|---|---|---|
| `schema` | Required | string | Must be `delivery-progress/v1`. |
| `cadence` | Required | string | `step_by_step` or `continuous`. Enum, case-sensitive. The resolver requires it to equal the requested cadence. |
| `current_stage` | Optional | string | Free label of the current stage. |
| `completed` | Optional | integer | Count of COMPLETED steps. |
| `total` | Optional | integer | Count of declared steps. |
| `approval_identity` | Optional | string | Copy of the APPROVAL `identity` at write time. Informational. |
| `authorization` | Optional | object | Evidence of the cadence authorization. Inner allowlist: `kind`, `scope`, `granted_utc`, `plan_identity` (strings) and `step_ids` (array of strings). No inner key is required. Other inner keys are `unknown_property`. `scope` is optional and informational (for example `step_by_step` with kind `step`); the resolver does not validate it, and `kind` with `step_ids` carry the enforced scope. |

```json
{
  "schema": "delivery-progress/v1",
  "cadence": "step_by_step",
  "current_stage": "implementation",
  "completed": 1,
  "total": 2,
  "approval_identity": "E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855",
  "authorization": {
    "kind": "step",
    "scope": "step_by_step",
    "granted_utc": "2026-11-11T12:00:00Z",
    "plan_identity": "E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855",
    "step_ids": ["US01-S1"]
  }
}
```

`authorization` semantics. `kind` is `step` (step_by_step) or `continuous`. `plan_identity` is the approved identity the choice covers and must equal the current plan identity (case-sensitive). `step_ids` is a non-empty array for `step`; for `continuous`, omitting it covers every eligible step of that plan, and a list restricts it to those steps. The resolver releases a step only when the record matches the switch passed (`-StepAuthorization` or `-ContinuousAuthorization`), the identity is current, and the step is in scope. Denial reasons: `authorization_record_missing`, `authorization_kind_mismatch`, `authorization_identity_mismatch`, `authorization_scope_excludes_step`. The record never covers other plans, Git, publication, or external effects, and the resolver does not authenticate the operator. See `scripts/ledger/Resolve-DeliveryExecution.ps1` and the decisions table in `EXECUTION.md`.

### 6.2 CHECKPOINT (`delivery-checkpoint/v1`)

| Property | Kind | Type | Notes |
|---|---|---|---|
| `schema` | Required | string | Must be `delivery-checkpoint/v1`. |
| `branch` | Required | string | Observed branch at write time. The resolver requires it to equal the observed branch on resume. |
| `head` | Required | string | Observed HEAD commit at write time. The resolver requires it to equal the observed HEAD on resume. |
| `active_step` | Required | string or `null` | Use `null` when no step is active. Any non-empty value makes the resolver deny. |
| `run_id` | Optional | string | Unique per run. |
| `updated_utc` | Optional | string | Time of the last checkpoint write. |
| `last_completed` | Optional | string or `null` | Id of the last COMPLETED step. |
| `next_eligible` | Optional | array of strings | Ordered ids of upcoming eligible steps. Informational. |
| `repositories` | Optional | array of objects | Per-repository entries `{ "path", "base", "branch", "head" }`, with `path` repository-relative. Used when a delivery spans more than one repository. Each entry allows optional string keys `path`, `base`, `branch`, and `head`; no key is required. Other keys are `unknown_property`. |
| `input_identity` | Optional | string | Declared-input identity at write time. The resolver checks the APPROVAL `input_identity`, not this value. |
| `location_kind` | Optional | string | `git` or `directory`. Enum, case-sensitive. Absent means `git`. With `directory`, the rules below apply. |
| `baseline_evidence` | Optional | string or `null` | Evidence reference `<step-id>/<name>` (section 10.1). Must match that format when present and not `null`. With `directory`, it must be a non-blank string and is required. |

```json
{
  "schema": "delivery-checkpoint/v1",
  "branch": "feature/example",
  "head": "0123456789ABCDEF0123456789ABCDEF01234567",
  "active_step": null,
  "run_id": "run-20261111-120000-a1",
  "updated_utc": "2026-11-11T12:00:00Z",
  "last_completed": "US01-S1",
  "next_eligible": ["US01-S2"],
  "repositories": [
    { "path": ".", "base": "master", "branch": "feature/example", "head": "0123456789ABCDEF0123456789ABCDEF01234567" }
  ],
  "input_identity": "E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855"
}
```

Note: the head value above is a placeholder with the right shape. A real value is the observed commit.

Directory kind. A unit outside Git has no branch or HEAD to observe. With `location_kind` set to `directory`:

- `branch` and `head` must both be empty strings. A non-empty value is `invalid_field`.
- `baseline_evidence` is required. An absent property is `missing_field`. A `null` value is `invalid_field`. A value of the wrong format is `invalid_field`.

```json
{
  "schema": "delivery-checkpoint/v1",
  "branch": "",
  "head": "",
  "active_step": null,
  "location_kind": "directory",
  "baseline_evidence": "US01-S1/plan-snapshot"
}
```

### 6.3 APPROVAL (`delivery-approval/v1`)

| Property | Kind | Type | Notes |
|---|---|---|---|
| `schema` | Required | string | Must be `delivery-approval/v1`. |
| `state` | Required | string | `pending`, `approved`, or `superseded`. Enum, case-sensitive. The resolver accepts only `approved`. |
| `identity` | Required when `state` is `approved` | string | Hash. Must equal `Get-DeliveryNormativeIdentity` of the current document. Otherwise `approval_identity_stale`. |
| `input_identity` | Required when `state` is `approved` | string | Hash. Caller-recomputed declared-input identity. Must equal the current value. |
| `review_state` | Required when `state` is `approved` | string | `reviewed`, `bypassed`, or `not_run`. Enum, case-sensitive. `not_run` is not eligible. |
| `review_bypass_reason` | Optional | string or `null` | Reason text when `review_state` is `bypassed`. Rules that depend on `review_state` are not checked by this library. |
| `review_bypass_operator_choice` | Optional | string or `null` | Operator choice for the bypass, expected to be `bypass` when `review_state` is `bypassed`. Not checked by this library. |
| `blocking_findings` | Optional | array | Must be empty for eligibility. The resolver treats a missing property as empty. |
| `unresolved_decisions` | Optional | array | Must be empty for eligibility. Same presence rule as `blocking_findings`. |
| `operator_choice` | Optional | object | `{ "choice": string, "evidence": string }`. Both inner keys are optional; no other inner key is allowed. Content-approval evidence, with `choice` set to `content_approval`. The resolver does not read it. |
| `review_identity` | Optional | string | Identity of the review record that backs this approval. Binds the approval to the durable review record. |
| `approved_utc` | Optional | string | Time of the operator approval. |

```json
{
  "schema": "delivery-approval/v1",
  "state": "approved",
  "identity": "E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855",
  "input_identity": "E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855",
  "review_state": "reviewed",
  "review_bypass_reason": null,
  "review_bypass_operator_choice": null,
  "blocking_findings": [],
  "unresolved_decisions": [],
  "approved_utc": "2026-11-11T12:00:00Z"
}
```

Bypass example fields when `review_state` is `bypassed`:

```json
{
  "review_state": "bypassed",
  "review_bypass_reason": "required reviewer host unavailable",
  "review_bypass_operator_choice": "bypass"
}
```

Content-approval evidence example (optional):

```json
{
  "operator_choice": {
    "choice": "content_approval",
    "evidence": "operator confirmed the normative content"
  }
}
```

**State transitions.**

- `pending` -> `approved`: the operator approves the exact normative content. Record `identity`, `input_identity`, and `review_state`.
- `approved` -> `pending`: amendment, because normative text changed. Reset the block to `pending`, remove the identity fields (`identity`, `input_identity`, `review_state`), then a new approval records the new identity.
- `approved` or `pending` -> `superseded`: the approval is withdrawn or the document is replaced by a newer one. Terminal; never eligible.

Regardless of `state`, an `identity` that differs from the recomputed normative identity means the approval is stale (`approval_identity_stale`).

### 6.4 STEP (`delivery-step/v1`)

| Property | Kind | Type | Notes |
|---|---|---|---|
| `schema` | Required | string | Must be `delivery-step/v1`. |
| `id` | Required | string | Must equal the marker id, case-sensitive. `Read-DeliveryBlocks` reports a missing or different value as `step_id_mismatch`. The resolver also rejects a mismatch (`step_block_invalid_shape`). |
| `status` | Required | string | `PENDING`, `IN_PROGRESS`, `COMPLETED`, or `BLOCKED`. Enum, case-sensitive. |
| `depends_on` | Optional | array of strings | Ids of predecessor steps. Not checked against the declared steps by this library (section 7, row 19). |
| `run_id` | Optional | string | Run that last changed the status. |
| `started_utc` | Optional | string | Time the step started. |
| `ended_utc` | Optional | string | Time the step ended. |
| `acceptance_evidence` | Optional | array or string | Evidence references for acceptance conditions. |
| `validation_results` | Optional | array of objects | Validation entries. Each entry requires `command` (string) and `result` (string). Optional entry keys: `exit_code` (integer) and `at_utc` (string). Other keys are `unknown_property`. |
| `blocker` | Optional | string or `null` | Text when `status` is `BLOCKED`. Not checked by this library. |
| `evidence_refs` | Optional | array of objects | Evidence files this step produced. Each entry requires `name` (lowercase slug matching `^[a-z0-9][a-z0-9-]*$`), `path` (non-blank string), and `sha256` (64 uppercase hexadecimal characters). No other entry keys. An empty array is valid. Section 10.1. |

```json
{
  "schema": "delivery-step/v1",
  "id": "US01-S1",
  "status": "PENDING",
  "depends_on": [],
  "acceptance_evidence": [],
  "validation_results": [],
  "blocker": null
}
```

Note: `started_utc` and `ended_utc` are strings. Write them as strings once the step starts or ends, or omit them. `null` is not accepted for them by this library.

## 7. Divergences to reconcile

Each row is a place where a file named in the first column differs from this contract. The implementation work that changes these files is outside WP1.

| # | Location | Current | Contract |
|---|---|---|---|
| 1 | `core/skills/integrated-delivery-implement/references/execution-protocol.md:10` | Step block named `STEP-<id>`. | `STEP:<id>`. The legacy form is rejected. |
| 2 | `core/skills/integrated-delivery-implement/references/execution-protocol.md:8` | Checkpoint branch and HEAD described per repository. `Resolve-DeliveryExecution.ps1:101-102` reads top-level `branch` and `head`. | Top-level `branch` and `head` are required. Per-repository data is in optional `repositories`. |
| 3 | `core/skills/integrated-delivery-implement/references/execution-protocol.md:9` | APPROVAL fields described in prose: "operator choice and timestamp", "unresolved blocking findings", "review-record identity/state". The resolver reads `review_state`, `review_bypass_operator_choice`, `blocking_findings`, and `unresolved_decisions` (`Resolve-DeliveryExecution.ps1:89-96`). | Names follow the resolver. `approved_utc` and `review_identity` are optional. |
| 4 | `core/skills/integrated-delivery-implement/references/execution-protocol.md:7` | PROGRESS "completed/total counts", "current_stage", and "authorization evidence" are unnamed. | `completed`, `total`, `current_stage`, and `authorization` (optional). |
| 5 | `scripts/ledger/Resolve-DeliveryExecution.ps1:60` and `:65` | Marker scanner accepts `[A-Z0-9-]+` names and the `STEP-` prefix. | Only `STEP:<id>` is valid. `STEP-` is rejected. |
| 6 | `scripts/ledger/Resolve-DeliveryExecution.ps1:105-106` | Step blocks matched only as `DELIVERY:STEP-<id>`. Canonical blocks give `step_blocks_missing`. | Canonical `STEP:<id>` form. |
| 7 | `scripts/ledger/Resolve-DeliveryExecution.ps1:38` | Identity projection pattern `[A-Z0-9-]+` does not match `STEP:<id>`, so STEP blocks stay in the identity. A status change then alters the identity. | All four block types are removed (section 4). |
| 8 | `scripts/ledger/Resolve-DeliveryExecution.ps1:39-44` | Projection does not trim trailing newlines or append exactly one LF. | Section 4. |
| 9 | `scripts/ledger/Resolve-DeliveryExecution.ps1:60` | Scanner is not fence-aware. A fenced example is read as a marker. | Section 1: fenced lines are plain text. |
| 10 | `scripts/ledger/Resolve-DeliveryExecution.ps1:33` | Block regex needs a non-empty payload (`\r?\n(.*?)\r?\n`). An empty payload reports `block_*_missing_or_duplicate`. | Empty payload is `invalid_json`. |
| 11 | `scripts/runtime/Write-DeliveryReviewRecord.ps1:52-58` | Marker scan is not fence-aware. It rejects any `<!-- DELIVERY:...-->` text, including inside fences. | Section 1. |
| 12 | `scripts/runtime/Write-DeliveryReviewRecord.ps1:80` | Requires at least one STEP block. | Exactly one per declared id (section 3). |
| 13 | `scripts/runtime/Write-DeliveryReviewRecord.ps1:81-82` | Projection does not trim trailing newlines or append exactly one LF. | Section 4. |
| 14 | `scripts/runtime/Write-DeliveryReviewRecord.ps1:127` | Record uses `approval.status -eq 'approved'`. The APPROVAL block uses `state`. The mapping between the two is not defined. | APPROVAL `state` is the only approval field. |
| 15 | `scripts/runtime/Write-DeliveryReviewRecord.ps1:124` | Record bypass uses `operator_choice.choice == 'bypass'` with `evidence`. APPROVAL uses `review_bypass_operator_choice` with `review_bypass_reason`. | APPROVAL names (section 6.3). |
| 16 | `scripts/runtime/Write-DeliveryReviewRecord.ps1:127` | Record content approval uses `operator_choice.choice == 'content_approval'`. No APPROVAL property records this choice. | Resolved; see "Resolved decisions" (section 8, decision 4). Recorded in optional APPROVAL `operator_choice`. |
| 17 | `scripts/runtime/Write-DeliveryReviewRecord.ps1:148` | Supports pwsh 7 only (pre-existing): `ConvertFrom-Json -Depth 50` (`-Depth` exists only in PowerShell 6 and later), `SHA256.HashData`, `[Convert]::ToHexString`, and `File.Move` with overwrite, none available on Windows PowerShell 5.1. Not fixed by the grammar work; 5.1 support or a documented minimum version is tracked under the install/compatibility item (C5.5). | Library avoids `-Depth` and runs on Windows PowerShell 5.1. |
| 18 | `scripts/runtime/Write-DeliveryReviewRecord.ps1:221` | `identity_rule` text does not state the trailing-newline rule. | Update with row 13. |
| 19 | `core/skills/_shared/integrated-delivery/SCHEMAS.md` section 6.4, `depends_on` | STEP blocks are excluded from the normative projection (section 4), so their `depends_on` declarations are not covered by the identity. | Checked by the plan preflight: `depends_on` must equal the declared `Depends on:` set; a mismatch is `depends_on_mismatch` (section 10). This library does not check it. |
| 20 | `core/skills/integrated-delivery-implement/references/execution-protocol.md` and any other document that names the block fields | Describes the PROGRESS, CHECKPOINT, and APPROVAL fields in prose (rows 3 and 4). | Use `completed`, `total`, `updated_utc`, `approved_utc`, `started_utc`, and `ended_utc`, as in section 6. Planned follow-up; not edited in WP1. |

Other references to the legacy form, outside WP1: `scripts/validation/Assert-DeliveryExecution.ps1:38` and `:41` write `DELIVERY:STEP-<id>` markers.

Consistent with this contract: `core/skills/integrated-delivery-review/references/review-protocol.md:14` names `STEP:<stable-id>`.

## 8. Resolved decisions

1. APPROVAL `state` accepts exactly `pending`, `approved`, and `superseded` (section 6.3). The library enforces the enum, case-sensitive.
2. A STEP payload `id` that differs from the marker id is reported by `Read-DeliveryBlocks` as `step_id_mismatch`.
3. An unclosed fence at end of text is reported as `unclosed_fence` (section 2).
4. Content approval evidence is recorded in the optional APPROVAL `operator_choice` object (section 6.3).
5. Unknown payload properties are errors (`unknown_property`), not ignored. Keys are matched exactly. Reason: operational blocks are excluded from the normative identity, so a key that was silently ignored could hide normative text. This reverses the earlier rule that ignored unknown properties.
6. STEP id uniqueness is case-sensitive. `US01-S1` and `us01-s1` may coexist in one plan.
7. Fence detection follows the CommonMark-lite rule in section 1.1.
8. Nested objects and arrays of objects have exact-case inner allowlists (section 6). The reason in decision 5 applies inside operational blocks too.
9. Timestamp-like strings are JSON strings. The library checks them as strings in Windows PowerShell 5.1 and PowerShell 7, where `ConvertFrom-Json` produces a `DateTime` for them.

## 9. Startup marker (`delivery-startup/v1`)

Separate file, not a DELIVERY block. `scripts/session/Invoke-StartupPreflight.ps1` writes it to `<SessionsRoot>/startup-<SessionId>.json`, atomically, and validates it on `check`. This library does not read or validate it.

The marker records a coordinator declaration. It does not prove that the model read the declared files or which model the host applied.

| Property | Type | Notes |
|---|---|---|
| `schema` | string | Must be `delivery-startup/v1`. |
| `session_id` | string | Matches `^[A-Za-z0-9._-]+$`. |
| `host` | string | Host name, for example `claude` or `codex`. |
| `recorded_utc` | string | ISO 8601 UTC time of the record action. |
| `subagents_capability` | string | `native`, `none`, or `unknown`. |
| `reads_declared` | array of strings | Declared startup reads, as base names. |
| `model_choice` | `null` or object | `null` when no choice was recorded. Otherwise `{ "kind", "model", "effort" }`, where `kind` is `inherit`, `pair`, or `saved_confirmed`, and `model` and `effort` are strings or `null`. |

Check gates (`spawn`, `review-record`) and the required reads per capability are defined by the script, not by this file.

## 10. Step declarations and plan preflight

Step declarations live in the normative plan text. `scripts/_lib/DeliveryGrammar.ps1` parses them and raises the step codes in section 2. `scripts/runtime/Test-DeliveryPlanPreflight.ps1` checks them against the STEP blocks.

Declaration syntax:

- `## Steps` is a level-2 heading. An optional leading `<n>. ` is allowed.
- Each step is a level-3 heading `### <id> <title>`. `<id>` matches the pattern in section 1.
- Under each step heading, a line `Depends on: <id>[, <id>...]` or `Depends on: none`, and a line `Validation: <non-empty text>`.
- Optional under each step heading, a line `Evidence: <name>[, <name>...]` naming the evidence this step produces. `Evidence: none`, or no such line, means no evidence. A name matches `^[a-z0-9][a-z0-9-]*$`.
- Optional under each step heading, a line `Needs evidence: <step-id>/<name>[, <step-id>/<name>...]` naming evidence that this step requires. `Needs evidence: none`, or no such line, means none. `<step-id>` matches the pattern in section 1.
- Labels are case-sensitive. A repeated `Evidence:` or `Needs evidence:` line under one heading is `evidence_declaration_invalid`. `none` cannot be combined with other names.
- Other step fields are free text. Headings inside fenced code blocks (section 1.1) are ignored.

Rules:

- Each declared id has exactly one STEP block, and each STEP block id is declared.
- The normative `Depends on:` text is authoritative over STEP `depends_on`. The block copy is operational: the preflight checks that it equals the declared set (order ignored, duplicates collapse) and never trusts it. A mismatch is `depends_on_mismatch`.
- An empty token between commas, a name that fails the slug pattern, a duplicate name within one step's `Evidence`, or a `Needs evidence` token without the `<step-id>/<name>` form is `evidence_declaration_invalid`, reported at the line of the declaration.
- Whether a `Needs evidence` reference names a producing step and name is checked by the preflight in the same work package. The grammar only checks the form.
- A declared step id containing `--` is `step_id_invalid`, because the double hyphen is reserved as the evidence file separator (`<step-id>--<name>.<ext>`). Declared step ids that differ only by case are `duplicate_declared_step`, because file systems alias them. Block marker ids (section 1) are not affected by either rule.

### 10.1 Evidence and baseline

- Evidence files for a unit live under `features/NNN-slug/<UNIT>/evidence/` as `<step-id>--<name>.<ext>`. Only `scripts/runtime/Invoke-DeliveryEvidence.ps1` writes them (`-Action write` or `verify`). Blocked reasons (exit 3): `evidence_not_declared`, `sensitive_content_detected`, `evidence_exists_different`, `evidence_ambiguous`, `evidence_missing`, `evidence_changed`. Exit 1 is an error.
- `scripts/ledger/Resolve-DeliveryExecution.ps1` checks the candidate step's `Needs evidence` and a directory checkpoint's `baseline_evidence` against the producer's `evidence_refs` entry. The entry must exist and its file must recompute to `sha256`.
- Resolver reasons: `evidence_missing` or `baseline_missing` (no entry or no file), `evidence_ref_invalid` or `baseline_ref_invalid` (bad path, other unit, or reparse point), `evidence_changed` or `baseline_changed` (SHA-256 differs).
- `evidence_ref_invalid` also denies the candidate step when a `Needs evidence` declaration inside its own range is malformed; the evidence field names the candidate id. Malformed declarations of other steps do not affect it.
- Two `evidence_refs` entries with the same name in one producer block are ambiguous and deny with `evidence_ref_invalid` (`baseline_ref_invalid` on the baseline path).
- A directory-kind checkpoint (`location_kind: directory`, section 6.2) replaces the branch and HEAD comparison. Its baseline is verified on every selection and resume.
- `scripts/runtime/Test-DeliveryPlanPreflight.ps1` raises `evidence_source_unknown`, `evidence_name_undeclared`, `evidence_source_not_predecessor`, and `baseline_reference_unknown`. Malformed declarations raise `evidence_declaration_invalid` (grammar).
- Declaration lines follow the strict rules in section 10: `none` mixed with names and repeated `Evidence:` or `Needs evidence:` lines under one heading are `evidence_declaration_invalid`.

Preflight issue codes (`issues[].code`):

- Input and grammar: `plan_path_invalid`, `grammar_invalid`.
- Step declarations: `steps_section_missing`, `duplicate_declared_step`, `step_id_invalid`, `step_depends_missing`, `step_validation_missing`, `evidence_declaration_invalid`.
- Block correspondence: `missing_block`, `unexpected_block`, `missing_step`, `undeclared_step`, `depends_on_mismatch`.
- Dependency graph: `dependency_unknown`, `dependency_self`, `dependency_cycle`.
- Approval and review: `approval_identity_stale`, `identity_changed`, `review_gate_blocked`.

Accepted plan paths: `features/NNN-slug/scratch/delivery-review/<name>.md` (draft snapshot) or the canonical `features/NNN-slug/(USnn|TSnn)/PLAN.md`; any other path is `plan_path_invalid`.

The preflight is read-only. It writes JSON `{ ok, identity, issues: [ { code, message, step } ] }` to stdout. Exit codes: 0 when ok, 3 when there are issues, 1 on error.

### 10.2 Plan dependencies and input identity

Declaration (normative text, outside operational blocks):

- `## Plan dependencies` is an optional level-2 heading, with an optional leading `<n>. ` as in `## Steps`. Without the heading the plan has no plan dependencies. Lines inside fenced code blocks are ignored (section 1.1).
- Each dependency is one line under the heading:

```markdown
Requires plan: features/NNN-slug/US01/PLAN.md identity=E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855 steps=US01-S2
```

- `<path>` is a repository-relative `features/NNN-slug/(US|TS)nn/PLAN.md`. `identity` is the 64-character uppercase normative identity (section 4) of the predecessor when this plan was approved. `steps` lists one or more predecessor step ids that this plan needs. A non-blank line under the heading that does not match this form is a malformed declaration (`plan_dependency_invalid`). A second `## Plan dependencies` heading is `plan_dependency_invalid`. A `Requires plan:` line outside the heading, outside fenced code, is `plan_dependency_invalid`. A dependency on the plan itself is `plan_dependency_invalid` in the resolver and `plan_dependency_cycle` in the preflight.

Resolver reasons. `scripts/ledger/Resolve-DeliveryExecution.ps1` checks the whole plan declaration for direct predecessors only, before the directory baseline check. The first failure denies, with the predecessor path in `dependency`. Checks run in this order:

1. `plan_dependency_missing`: the predecessor file is absent.
2. `plan_dependency_invalid`: the declaration is malformed, the predecessor fails the grammar, or a listed step is absent from its `## Steps`.
3. `plan_dependency_identity_changed`: the predecessor's recomputed normative identity differs from the declared `identity`.
4. `plan_dependency_not_approved`: the predecessor APPROVAL is missing, not `approved`, or its `identity` is stale.
5. `plan_dependency_step_incomplete`: a listed step is not `COMPLETED`.
6. `plan_dependency_evidence_missing`: a listed step is `COMPLETED` but its `acceptance_evidence` is missing or blank.

Preflight codes (`scripts/runtime/Test-DeliveryPlanPreflight.ps1`). The preflight follows the dependency chain. It does not require predecessor steps to be `COMPLETED`.

- `plan_dependency_invalid` and `plan_dependency_missing`: as in the resolver. The preflight also reports `plan_dependency_invalid` for an unsafe path and for a predecessor whose delivery blocks do not parse.
- `plan_dependency_identity_changed`: the declared `identity` differs from the predecessor's current identity.
- `plan_dependency_step_unknown`: a listed step is not declared in the predecessor's `## Steps`.
- `plan_dependency_cycle`: the chain returns to the plan itself or to a plan already on the same chain. The visited set is per chain, so a diamond is not a cycle. More than 20 `Requires plan:` hops is `plan_dependency_cycle` with a depth-limit message.

Effect. Operational progress in a predecessor, including all operational blocks, never changes either normative identity. A normative change of a predecessor blocks each dependent with `plan_dependency_identity_changed` until the dependent is amended (new declared identity, re-review, re-approval).

Input identity by kind. A declared input that is `features/NNN-slug/REFINEMENT.md` or `features/NNN-slug/(US|TS)nn/PLAN.md` is identified by its normative identity (section 4). Any other declared file is identified by the uppercase SHA-256 of its raw bytes. An input of the first kind whose delivery blocks do not parse invalidates the review record check (`inputs_changed`) and the record writer.

Gate order and divergence. Before the first implementation step the coordinator runs `Test-DeliveryPlanPreflight.ps1 -ExpectedIdentity <approved identity> -ReviewRecordPath <record>`, which includes the review gate, and then the resolver. A blocked preflight blocks execution. The resolver is the per-step authority and does not read the review record itself. It also runs on Windows PowerShell 5.1, while the review scripts need pwsh 7.

Limits. `acceptance_evidence` counts as non-blank when it is a non-blank string, or an array containing one. PowerShell 7 may parse an ISO 8601 timestamp value as a date; that value still counts as non-blank.

### 10.3 External input sources

Scope: declared material inputs of a `delivery-review-record/v1` record (`inputs[]`). Repository-relative inputs keep the rules of section 10.2.

Alias catalog:

- A per-user JSON file kept in the SDD directory beside `preferences.json`, conventionally `input-aliases.json`. The toolkit never writes it, and it never lives inside a repository or a versioned artifact.
- Shape: `{ "schema": "delivery-input-aliases/v1", "aliases": [ { "name", "root", "kind" } ] }`. `name` is a slug and unique. `root` is an absolute existing directory that is not a link. `kind` is `directory` or `git`; `git` requires a `.git` entry in `root`. Unknown keys are rejected.
- Scripts receive the catalog through `-AliasCatalogPath`. Without it an alias input cannot be verified.

Input path forms:

- Repository-relative (section 10.2), or `alias:<name>` / `alias:<name>/<relative>`.
- Forward slashes; no `.` or `..` segment, no empty segment, no colon outside the `alias:` prefix, no trailing slash.
- Artifacts and records cite the alias form only, never the private root.
- An alias-only path (`alias:<slug>`, no relative part) is valid only for source kind `revision` or `fileset`; a `file` input needs a relative part. Reordering `source.files` does not change the identity, because members are hashed in sorted order.

Source kinds. An optional `source` object on a record input selects how the input is identified. A repository-relative plain file takes no `source`.

| `source.kind` | `path` | Other keys | Identity |
|---|---|---|---|
| `file` | `alias:<name>/<file>` | none | SHA-256 of the raw bytes. The file is read twice; a difference is `source_changed_during_read`. |
| `fileset` | `alias:<name>/<dir>` (directory) | `files`: explicit list of relative member paths | SHA-256 (uppercase hex) of the UTF-8 compact JSON array, no whitespace, entries ordered by `path` with ordinal comparison, each `{"path":"<relative path with />","sha256":"<UPPERCASE hex of the file bytes>"}` (key order `path`, then `sha256`). Case-insensitive duplicate paths are `fileset_collision`. Limits: 2000 files, 50 MB per file. |
| `revision` | `alias:<name>` of a `git` alias | `revision`: full 40-hex commit id | SHA-256 (uppercase hex) of the UTF-8 compact JSON text `{"kind":"revision","alias":"<name>","commit":"<lowercase 40 hex>","tree":"<lowercase tree id>"}`, no whitespace. Branches, tags, and abbreviations are `revision_invalid`. Verified with read-only Git (`cat-file`, `rev-parse`) only. |

Alias files and filesets are always identified by raw bytes; no normative projection applies to them.

Safety. Containment under the alias root is required. The library rejects `..`, absolute and drive-qualified forms, links and reparse points (dangling ones included), missing or unreadable members, and files that change while being read.

Failure codes: `alias_catalog_missing`, `alias_catalog_invalid`, `alias_unknown`, `source_kind_invalid`, `source_path_invalid`, `source_escapes_root`, `source_reparse_point`, `source_missing`, `source_unreadable`, `source_too_large`, `source_changed_during_read`, `fileset_invalid`, `fileset_collision`, `revision_invalid`, `revision_unavailable`, `git_unavailable`.

Verdict. The record gate (`Test-DeliveryReviewRecord.ps1`) returns `input_source_unavailable` with detail `<id>: <code>` when any code above prevents verification. A changed identity or a missing repository file stays `inputs_changed`.

A source the machinery cannot verify gives `input_source_unavailable`, including a missing alias file (an unmounted root looks like a deletion) and any unexpected error while verifying it. Plain repository paths keep `inputs_changed` for a changed or missing file. When a changed identity and an unavailable source both occur, `inputs_changed` is reported first.

CLI: `scripts/runtime/Get-DeliveryInputSourceIdentity.ps1 -RepoPath <repo> (-InputJson <json> | -InputPath <file>) [-AliasCatalogPath <file>]`. On success it prints `{"ok":true,"identity":"<HEX>"}` and exits 0. On failure it prints `{"ok":false,"reason":"<code>","message":"<text>"}` and exits 3.

Writers and gates. `Write-DeliveryReviewRecord.ps1` and `Test-DeliveryReviewRecord.ps1` accept `-AliasCatalogPath`. `Test-DeliveryPlanPreflight.ps1` forwards it and reports the review-gate result as `review_gate_blocked`.

Limit. A plan's declared inputs written as prose are not machine-read. External sources are verified only for review-record inputs and through the identity CLI.

### 10.4 Refinement items and references

Scope: items of `features/NNN-slug/REFINEMENT.md` and the plan `## Refinement references` section. Field labels and layout: `core/skills/integrated-delivery-refine/references/refinement-format.md` ("Refinement items").

Items:

- Item heading: level 3, `### <ID> <title>`. `<ID>` is `D-`, `CA-` or `R-` followed by at least three digits (`(D|CA|R)-[0-9]{3,}`) and must be the first space-delimited token. Other headings are ordinary headings and do not start an item.
- The body runs to the next heading of level 1 to 3. IDs are unique within the file (`refinement_item_invalid` otherwise) and are never recycled.
- A superseded item keeps its ID and carries the body line `Status: superseded by <ID>`.
- Item hash: uppercase SHA-256 hex of the UTF-8 item body, from the heading line through the line before the next level 1 to 3 heading. Normalize as in section 1 (BOM, CRLF to LF), trim trailing blank lines, and end with exactly one LF.

References (plan side):

- `## Refinement references` is a level-2 heading with an optional `<n>. ` prefix. Each cited item is one line: `Uses: <features/NNN-slug/REFINEMENT.md> <ID> hash=<64 UPPERCASE hex>`, where the hash is the item hash.
- A `Uses:` line outside that heading, a malformed line, or a hash that is not 64 uppercase hex is `refinement_reference_invalid`.
- The referenced refinement must have its APPROVAL in state `approved` with a current `identity`; otherwise `refinement_not_approved`.
- A plan never restates a referenced item's value and never declares a `### <ID> ...` heading for an ID defined in a referenced refinement (`plan_restates_refinement_item`).

Preflight codes (`scripts/runtime/Test-DeliveryPlanPreflight.ps1`). Precedence: a superseded item reports `refinement_reference_superseded` even when its hash also changed.

- `refinement_reference_unknown`: the refinement file or the cited ID does not exist.
- `refinement_reference_stale`: the cited hash differs from the current item hash.
- `refinement_reference_superseded`: the cited item carries `Status: superseded by`.
- `refinement_not_approved`, `plan_restates_refinement_item`, `refinement_reference_invalid`: as above.

CLI: `scripts/runtime/Get-DeliveryRefinementItems.ps1 -RepoPath <repo> -RefinementPath <REFINEMENT.md> [-Id <ID>]`. On success it prints `{"ok":true,"identity":"<HEX>","items":[{"id","title","hash","superseded_by"}]}` and exits 0; `superseded_by` is `null` when the item is not superseded. `identity` is the refinement's normative identity (section 4). On failure it prints `{"ok":false,"reason","message"}` and exits 3.

Focused amendment flow:

1. Patch only the affected items, as a minimal edit.
2. Reset the APPROVAL block from `approved` to `pending` (section 6.3), re-review the affected content, and record a new approval.
3. Dependent plans report `refinement_reference_stale` or `refinement_reference_superseded` at preflight.
4. In each dependent plan, update only the affected `Uses:` lines with hashes read through the CLI (a superseded ID is replaced by its replacement ID), re-audit the affected plan sections, and re-approve the plan content.
5. Operational edits (progress, checkpoint, step status, evidence) never require a new normative approval.
