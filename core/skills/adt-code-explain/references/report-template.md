# Mode-specific report templates

The selected mode determines the report shape. The report uses the chat language. Technical names stay as they appear in the code. Headings stay in English. The terms project shape, system design, and design pattern stay those words.

## Comparison mode — seven required sections

Open with product reading. Internal detail comes after that block.

Each claim is one of:

- **observed** — cite `path:line` or a diff hunk.
- **inferred** — state the evidence boundary. In comparison mode, identify what the diff does not show; in standalone mode, identify code or collaborators that were not opened.

Outside a literal code quote, omit the tokens in this list:

```text
"should" "deveria" "Approved" "Approved with reservations" "Changes required" "Aprovado" "Aprovado com ressalvas" "Alterações necessárias" "severity"
```

Build output, test output, and a coverage number stay observed facts. Add no sentence that the result is enough or not enough.

## product reading

The goal of the implementation: the effect observable from outside, read from the diff and the code.

Example of a goal: the endpoint refuses a request that lacks the header and responds 401.

The internal path does not belong in this block. An error branch belongs in behavior.

Short prose. Add a Mermaid flow only when the diff shows a usage path with three or more steps.

## change map

Changed paths in the slice.

| Path | Set | What entered |
|------|-----|----------------|
| `path/to/file` | unstaged, staged, or the diff side | One line of what entered |

## behavior

Internal path, who calls whom, error branches visible in the code, and the observed build result.

Linear path: prose with `path:line`.

A branch, including an error branch, becomes a Mermaid diagram.

## tests

Tests in the slice. No quality note. A failed build or failed tests still leave this block and the other six blocks in the report.

Fill Result with the observed execution result. Leave Result and Coverage empty when the diff was empty and no run started. Leave Coverage empty unless the stack emits the number. Add no sentence that the result or the number is enough or not enough.

| Test | Asserts | Infrastructure | Base | Result | Coverage |
|------|---------|----------------|------|--------|----------|
| Name of the test that exists | What that test asserts | Runner, test project, how it starts | Fixtures, fakers, shared setup | Observed execution result, including a failure | Number only when the stack emits it; otherwise leave the cell empty |

## project shape

Folders and dependency direction.

| Folder | Depends on |
|--------|------------|
| `folder` | `other folder` |

Add a graph only when the direction does not fit the table.

## system design

Entry points and how the components talk. Mermaid.

```mermaid
flowchart LR
  Entry["entry point read in the pass"] --> Component["component read in the pass"]
```

Replace the nodes with what the pass opened.

## design pattern

Prose. Follow `references/patterns.md`. Name a pattern only when the opened structure shows it. Otherwise write that the pattern is not visible. Do not recommend a pattern.

## Standalone mode — five short sections

Use these five sections only. Do not add `change map`, `tests`, `project shape`, `system design`, or `design pattern` sections as requirements. Do not load `references/patterns.md`.

### observable goal

State the externally observable purpose or result of the existing code, based on the opened implementation. Do not describe a change or imply comparison.

### files and symbols opened

List the relevant paths and symbols with line references. Cite only code actually opened.

### relevant flow

Explain the relevant execution or data flow from the opened code. Add a Mermaid diagram only when it makes a multi-step flow clearer.

### observed calls and collaborators

Name calls and collaborators visible in the opened files, with `path:line` evidence. State when a target or collaborator was outside the read scope.

### inferences and limits

Label each inference and state the evidence boundary that prevents it from being an observation. Do not assess correctness, completeness, design quality, or recommend changes.
