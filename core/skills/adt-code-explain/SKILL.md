---
name: adt-code-explain
description: Explain code changes or describe how existing code works. Descriptive skill, not a mode of adt-code-review. Use when invoking /adt-code-explain.
---

# Skill: adt-code-explain

## Trigger
**Negative signal:** applies as defined in `_shared/skill-boilerplate.md`; the skill-specific signals are listed below.


Invoke when the user asks for `/adt-code-explain`.

This skill is descriptive. It is not a mode of `adt-code-review`.

## Outcome

A mode-specific report: comparison explains what changed and how the implementation appears to work; standalone explains how existing code works. Both cite opened code and distinguish observed facts from inference. Neither judges correctness, completeness, or pattern fit.

## Inputs

Select a mode from the request before opening code:

| Observed input | Mode and action |
|---|---|
| Resolvable `source` and `target`, with or without `path` | Compare them using `references/comparison.md`. |
| Exactly one endpoint (`source` or `target`) | Ask only for the missing endpoint. Do not select standalone or fetch refs. |
| No endpoints, but a topic, symbol, or `path` identifying code | Explain the current code in standalone mode. Here `path` may identify a file or folder. Do not calculate a diff. |
| Endpoints plus a clear request to explain a related area | Compare, then explain that area only when its relationship and boundary are clear. Ask before reading wider when unclear. |
| Mixed comparison and explanation intent, or `source` could mean a path or ref | Ask which mode and reference/path the user means. Do not guess or widen reads. |
| No endpoint, topic, symbol, or identifiable path | Ask what code or behavior the user wants explained. |

Accepted comparison form:

```text
/adt-code-explain source=working-tree target=HEAD path=src/Api
/adt-code-explain source=feature/foo target=develop
```

`source` is `working-tree` or a local or remote ref that git already resolves. `target` is `HEAD` or another local or remote branch. `path`, when present, is a folder prefix. A glob is not accepted.

An omitted `source` asks one question: working tree, or a named local or remote ref. An omitted `target` asks one question: `HEAD`, or another local or remote branch. There is no silent default. A named ref that git cannot resolve asks one question for a name git already resolves. Do not fetch.

An omitted `path` applies no path filter to the comparison, the reads, the build, or the tests. A present `path` limits those four to paths under that prefix.

In standalone mode, `path` may be one file or a folder. It limits code reads only; never treat it as a Git endpoint or a comparison path filter. If no path is supplied, use the identified topic or symbol to find the relevant code and keep the explanation scoped to that code.

Standalone examples:

```text
/adt-code-explain path=src/Api/CustomerService.cs
/adt-code-explain topic="how customer lookup works"
```

A forbidden path may be listed when it appears in the diff. Do not open it and do not cite its content. Forbidden paths are spec (`PRD`, `PLAN`, `CHANGE`), evidence packages, architecture (`ARCH/`), security (`SEC/`), analysis (`ANALYSIS/`), guidelines, a stack checklist used as a quality bar, `adt-code-review` references, and a prior review report. A child briefing repeats this ban.

For each relevant call in the diff, open the neighboring file that implements the call target when that file is inside the prefix (or anywhere when `path` is omitted). Citing a spec does not replace that open. A call target outside the prefix stays closed. The claim is inferred and states that the target stayed outside the limit.

The three diff commands live in `references/comparison.md`.

## Lazy-load (only when needed)

| When | Path |
|------|------|
| Three diff comparisons | `core/skills/adt-code-explain/references/comparison.md` |
| Stack signal order | `core/skills/adt-code-explain/references/stack-discovery.md` |
| Search map for the detected stack | `core/skills/adt-code-explain/references/search-map.md` |
| Observable pattern signals (comparison only) | `core/skills/adt-code-explain/references/patterns.md` |
| Report shape for selected mode | `core/skills/adt-code-explain/references/report-template.md` |

**Never by default:** do not preload these five references together. Load one reference when that part of the pass runs. From `search-map.md`, load only the section of the detected stack. This skill has no `reference.md`.

`core/skills/_shared/agents/SPAWN.md` is a shared contract. It is not a sixth reference in this folder.

## Reference routing

| Situation | Path |
|-----------|------|
| Three diff comparisons | `references/comparison.md` |
| Standalone mode selection and scope | This `SKILL.md`; do not load comparison rules |
| Stack signal order | `references/stack-discovery.md` |
| Search map for the detected stack | `references/search-map.md` |
| Design pattern block in comparison mode | `references/patterns.md` |
| Mode-specific report | `references/report-template.md` |

## Process

1. Apply the mode table above before opening files or choosing references.
2. In comparison mode, load `references/comparison.md`, then follow the existing diff, stack, search, and report process. Load `references/patterns.md` only for the comparison report's design pattern block.
3. In standalone mode, explain existing behavior from the relevant opened code. Load `references/stack-discovery.md` and only the selected stack's relevant entry-point/dependency guidance in `references/search-map.md` when that helps locate code. Do not use the Tests guidance or load `comparison.md` or `patterns.md`.
4. Write the mode-specific report by following `references/report-template.md`.

In standalone mode, cite paths and line numbers for opened files and symbols. Keep observed behavior separate from inference; state boundaries and collaborators that could not be opened. Do not add a design pattern block.

## Read, build, and test

No permission or path-count confirmation is needed before opening a clearly identified, in-scope file. A material mode or scope ambiguity follows the Inputs table.

In comparison mode, when the diff is non-empty, the skill may compile, build, and run tests on the slice. It does not edit the target repository.

A build failure or a test failure does not cancel the seven report blocks. The observed result is a fact in behavior and in the tests table.

Coverage appears only when the stack emits the number. The report adds no sentence that the number, the build, or the tests are enough or not enough.

An empty diff states that there is no change. It does not start a build and it does not start tests. Standalone mode never calculates a diff and never starts a build or tests.

## Parent and children

Before the first spawn decision in this conversation, read `core/skills/_shared/agents/SPAWN.md` if that file has not already been read. It stays a shared contract. It is not a reference file of this skill.

The parent writes the report blocks required for the selected mode.

Independent fronts — reading across files, projects, tests, or build — go only to children that already exist: `repo-analyst`, `shell-runner`, the detected stack skill, and `adt-run-tests`. Use the host mechanism described in `SPAWN.md`. Work on one file, with no risk of spreading, stays in the parent.

The briefing is description plus evidence, scoped paths, and a receipt. The excerpt is a short pointer. Do not paste the whole PRD. Do not ask the child for judgment or for edits.

When `subagents` is absent (`none`, missing, or unknown), the parent does that work. Absence is not a hard failure.

Do not create a new specialist type. Do not invoke `/adt-code-review`.

When the operator asks for a judgment of correctness, completeness, or pattern fit, do not answer. Offer the `/adt-code-review` handoff at most once.

## Report rules

The report uses the chat language. Technical names stay as they appear in the code. The terms project shape, system design, and design pattern stay those words.

Each claim is observed or inferred. An observed claim cites `path:line` or, in comparison mode, a diff hunk. An inferred claim states the evidence boundary: what the diff does not show in comparison mode, or what code/collaborator was not opened in standalone mode.

Outside a literal code quote, the report omits the tokens in this list:

```text
"should" "deveria" "Approved" "Approved with reservations" "Changes required" "Aprovado" "Aprovado com ressalvas" "Alterações necessárias" "severity"
```

Build output, test output, and a coverage number stay observed facts. The report adds no sentence that the result is enough or not enough.

## Must not

- Act as a mode of `adt-code-review`.
- Judge correctness, completeness, or pattern fit.
- Ask before opening an already identified, in-scope file, or confirm by path count.
- Edit the target repository.
- Cancel the seven comparison sections when build or tests fail.
- Start a build or tests when the diff is empty.
- Create a new specialist type.
- Invoke `/adt-code-review`, or offer that handoff more than once.
- Add `reference.md`.
- Preload every reference in the Lazy-load table.
