# Agent routing -> stack skills

Orchestrators and specialists **do not** reimplement stack work. Point implementation to existing developer skills.

| Signal | Route |
|--------|-------|
| `.cs` / `.csproj` / EF | `/dotnet-developer` |
| React Native / Expo | `/react-native-developer` |
| React / TSX | `/react-developer` |
| Angular | `/angular-developer` |
| Vue | `/vue-developer` |
| Blazor | `/blazor-developer` |
| Electron | `/electron-developer` |
| Node / plain JS | `/javascript-developer` |
| Python | `/python-developer` |
| Mixed / unclear | `/developer` (router) |
| UI shape / audit first | `/impeccable` -> DESIGN-BRIEF -> stack skill |
| Blip plugin scaffold | `/blip-plugin-developer` |

## Orchestrator boundaries

| Skill | May spawn | Must not |
|-------|-----------|----------|
| `orchestrate-analyze` | Roster specialists via Task | Call `*-developer` to write app code |
| `orchestrate-deliver` | Contracts of `sdd-spec` / `sdd-plan` per story | Implement code |
| `orchestrate-develop` | One subagent per PLAN step using `sdd-develop` contract | Parent writes app code; multi-step in one child |

**Task model:** see `SUBAGENT-MODEL.md` — omit `model` by default; premium only after rare hard-task gate + user **sim**.

**Caveman receipts:** when `caveman_mode` is ON, specialists return the schema in `RECEIPT.md` (ultra structured findings). Parent inherits prefs `caveman_level` but **never** compresses gates or artifact drafts. Prefer level `ultra` only for long multi-specialist O1 sessions. Load `_shared/caveman/CAVEMAN.md` only if mode ON.

**Memory-bank (Forma C Step 0):** after gate, pass resolved `bank_root` (`$Cwd/memory-bank/` or `<classic.path>/memory-bank/` per `STORAGE.md`) as **read-only** Prior context to specialists / O2 draft Tasks / O3 develop children (selective files). Do not place bank under `features/`. Forma A / manual `sdd-*` do not require the gate. Optional narrative compact: `_shared/caveman/COMPACT.md` (user **sim**).

## Review

After O3 or manual develop: `/code-review` (name `- single` or `- multi-angle`, or let the skill ask - no silent default).
