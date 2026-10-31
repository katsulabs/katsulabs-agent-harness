# Status Schema

The asynchronous handoff channel between roles. Instead of "reporting back verbally to the main session", each subagent appends its result to a **committed** status file. Other sessions and instances learn progress from the file.

File: `<handoff dir>/<TICKET>-status.md` (one per ticket).

## Frontmatter (required)

```yaml
---
ticket: TB-101
updated: 2026-07-18
---
```

## Role table (required, header fixed)

`| role | status | artifacts | verified |`

| Column | Values |
|--------|--------|
| `role` | `Contract` `Backend` `Frontend` `QA` `Editor` |
| `status` | `todo` `in_progress` `done` `blocked` |
| `artifacts` | paths, comma-separated, or `—` |
| `verified` | evidence (e.g. `npm test PASS`) or `—`; for `blocked`, the reason |

## Rules

- Each role edits **only its own row**. This keeps merge conflicts away.
- On finishing, update `status`, `artifacts`, `verified` and commit.
- QA confirms every role is `done` before the PR.
- Gate: `collect-handoff.sh <TICKET>` passes only if all roles are `done` with non-empty `verified` and QA is `done`.

## Example

```markdown
---
ticket: TB-101
updated: 2026-07-18
---

# Status — TB-101

| role | status | artifacts | verified |
|------|--------|-----------|----------|
| Contract | done | docs/handoffs/TB-101-handoff.md | validate-handoff PASS |
| Backend  | in_progress | server/users.js | — |
| Frontend | todo | — | — |
| QA       | todo | — | — |
```
