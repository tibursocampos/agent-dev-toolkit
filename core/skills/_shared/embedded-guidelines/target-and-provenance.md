# Target and provenance

## Identify before recommending

Before proposing implementation details, capture the smallest context that can change the answer:

| Field | Record | If absent |
|---|---|---|
| Target | board/module, architecture, variant, and revision | ask; do not infer from a family name or a marketing label |
| Runtime | firmware runtime and version | ask; do not assume host behavior or a full standard library |
| Framework/core | selected framework or core and version | ask; do not infer a framework from the board alone |
| Toolchain | project-declared build environment and version | inspect the project; do not prescribe a new one here |
| Hardware facts | voltage/current, memory, peripherals, radio, storage, and limits | cite the source or mark the fact `assumed` |
| Validation setup | host, compiler, device, fixture, instruments, and test scenario | state what is unavailable |

Names and versions are context, not proof. Record the source for each material fact: datasheet, board documentation, project decision, dependency metadata, measurement, test result, or operator-provided information.

## Provenance and applicability

For every platform-qualified recommendation:

1. name the target and revision to which it applies;
2. name the source and its version/date when that can affect the claim;
3. state whether the source is normative, project-specific, measured, or only an assumption;
4. state what is not covered, such as another revision, runtime, bootloader, memory configuration, or electrical setup.

Do not turn a value observed on one board into a family-wide limit. Do not turn a project architecture note into a capability that the firmware exposes today.

## State vocabulary

Use one or more explicit labels in notes, reviews, and handoffs:

- **confirmed** — supported by an identified source or reproducible observation;
- **assumed** — working hypothesis that still needs confirmation;
- **planned** — accepted design intent or future work, not present behavior;
- **implemented** — present in the inspected source or artifact;
- **verified** — exercised by a named validation level and scenario.

An item may move from `planned` to `implemented` without becoming `verified`. An `assumed` item must not be used as the sole basis for a safety-sensitive or irreversible recommendation.

## Common review questions

- Could a different board revision change this recommendation?
- Does the cited source describe the selected runtime and framework, or only a related platform?
- Is the statement about source structure, compilation, device behavior, or HIL behavior?
- Which state is being reported, and what evidence would move it to the next state?
