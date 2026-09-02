# memory-bank-init — command playbook

**Load after Step -1 gates.** Ordered step discovery without dumping `SKILL.md` Process (REQ-006 / CA3). Load **one** section file per step (`SKILL-REFERENCE-RETRIEVAL.md`).

| Step | Action | Lazy section / contract |
|------|--------|-------------------------|
| -1b | Caveman Lite when active | `CAVEMAN.md` |
| 1 | Gate check; load MEMORY-BANK + STORAGE; resolve `invocation_context` | `MEMORY-BANK.md`, `STORAGE.md`, `INVOCATION-CONTEXTS.md` |
| 2 | Resolve target (`bank_root`; create / refresh / refresh-light) | `STORAGE.md`; `references/versioning.md` |
| 3 | Gitignore (repository mode only) | `STORAGE.md` |
| 4 | Confirm before write (**sim**) | — |
| 5 | Inventory (read-only scan); capture `status`/`status_reason`/`inventory_hash`/`inventory_summary` | `references/inventory-fallback.md`; inventory script |
| 6 | Scaffold or refresh files | `references/template-map.md`, `references/generated-markers.md`, `references/tech-stack.md` |
| 7 | Report + handoff incl. inventory governance (STOP; no O1/O2/O3 in this skill) | `references/secrets.md`, `references/dry-run.md` |

Never place bank under `features/`. Never write app code. Secrets checklist: `references/secrets.md`.
