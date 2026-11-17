# ADT delivery - storage and feature selection

Used by adt-delivery-flow, adt-delivery-refine, adt-delivery-plan and adt-delivery-implement. One rule, one place: those skills link here instead of repeating it.

## Storage root

- Use `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/STORAGE-RESOLUTION.md` only to resolve the configured repository or global manifest storage root.
- Call it with `$Workflow = classic`, exactly as `adt-sdd-develop` does. It is the only supported value.
- Do not change the rules of that file.
- Then resolve the actual feature directory under that root, including in global mode.
- This flow owns its layout (`features/NNN-slug/PLAN.md`). It does not enforce the Classic story layout (USnn/PRD/PLAN folders).
- Repository without a manifest entry (first run): follow the existing storage-selection and manifest setup.
- Malformed or unsupported manifest, or invalid configured path: stop and reconcile. Never fall back from global to local.
- Configured global root missing on disk: stop and ask the operator whether to correct the configured path or create the folder. Never create it silently and never use a local `features/` folder instead.

## Memory bank root

- `bank_root` follows `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/MEMORY-BANK.md`, section "Path resolution", with the storage root resolved above: repository storage `$Cwd/memory-bank/`; global storage `<classic.path>/memory-bank/`.
- Never place the bank under `features/NNN-slug/`.
- Refine and plan read it selectively and never write it. Only `adt-memory-bank`, after the operator confirms it at the end of implement, creates or refreshes it.

## Feature directory

- Explicit feature path: resolve it inside the configured feature root. Reject traversal and escapes, including in global storage.
- Global storage: a same-named `features/` folder in the working repository is not a fallback.
- No explicit path: inspect the filesystem, including ignored directories.
  - Exactly one matching existing feature: use it.
  - Several matches: ask the operator which one.
  - None: allocate the next available NNN.
  - Check the final directory for collisions immediately before creating it.
- Locate existing artifacts before allocating a feature. Preserve unrelated work.
- Do not use `git ls-files` or other tracked-file listings to find features or artifacts; they omit ignored files.
- New feature slug: short kebab-case taken from the demand title; confirm it with the operator when the choice is not obvious.

## Plan selection

- Default plan: `features/NNN-slug/PLAN.md` at the feature root.
- Exceptional split: use it only when several repositories or independently delivered units cannot be represented clearly in one plan (ownership, approval or progress).
  - Propose the split to the operator and agree it before creating any separate plan.
- After agreement:
  - The feature-root `PLAN.md` stays the primary shared source.
  - Independent plans live at `plans/<unit-or-repo-slug>/PLAN.md` inside the feature directory.
  - Each independent plan has its own approval, progress and adjacent `CODE-REVIEW.md`.
  - Shared decisions stay in the primary plan. Independent plans reference them and do not duplicate them.
- Select the exact plan with the operator. Validate it inside the actual feature directory, including global storage. Reject traversal and escapes.
- US sections inside one plan are optional, when they improve clarity. Do not create extra story files by default.

## Missing plan

- Direct `adt-delivery-plan` or `adt-delivery-implement` invocation with no selected existing plan: stop. Ask for the intended input or refinement.
- Do not create a substitute plan.
- Exception: after an agreed split, creating the selected independent plan uses the feature-root `PLAN.md` as input.
