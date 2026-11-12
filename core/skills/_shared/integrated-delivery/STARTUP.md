# Integrated delivery startup contract

Coordinator rule. Applies before any delegation, write, or durable review record in an integrated-delivery run. Gate ids and question mapping: `{{TOOLKIT_ROOT}}/skills/_shared/agents/QUESTIONS.md` and `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/SESSION.md`.

## 1. Resolve once per session

1. Host: the agent host in use (for example `claude`, `codex`). Do not guess it.
2. Always-on policy: installed `guardrails`, `sdd-pipeline-guards`, and `orchestrator-session`. Guardrails path: `{{GUARDRAILS_PATH}}`.
3. Effective `subagents` capability: `native`, `none`, or `unknown`. Unknown or unavailable counts as `none`.
4. Preferences: `orchestrator_mode` and `caveman_mode` in `{{SDD_ROOT}}/preferences.json`. Read `orchestrator_mode` only when capability is `native`.

## 2. Read contracts by trigger

- Always: `guardrails` and `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/SESSION.md`.
- Only when capability is `native`: `SPAWN-DIGEST.md`, `SPAWN.md`, and `SUBAGENT-MODEL.md` in `{{TOOLKIT_ROOT}}/skills/_shared/agents/`.
- Capability `none`, `unknown`, or unavailable: skip every spawn and model-choice contract and question. Work in the parent.

## 3. Declare with the preflight script

Script: `{{TOOLKIT_ROOT}}/scripts/session/Invoke-StartupPreflight.ps1`. Sessions directory: `{{SDD_ROOT}}/sessions`.

1. Record after the reads and the model choice:
   `-Action record -SessionId <id> -SessionsRoot <sessions> -AgentHost <host> -Capability <cap> -ReadsDeclared <base names> [-ModelChoiceKind inherit|pair|saved_confirmed -Model <m> -Effort <e>]`
   - `-ReadsDeclared`: base names of every startup read actually done.
   - `-ModelChoiceKind`: `inherit`, a `pair` chosen by the operator in this session, or a `saved_confirmed` pair confirmed by the operator in this session. Required when capability is `native`. Omit when capability is `none`.
   - Never record a model, effort, or isolation that the host did not report.
2. Check before each transition:
   - `-Action check -Gate spawn` before the first spawn.
   - `-Action check -Gate review-record` before saving a review record.
3. Exit 3 means blocked. The `reason` is one of `marker_missing`, `host_mismatch`, `reads_missing`, `model_choice_missing`, or `marker_invalid`. Fix the cause, record again, then check again.

Operational sequence for each host session:

1. On the first integrated-delivery transition, resolve the host and capability, read the applicable startup contracts, then record one marker for the current host session. Reuse that `SessionId` and `SessionsRoot` for later transitions in the same session; do not infer that a prior conversation created a marker.
2. Before the first child delegation in the session, run the script with `-Action check -Gate spawn`.
3. Immediately before each durable review-record write, run it with `-Action check -Gate review-record`. A blocked result means do not write the record; report the exact reason and resolve the marker inputs first.
4. Canonical artifacts may be drafted before the review-record gate, but record the startup marker before the first such write.

Use `{{TOOLKIT_ROOT}}/scripts/session/Invoke-StartupPreflight.ps1` with the exact argument forms in section 3. The record call must declare the base names actually read. When capability is `none` or `unknown`, omit spawn/model-choice reads and model-choice parameters. When the host exposes no session id, create one session-local unique id and reuse it for the current host session; this id does not prove continuity across restarts.

## 4. Limits

- The marker is a coordinator declaration. It does not prove that the model read the files or which model the host applied.
- A saved model/effort pair is an option under `SUBAGENT-MODEL.md`. It is not an authorization inferred from the saved value.

## 5. Precedence

- Integrated-delivery contracts (`features/NNN-slug/USnn/PLAN.md` or `TSnn/PLAN.md`, `REFINEMENT.md`, operational blocks) govern integrated units.
- The Classic SDD structure (`PRD/`, `PLAN/PLAN_NNN_*.md`) and its session gates (`step_confirmed`, `tests_run`) govern Classic flows.
- Neither validates the other's artifacts. Both stay independent.
