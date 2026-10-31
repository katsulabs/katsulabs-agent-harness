# 하네스 커스터마이징

문서 전용 스타터를 팀 스택에 맞게 확장할 때 참고합니다.

## 문서 전용 (기본)

추가 작업 없이 그대로 사용합니다. Single Source of Truth:

- `.cursor/rules/*.mdc`
- [playbook.md](./playbook.md)

## 풀스택 앱으로 확장

코드베이스가 생기면 아래를 **함께** 갱신합니다. rules와 docs 중 한쪽만 바꾸면 에이전트 지시가 어긋납니다.

| 항목 | 문서 전용 (현재) | 풀스택 예시 |
|------|------------------|-------------|
| Contract 수정 범위 | `docs/**`, 계약 문서 | `db/migration`, API DTO, OpenAPI |
| Backend 수정 범위 | 시스템/운영 `docs/**` | `modules/**`, API 테스트 |
| Frontend 수정 범위 | 사용자/PR `docs/**` | `frontend/**`, Vitest |
| QA 검증 | 링크·DoD·역할 경계 | + 회귀 테스트, E2E |
| PR 게이트 | 문서 품질 게이트 | + backend/frontend 테스트 |
| 병렬 기준 | 문서 경로 비중첩 | + Flyway/DTO 충돌 없음 |

### 권장 순서

1. `playbook.md` 역할 표를 코드 경로로 재작성
2. 각 `.mdc`의 globs·범위·금지 규칙 갱신
3. `eval-guide.md` 테스트 게이트 명령 교체
4. `.github/PULL_REQUEST_TEMPLATE.md` 체크리스트 교체
5. CI workflow에 테스트 job 추가

### Backend / Frontend 이름

풀스택에서도 태그 호환을 위해 이름을 유지할 수 있습니다. 팀 내 혼란이 크면 Ops-Docs / User-Docs 등으로 rename하고 태그 표도 함께 바꿉니다.

## 티켓·브랜치

- Prefix: `TB-` → 팀 이슈 트래커 키로 교체
- Branch: `feature/TB-{id}-{short-name}` → monorepo 규칙에 맞게 조정

## CI/CD

기본 제공: [docs-quality-gate.yml](../../.github/workflows/docs-quality-gate.yml)

추가 mirror·배포 파이프라인은 [todo.md](./todo.md) 보류 항목으로 추적합니다.

## 서드파티 에이전트·스킬

문서 전용·풀스택 공통으로 외부 플러그인을 **보완 레이어**로 쓸 때는 [third-party-plugins.md](./third-party-plugins.md)를 따릅니다. 풀스택 확장 후 code-review-graph, gstack, headroom 채택 순서가 정리되어 있습니다.
