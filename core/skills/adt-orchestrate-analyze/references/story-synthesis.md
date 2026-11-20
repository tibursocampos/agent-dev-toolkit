# O1 synthesis

## Canonical records

Use the resolved feature tree and templates under
`skills/_shared/templates/features/`:

```text
features/NNN-slug/
├── FEATURE.md
├── USnn/STORY.md   # when a user outcome warrants a separate story
├── TSnn/STORY.md   # when a technical outcome warrants a separate story
└── Bug/STORY.md    # when a bounded defect warrants a separate story
```

Only create story folders that support a distinct, understandable outcome.
Omit unnecessary records and optional sections. CONTINUITY, CHANGE, TASKS,
Memory Bank, and specialist sidecars are not required for new or resumed work.
Do not convert or delete historical files. O1 does not create PRDs or PLANs.

## Prepare and revise

- FEATURE explains the intended outcome and material scope. Use goals,
  exclusions, acceptance references, decisions, evidence, and story links when
  they define the work. Record a feature Definition of Done that proves the
  integrated result across story boundaries.
- A STORY describes one useful outcome, its boundaries, acceptance, and
  dependencies. Write new criteria in Given / When / Then and a story Definition
  of Done that points to outcome evidence. Accept equivalent criteria in existing
  stories. Useful IDs aid navigation without prescribing a fixed format or count.
- Keep stories outcome-shaped. Merge items that differ only by file or layer;
  split when outcomes, consumers, risks, or delivery boundaries are materially
  independent. Load `story-sizing.md` or `anti-task-shatter.md` only when a
  concrete sizing question needs them.
- For relevant brownfield changes, include observed current behavior, intended
  change, and concrete risks in the canonical FEATURE/STORY; add a separate
  ANALYSIS/ARCH/SEC note only when it carries distinct useful evidence. Use
  `skills/_shared/sdd-artifacts/AUTHORING-CONTENT.md` for applicable risks and
  the scaffolds under `skills/_shared/templates/features/story/`.
- Keep material decisions and unresolved questions in the canonical artifact.
  Label facts, inferences, suggestions, and operator decisions. Carry the
  affected work and decision source forward. Do not let a suggestion add scope.
- When relevant, show which story covers a material outcome, what remains
  unchanged, or what question is unresolved. A useful link is enough; no
  duplicate decision ledger or prescribed matrix is required.

## Evidence and source handling

Read relevant sources that are authorized. Prefer current canonical evidence;
note material uncertainty and limits. Do not require promotion of every cited
Markdown document. A user-selected feature brief in an identified EPIC may be
read narrowly with its relevant context and dependencies. Do not paste whole
source documents or a Memory Bank into the FEATURE/STORY.

For external evidence that may be needed later, record only the authorized
portable reference format defined in `STORAGE.md`; O1 does not authorize O3
access to an external root.

## Handoff readiness

The outcome is ready for planning when its material behavior, scope, acceptance,
dependencies, and required decisions are sufficiently clear for O2 to prepare
the PRD/PLAN set. Ask about a material unresolved decision before dependent
work. Minor questions do not block unrelated stories. Do not run a mandatory
document validator, scorecard, fixed-count check, or backlog approval gate.

End with a concise synthesis and the next action. O2 presents its complete
implementation PLAN set for one explicit approval before code.
