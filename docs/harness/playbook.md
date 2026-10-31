# Playbook

에이전트 운영 단일 참조. **필요한 섹션만 읽는다.** 계약: `AGENTS.md`

## 역할

| Agent | 역할 | 범위 |
|-------|------|------|
| Main | 분해, worktree, 분배 | `docs/**` |
| Editor | 문서·규칙·PR | `docs/**`, `.cursor/**`, `.github/**` |
| Contract | API·DB·DTO 계약 | `db/**`, `**/dto/**`, `**/openapi.*`, `contracts/**`, `api-spec/**` |
| Backend | 서버·API·로직 | `modules/**`, `backend/**`, `server/**`, `api/**` |
| Frontend | UI·클라이언트 | `frontend/**`, `client/**`, `apps/web/**` |
| QA | PR·eval 게이트 | `validate-harness`, `run-eval`, CI |

태그: `[TB-xxx][Editor|Contract|Backend|Frontend|QA]`

## 워크플로

- `main` 직접 커밋 금지 · worktree 1개/기능 · no-ff
- 흐름: worktree → 구현 → validate → run-eval → PR → CI → 머지
- 순차: Contract → Backend/Frontend(병렬 가능) → QA. 불명확하면 순차.
- `todo.md`는 **자기 티켓 브랜치에서만** 편집. 남 티켓 행 수정 금지 · 통합은 머지 시점에만.

## Worktree

스킬: `worktree-setup` · 경로: `../.worktrees/TB-{id}-{name}` · `.gitignore` 등록

**동시 실행 규칙**: 1 워킹트리 = 1 인스턴스. 여러 인스턴스를 동시에 돌릴 때는 **반드시 티켓별 worktree**로 분리(같은 체크아웃 공유 금지 — `.git/index`·`todo.md`·`eval/reports` 경쟁). eval 산출물은 브랜치 티켓 기준 `eval/reports/TB-{id}/`로 자동 격리된다.

## 서브에이전트 디스패치

규약만으로 멀티에이전트를 운영한다. Cursor **Task** 도구(또는 동급 서브에이전트)로 역할별 분리.

| 단계 | 동작 |
|------|------|
| 1 | `[TB-xxx][Role]` 태그 + 범위(globs) + DoD를 프롬프트에 명시 |
| 2 | Contract 먼저 · Backend/Frontend 병렬 가능 · QA 마지막 |
| 3 | 산출물: Contract는 `handoff-schema.md` 형식 핸드오프 |
| 4 | 종료 시 `TB-{id}-status.md`에 자기 역할 status·산출물·검증 결과 append (구두 전달 대체) |

병렬 티켓은 worktree 1개/티켓. 한 worktree 내 Backend·Frontend만 병렬 디스패치.

## 상태 채널

역할 간 비동기 인계는 커밋되는 상태 파일로 한다 — "메인에 구두 전달" 대신 다른 인스턴스·세션이 파일로 진행 상황을 인지한다.

- 파일: `docs/harness/handoffs/TB-{id}-status.md` · 스키마: `status-schema.md` · 예시: `examples/status-example.md`
- 각 역할은 **자기 행만** append (`status`: `todo`/`in_progress`/`done`/`blocked`) → 머지 충돌 최소화
- QA는 전 역할 `done` 확인 후 PR · 검증: `validate-status`

오케스트레이션: `dispatch-plan TB-{id}` — 전 역할 프롬프트 + 상태 스켈레톤 생성 · 역할별 단건은 `dispatch-prompt`  
PR 전: `collect-handoff TB-{id}` (전 역할 `done`+`verified` 게이트) · `verify-dispatch` (브랜치 `feature/TB-{id}-*`)  
명령 예시: [examples/multi-agent-dispatch.md](./examples/multi-agent-dispatch.md) · 실행 walkthrough: [examples/multi-agent-walkthrough.md](./examples/multi-agent-walkthrough.md)

## 운영 게이트

명령·시점은 `AGENTS.md` 검증 섹션이 단일 출처 · 쉘: `setup-shell.md` · eval: [eval-guide.md](./eval-guide.md)  
CI: `validate` + `test` jobs (+ `*-platforms` OS matrix) · branch protection: `validate`, `test` 권장

## 실패 시

| 실패 | 조치 |
|------|------|
| validate-harness | `playbook.md` · 링크·mdc·필수 파일 |
| validate-handoff | `handoff-schema.md` |
| verify-dispatch | `feature/TB-{id}-*` 브랜치 |
| collect-handoff | 전 역할 `done`+`verified` (`status-schema.md`) |
| validate-todo-sync | `todo.md`에 티켓 등록 |
| validate-commit-msg | 커밋 메시지에 `TB-{id}` |
| run-eval | `first-ticket.md` · `presets/` |

채택: `TEMPLATE.md` · 첫 티켓: `first-ticket.md` · 용어: `glossary.md`

## Hook fallback

태그 유지 → 산출물 전달 → validate+eval 재실행 → PR에 사유 기록

## 토큰 효율

`todo.md`+변경 파일만 로드 · Rules 최소 · Skills는 PR/worktree 시만 · 수술적 diff

## 훅 (실행 시점 강제)

도구 중립: 훅은 에이전트 도구 호출 시점에 규칙을 강제한다. 상세: [modernization.md](./modernization.md)

- `scripts/guard-tool.sh` — main 직접 commit/push·force push 차단 · `HARNESS_ROLE=<Role>` 설정 시 범위 밖 편집 차단 (`scripts/role-scopes.json`)
- `scripts/stop-gate.sh` — 종료 전 `validate-harness`
- 어댑터: `.claude/settings.json` · 스킬 원본 `.cursor/skills` → `.claude/skills` (`sync-adapters`)

## 참조

샘플: `sample/` (TB-101) · `examples/` · 레이어·세대: [introduction.md](./introduction.md)
