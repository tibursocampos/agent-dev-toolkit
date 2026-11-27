## Handoff after preparation

Before handoff, reconcile each listed PRD and PLAN against the requested behavior, acceptance, scope, dependencies, material decisions, and evidence limits. Use the owner skill's substantive review; do not run a universal format preflight. Fix a supported inconsistency within the prepared scope. If a correction materially changes the approved outcome, obtain a decision for the changed PLAN before implementation.

List only PLANs whose implementation scope was explicitly approved. Include relevant PRD, FEATURE, STORY, or evidence paths for context. Preserve portable `external:<alias>/<relative-path>` evidence references exactly; O2 does not grant additional access.

CONTINUITY may be read as optional historical context, but creating or updating it is not required. Do not mirror progress or approval state into CONTINUITY, CHANGE, or TASKS. Existing files need no conversion or deletion.

## Cross-artifact review

Review current behavior versus intended change for relevant brownfield work, material dependencies between stories, and whether the PLAN's acceptance and validation cover the requested outcome. This is a substantive review, not a fixed checklist or validator gate. Use available evidence and state its limits; unresolved material conflict blocks only affected plans.

## Handoff choices

After one explicit approval of the listed PLAN set, route to O3 or direct `adt-sdd-develop`. The handoff must not imply that implementation has started, that tests were run, or that unlisted plans were approved.
