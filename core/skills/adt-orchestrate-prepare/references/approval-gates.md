## One approval before implementation

Finish substantive review of the implementation PLANs before requesting approval. Present the complete portable PLAN path or the explicitly listed set of PLAN paths, with a concise summary of scope, material decisions, and notable validation limits.

Ask once whether the presented plan or set is approved for implementation. Accept an explicit affirmative, a request to adjust, or cancellation in the user's language. Silence is not approval. Approval applies only to the plans presented; a new plan or material scope change needs its own decision.

No separate approval is required to draft, revise, or save FEATURE, STORY, PRD, or PLAN documents. Do not persist `write_confirmed`, `content_approved`, or another session token as authority. Do not ask again because O2 advances to another document phase or resumes without a material change.

| Answer | Action |
|---|---|
| Approve | Record the approval briefly in the PLAN or handoff context and route only the listed plans to implementation. |
| Adjust | Update the affected draft, re-review it, and present the changed plan scope for a decision if the implementation outcome or scope changed materially. |
| Cancel | Stop before implementation and leave the prepared artifacts as drafts. |

O2 owns one progress table for preparation and approval. Do not add an approval/status table or make internal `adt-sdd-spec` / `adt-sdd-plan` calls display a second table.
