# Step 0 - blocking start gate

Run this before any other step of `adt-delivery-flow`. A stage skill run directly (not routed by the flow in the same run) runs it first too. It is blocking: a failed preflight or an unanswered question stops the run. Chat language: `{{TOOLKIT_ROOT}}/skills/_shared/agents/LANGUAGE.md`.

## Order

1. **Subagent capability.** Resolve the effective `subagents` capability: `native` when the host exposes an Agent or subagent tool, otherwise `none`. Unknown means `none`.
2. **Preferences.** Read `{{SDD_ROOT}}/preferences.json`. When it is missing, create it with the first-install defaults in `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md` (section "Preferences File").
3. **Model choice, only when `native`.** Read `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN-DIGEST.md`, `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md` and `{{TOOLKIT_ROOT}}/skills/_shared/agents/SUBAGENT-MODEL.md`. Ask the one-time session model and effort question as `SUBAGENT-MODEL.md` section "Session choice" describes, with the rules in `{{TOOLKIT_ROOT}}/skills/_shared/agents/QUESTIONS.md`, then WAIT for an explicit answer. Silence is not an answer, and a saved preference does not answer it. Record the answer as `inherit`, `reuse_saved` or `choose_model`; for `choose_model`, finish the new-model branch first. When capability is `none`, skip this step and record `n/a`. A new conversation asks again.
4. **Preflight `start`.** Run:

   ```
   powershell -NoProfile -File {{TOOLKIT_ROOT}}/scripts/runtime/Test-AdtDeliveryPreflight.ps1 -Stage start -Subagents <native|none> -ModelChoice <inherit|reuse_saved|choose_model|n/a>
   ```

   Exit 0: continue. Exit 1: blocking. Report the `failures` list of the printed JSON line to the operator and stop.
5. **Notices, shown once.** When capability is `native`, show `[Orchestrator] Mode active: {orchestrator_mode}. Type orchestrator status to review.` Show the caveman notice only when the stage that runs next may compress. The refine and plan stages never show it (exemption in their Step -1b).

## Recorded values

The answers of this step, and the mode, are written into the plan's Operational record by the refine stage (`{{TOOLKIT_ROOT}}/skills/adt-delivery-refine/SKILL.md`, step 1). These are the exact lines:

- `Mode: full|analysis` (`analysis` only when the operator asked for an analysis alone, see `adt-delivery-flow/SKILL.md`, "Analysis-only mode"; otherwise `full`)
- `Subagents: native|none`
- `Model choice: inherit|reuse_saved|choose_model|n/a`
- `Stage ledger: refine=pending|done, plan=pending|approved, implement=pending|in_progress|done`

A new plan starts with `refine=pending, plan=pending, implement=pending`. A resumed plan keeps its ledger.

## Preflight calls

`Test-AdtDeliveryPreflight.ps1` checks one stage per call and prints one JSON line `{"ok":bool,"stage":"..","failures":[".."]}`. Exit 1 is blocking in every skill that calls it: report the `failures` list and stop. Do not route around it and do not retry the same call without a changed input.

| Stage | Called by | Arguments |
|-------|-----------|-----------|
| `start` | Step 0 | `-Stage start -Subagents <..> -ModelChoice <..>` |
| `refine` | refine entry, after it writes the record | `-Stage refine -PlanPath <selected PLAN.md> -Subagents <..> -ModelChoice <..>` |
| `plan` | flow before routing to planning, and plan entry | `-Stage plan -PlanPath <selected PLAN.md> -Subagents <..> -ModelChoice <..>` |
| `implement` | flow before routing to implementation, and implement entry | `-Stage implement -PlanPath <selected PLAN.md> -Subagents <..> -ModelChoice <..>` |

For `refine`, `plan` and `implement`, pass the values recorded in the Operational record. `start` has no `-PlanPath`.
