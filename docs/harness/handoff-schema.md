# Handoff Schema

Contract → Backend/Frontend 핸드오프 고정 형식. 예시: `examples/contract-handoff.md`

## Frontmatter (필수)

```yaml
---
ticket: TB-{id}
from: Contract
to: [Backend, Frontend]
status: ready | blocked
breaking: false
---
```

## 본문 섹션 (순서 고정)

| 섹션 | 내용 |
|------|------|
| `## API 변경` | 메서드·경로·쿼리·상태코드 |
| `## DTO` | JSON 스키마 또는 타입 정의 |
| `## DB` | migration 파일·호환성·rollback |
| `## Backend TODO` | 체크리스트 |
| `## Frontend TODO` | 체크리스트 |
| `## Breaking change` | 없음 / 상세 |

## 파일 위치

- 티켓당 1개: `docs/harness/handoffs/TB-{id}-handoff.md` (선택)
- 또는 PR 설명에 동일 구조 붙여넣기

## 검증

- Contract 완료 후 Backend/Frontend 디스패치 **전** 작성
- `breaking: true`이면 QA·Frontend에 명시적 알림
- `pwsh scripts/validate-handoff.ps1` (또는 `.sh`) PASS
- 용어 변경 시 playbook·AGENTS.md 동기화

## 최소 예시

```markdown
---
ticket: TB-101
from: Contract
to: [Backend, Frontend]
status: ready
breaking: false
---

## API 변경
- `GET /api/users` — `?page=&size=`

## DTO
\`\`\`json
{ "id": "uuid", "name": "string" }
\`\`\`

## DB
- migration: `V001__users.sql` · additive only

## Backend TODO
- [ ] Controller + Service

## Frontend TODO
- [ ] API client 타입

## Breaking change
없음
```
