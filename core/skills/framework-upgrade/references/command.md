# Command playbook — framework-upgrade

Load **after** Step -1 gates. Ordered discovery only — do not paste pack corpora here.

## Order

1. Confirm gate checklist in chat (incl. Skip D + silence ≠ approval for migrate — TE05).
2. Resolve **mode** → `references/modes.md` (ask if omitted; never default to `migrate`).
3. Resolve **`framework_id`** → `references/detect.md` (TE03: 0 or >1 → ask; pack signals in `PACK.md`).
4. Resolve **versions / range** → `references/version-policy.md` (+ `packs/<id>/PACK.md`).
5. If out of `supported_range` → `references/research-protocol.md` (TE04; reuses `sources-catalog.md` official first) before any mutate.
6. Progressive load → `references/progressive-load.md` (one section at a time).
7. Execute mode contract from `references/modes.md`.
8. For `plan` / `migrate` / `validate`: touch `references/decision-register.md` + `references/evidence.md` as required.
9. Report outcome; stop. Offer `/commit` if files changed.

## Mode shortcut

| User signal | Prefer |
|-------------|--------|
| inventory / gaps / read-only | `audit` |
| ordered steps / baby plan | `plan` |
| apply changes / implement upgrade | `migrate` (**sim** required first) |
| build/test / verify after change | `validate` |

If implement is implied without **sim**: stay in `audit` or `plan` (TE05).
