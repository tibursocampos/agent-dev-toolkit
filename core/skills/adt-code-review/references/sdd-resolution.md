## SDD artifact resolution

Run in **step 0.5** before scoping the diff. Load `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/STORAGE.md`. Resolve the actual artifact from the active repository, independently of the toolkit installation path.

### Checklist

1. **Target repo** - use the workspace under review.
2. **Selected layout** - use the explicit current invocation or handoff. An explicit story PLAN selects Classic/O3 layout. An explicit feature-root or split-unit PLAN selects Delivery. A plan layout does not itself select O3 invocation context.
3. **Manifest** - load `STORAGE-RESOLUTION.md` and resolve `repositories[$Cwd].classic` in `{{SDD_ROOT}}/manifest.json`. Use only the configured feature root. If that resolution fails, report the actual issue; a same-name file in a different root is not a substitute.
4. **Search** - prefer an explicit portable path. Otherwise search only the manifest-selected feature root. Files ignored by Git remain discoverable. Use `adt-read-sdd-artifact` to confirm selected files.

   | Layout | Candidate patterns relative to the selected feature root |
   |--------|--------------------------------------------------------|
   | Classic/O3 | `*/USnn/PRD/*.md`, `*/USnn/PLAN/PLAN_*.md` and their `TSnn` equivalents |
   | Delivery | `*/PLAN.md`, `*/plans/<approved-unit>/PLAN.md` |

5. **Associate** - first use an explicit canonical PRD/PLAN link, then an unambiguous sibling in the same story folder. Reject a cross-story association even when filenames share the same feature number. A Delivery PLAN is self-contained; for an approved split unit, read relevant decisions from its linked primary PLAN.
6. **Use the authoritative scope** - a selected approved PLAN prepared directly from a demand provides traceability without a separate PRD. When both are present, the approved PLAN scopes implementation and the linked PRD supplies the referenced behavior.
7. **Select the review scope**:

   | Priority | Signal |
   |----------|--------|
   | 1 | User or current handoff supplied an explicit artifact path |
   | 2 | Canonical relationship or unique same-story sibling resolves the companion |
   | 3 | Current diff and branch identify one feature and story/unit without ambiguity |
   | 4 | Exactly one applicable scope remains |
   | 5 | Ask once in the chat language (`core/skills/_shared/agents/LANGUAGE.md`) if plausible scopes remain ambiguous |

8. **Read** the selected PLAN and only relevant companion sections before SDD traceability (step 2).
9. **Report** the actual artifact paths used, in portable form, and any material evidence limit.

### Outcomes

| Result | Action |
|--------|--------|
| One applicable PRD/PLAN scope | Proceed with SDD traceability |
| Selected approved PLAN supplies the scope | Review against its scope and criteria, including applicable primary-plan decisions for a split unit |
| No applicable artifacts in the selected root | Report **Limitação SDD** (technical/guidelines review only), or the specific manifest/path issue when resolution failed |
| Multiple plausible scopes | Ask once for the review target |

---

---
