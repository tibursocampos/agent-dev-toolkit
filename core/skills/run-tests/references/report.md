# Report

Render sentences in the user chat language (`LANGUAGE.md`). Field names and result tokens stay English.

| Field | Value |
|-------|--------|
| stack id | English stack id |
| command | the command that ran |
| exit code | process exit code |
| result | `PASS` or `FAIL` |
| log | portable path when one exists |

Several stacks: one row per stack. Overall `PASS` only when every row is `PASS`.

A check the repository does not have is `SKIPPED` with a reason. It does not become `PASS`.
