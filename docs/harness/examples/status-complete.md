---
ticket: TB-101
updated: 2026-07-18
---

# Status (완료 예시) — TB-101

`collect-handoff` PASS 대상: 전 역할 `done` + `verified` 기록. 스키마: `../status-schema.md`

| role | status | artifacts | verified |
|------|--------|-----------|----------|
| Contract | done | docs/harness/handoffs/TB-101-handoff.md | validate-handoff PASS |
| Backend | done | sample/server/users.js, sample/server/users.test.js | run-eval PASS |
| Frontend | done | sample/client/user-list.html | run-eval PASS |
| QA | done | eval/reports/pr-eval-summary.md | validate-harness -Pr PASS |
