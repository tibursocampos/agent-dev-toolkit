# O1 intent classification

Classify the primary user intent before doing multi-story analysis. Reuse prior
context and ask only if the route is materially unclear.

| Intent | Signals | Default route |
|---|---|---|
| Existing feature | User cites a feature tree or requests resumption | Read current FEATURE/STORY/PRD/PLAN material and continue the appropriate flow. Existing sidecars are optional context. |
| New feature | A bounded capability or change is requested | Classic SDD for one clear story; O1 for justified multi-story or multi-area work. |
| Product initiative | Several outcomes or product areas are implied | O1 when decomposition and coordinated investigation are useful. |
| Problem or need | Defect, regression, or operational pain | Developer for a clear isolated fix; Refine or Classic SDD for one item; O1 for multi-area impact or multiple stories. |
| Idea | Hypothesis with no settled outcome | Refine the idea or ask a focused question; do not invent requirements. |

Do not classify a task as O1 solely because it is brownfield. When another
workflow is the clear fit, hand it off without creating an O1 feature tree.
When O1 is appropriate, carry the selected route into the synthesis and make
its reasoning clear.
