# Handoff Schema

Fixed format for the Contract -> Backend/Frontend handoff. One file per ticket: `<handoff dir>/<TICKET>-handoff.md`.

## Frontmatter (required)

```yaml
---
ticket: TB-101
from: Contract
to: [Backend, Frontend]
status: ready        # ready | blocked
breaking: false      # true | false
---
```

## Sections (this order; Korean or English headings)

| Section (KO / EN) | Content |
|-------------------|---------|
| `## API 변경` / `## API changes` | method, path, query, status codes |
| `## DTO` | JSON schema or type definitions |
| `## DB` | migration files, compatibility, rollback |
| `## Backend TODO` | checklist |
| `## Frontend TODO` | checklist |
| `## Breaking change` | none, or details |

## Rules

- Write the handoff **after** the contract is fixed and **before** dispatching Backend/Frontend.
- `breaking: true` means QA and Frontend must be told explicitly.
- `status: blocked` means the contract is not final; implementers must not start.

## Complete example

```markdown
---
ticket: TB-101
from: Contract
to: [Backend, Frontend]
status: ready
breaking: false
---

## API changes
- `GET /api/users` — `?page=&size=` → 200 `{ items: User[], total: number }`

## DTO
```json
{ "id": "uuid", "name": "string", "email": "string" }
```

## DB
- migration: `V001__users.sql` · additive only · rollback: drop table

## Backend TODO
- [ ] Controller + Service
- [ ] Pagination test

## Frontend TODO
- [ ] API client types
- [ ] User list view

## Breaking change
none
```
