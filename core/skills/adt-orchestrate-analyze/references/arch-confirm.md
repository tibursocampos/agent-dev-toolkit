# Material architecture decisions

O1 has no architecture-style approval gate. Do not ask for confirmation merely
because the work is greenfield, brownfield, or lacks an established repository
style. Do not create a mirrored ARCH document solely to record the existing
architecture.

When a concrete architecture choice materially changes behavior, acceptance,
scope, access, or implementation, present the choice and its consequence before
dependent work. Persist the resolved decision in FEATURE/STORY or a separate
ARCH note when that separate record is useful. If the choice is not material to
the requested outcome, state a supported assumption or record a suggestion;
never treat a suggestion as user approval or expand scope on that basis.

Existing architecture notes and Memory Bank material are optional evidence.
Read only relevant sources. Implementation planning and its one approval occur
in O2/Classic planning, before code.
