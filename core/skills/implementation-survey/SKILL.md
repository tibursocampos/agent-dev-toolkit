---
name: implementation-survey
description: Describe what changed and how the implementation appears to work. The report opens with the external observable goal. Descriptive skill, not a code-review mode. Use when invoking /implementation-survey.
---

# Skill: implementation-survey

## Trigger

Invoke when the user asks for `/implementation-survey`.

This skill is descriptive. It is not a mode of `code-review`.

## Outcome

A report that answers what changed and how the implementation appears to work. The first block is the external observable goal. Internal detail stays in behavior. The report states no judgment of correctness, completeness, or pattern fit.

## Inputs

Accepted form. `path` is optional:

```text
/implementation-survey source=working-tree target=HEAD path=src/Api
/implementation-survey source=feature/foo target=develop
```

`source` is `working-tree` or a local or remote ref that git already resolves. `target` is `HEAD` or another local or remote branch. `path`, when present, is a folder prefix. A glob is not accepted.

An omitted `source` asks one question: working tree, or a named local or remote ref. An omitted `target` asks one question: `HEAD`, or another local or remote branch. There is no silent default. A named ref that git cannot resolve asks one question for a name git already resolves. Do not fetch.

An omitted `path` applies no path filter to the comparison, the reads, the build, or the tests. A present `path` limits those four to paths under that prefix.

A forbidden path may be listed when it appears in the diff. Do not open it and do not cite its content. Forbidden paths are spec (`PRD`, `PLAN`, `CHANGE`), evidence packages, architecture (`ARCH/`), security (`SEC/`), analysis (`ANALYSIS/`), guidelines, a stack checklist used as a quality bar, `code-review` references, and a prior review report. A child briefing repeats this ban.

For each relevant call in the diff, open the neighboring file that implements the call target when that file is inside the prefix (or anywhere when `path` is omitted). Citing a spec does not replace that open. A call target outside the prefix stays closed. The claim is inferred and states that the target stayed outside the limit.

The three diff commands live in `references/comparison.md`.

## Lazy-load (only when needed)

| When | Path |
|------|------|
| Three diff comparisons | `core/skills/implementation-survey/references/comparison.md` |
| Stack signal order | `core/skills/implementation-survey/references/stack-discovery.md` |
| Search map for the detected stack | `core/skills/implementation-survey/references/search-map.md` |
| Observable pattern signals | `core/skills/implementation-survey/references/patterns.md` |
| Report shape | `core/skills/implementation-survey/references/report-template.md` |

**Never by default:** do not preload these five references together. Load one reference when that part of the pass runs. From `search-map.md`, load only the section of the detected stack. This skill has no `reference.md`.

`core/skills/_shared/agents/SPAWN.md` is a shared contract. It is not a sixth reference in this folder.

## Reference routing

| Situation | Path |
|-----------|------|
| Three diff comparisons | `references/comparison.md` |
| Stack signal order | `references/stack-discovery.md` |
| Search map for the detected stack | `references/search-map.md` |
| Design pattern block | `references/patterns.md` |
| Seven-block report | `references/report-template.md` |

## Process

Write the report by following `references/report-template.md`.

Write the design pattern block by following `references/patterns.md`. Name a pattern only when the opened structure shows it. When it does not, say the pattern is not visible. Do not recommend a pattern.

## Read, build, and test

There is no question before opening a file. There is no confirmation by path count.

When the diff is non-empty, the skill may compile, build, and run tests on the slice. It does not edit the target repository.

A build failure or a test failure does not cancel the seven report blocks. The observed result is a fact in behavior and in the tests table.

Coverage appears only when the stack emits the number. The report adds no sentence that the number, the build, or the tests are enough or not enough.

An empty diff states that there is no change. It does not start a build and it does not start tests.

## Parent and children

Before the first spawn decision in this conversation, read `core/skills/_shared/agents/SPAWN.md` if that file has not already been read. It stays a shared contract. It is not a reference file of this skill.

The parent writes the seven blocks.

Independent fronts — reading across files, projects, tests, or build — go only to children that already exist: `repo-analyst`, `shell-runner`, the detected stack skill, and `run-tests`. Use the host mechanism described in `SPAWN.md`. Work on one file, with no risk of spreading, stays in the parent.

The briefing is description plus evidence, scoped paths, and a receipt. The excerpt is a short pointer. Do not paste the whole PRD. Do not ask the child for judgment or for edits.

When `subagents` is absent (`none`, missing, or unknown), the parent does that work. Absence is not a hard failure.

Do not create a new specialist type. Do not invoke `/code-review`.

When the operator asks for a judgment of correctness, completeness, or pattern fit, do not answer. Offer the `/code-review` handoff at most once.

## Report rules

The report uses the chat language. Technical names stay as they appear in the code. The terms project shape, system design, and design pattern stay those words.

Each claim is observed or inferred. An observed claim cites `path:line` or a diff hunk. An inferred claim states what was not in the diff.

Outside a literal code quote, the report omits the tokens in this list:

```text
"should" "deveria" "Approved" "Approved with reservations" "Changes required" "Aprovado" "Aprovado com ressalvas" "Alterações necessárias" "severity"
```

Build output, test output, and a coverage number stay observed facts. The report adds no sentence that the result is enough or not enough.

## Must not

- Act as a mode of `code-review`.
- Judge correctness, completeness, or pattern fit.
- Ask before opening a file, or confirm by path count.
- Edit the target repository.
- Cancel the seven blocks when build or tests fail.
- Start a build or tests when the diff is empty.
- Create a new specialist type.
- Invoke `/code-review`, or offer that handoff more than once.
- Add `reference.md`.
- Preload every reference in the Lazy-load table.
