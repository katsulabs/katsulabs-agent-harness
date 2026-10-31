# Status Schema

역할 간 **비동기 인계 채널**. 서브에이전트가 종료 시 결과를 "메인에 구두 전달"하는 대신, 커밋되는 상태 파일에 자기 행을 append 한다. 다른 인스턴스·세션이 진행 상황을 파일로 인지한다.

예시: `examples/status-example.md` · 핸드오프(계약)와 상보적: `handoff-schema.md`

## 파일 위치

- 티켓당 1개: `docs/harness/handoffs/TB-{id}-status.md`
- 접미사 `-status.md` 로 핸드오프 파일과 구분 (`validate-handoff`는 건너뜀)

## Frontmatter (필수)

```yaml
---
ticket: TB-{id}
updated: YYYY-MM-DD
---
```

## 본문 — 역할 상태 표 (필수)

헤더 컬럼 고정: `role | status | artifacts | verified`

| 컬럼 | 값 |
|------|-----|
| `role` | `Contract` \| `Backend` \| `Frontend` \| `QA` \| `Editor` |
| `status` | `todo` \| `in_progress` \| `done` \| `blocked` |
| `artifacts` | 산출물 경로(쉼표 구분) 또는 `—` |
| `verified` | 검증 결과(`run-eval PASS` 등) 또는 `—` |

## 규약

- **append-only**: 각 역할은 **자기 행만** 갱신. 남 역할 행 편집 금지 → 머지 충돌 최소화.
- 역할 종료 시 `status`·`artifacts`·`verified` 를 갱신하고 커밋.
- `blocked`이면 `verified` 열에 사유 요약.
- QA는 전 역할 `done` 확인 후 PR 진행.
- 검증: `pwsh scripts/validate-status.ps1` (또는 `./scripts/validate-status.sh`) PASS.

## 최소 예시

```markdown
---
ticket: TB-101
updated: 2026-07-18
---

# Status — TB-101

| role | status | artifacts | verified |
|------|--------|-----------|----------|
| Contract | done | docs/harness/handoffs/TB-101-handoff.md | validate-handoff PASS |
| Backend  | in_progress | server/users.js | — |
| Frontend | todo | — | — |
| QA       | todo | — | — |
```
